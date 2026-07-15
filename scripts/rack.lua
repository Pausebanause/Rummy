--[[ Rummikub-Ständer  ────────────────────────────────────────────────
Dieses Script auf den Ständer legen (Rechtsklick > Scripting > Lua-Editor).
Rechtsklick auf den Ständer  →  "Besitzer: <Farbe>" wählen.
Es wird automatisch eine Hidden Zone über dem Ständer erzeugt, sodass nur
der Besitzer (und der GM/Schwarz) die Steine darauf sehen kann.
"Zone entfernen" löscht die Hidden Zone wieder.
--------------------------------------------------------------------]]

local COLORS = {"White","Red","Orange","Yellow","Green","Teal","Blue","Purple","Pink"}
local zoneGUID = nil

function onSave()
    return JSON.encode({ zoneGUID = zoneGUID })
end

function onLoad(saved)
    self.locked = true   -- Pflicht: Non-Convex-Collider braucht ein gesperrtes Objekt

    if saved and saved ~= "" then
        local data = JSON.decode(saved)
        if data then zoneGUID = data.zoneGUID end
    end

    for _, c in ipairs(COLORS) do
        self.addContextMenuItem("Besitzer: " .. c, function() setOwner(c) end, false)
    end
    self.addContextMenuItem("Zone entfernen", removeZone, false)
end

function getZone()
    if zoneGUID then return getObjectFromGUID(zoneGUID) end
    return nil
end

function removeZone()
    local z = getZone()
    if z then z.destruct() end
    zoneGUID = nil
    broadcastToAll("Hidden Zone entfernt.", {0.9, 0.9, 0.9})
end

function setOwner(color)
    removeZone()

    local b   = self.getBounds()
    local pad = 0.4
    local pos = {
        x = b.center.x,
        y = b.center.y + b.size.y * 0.5,      -- Zone sitzt auf dem Ständer
        z = b.center.z,
    }
    local scale = {
        x = b.size.x + pad,
        y = b.size.y * 2.2 + pad,             -- hoch genug für gehaltene Steine
        z = b.size.z + pad,
    }

    spawnObject({
        type              = "FogOfWarTrigger",   -- = Hidden Zone
        position          = pos,
        rotation          = self.getRotation(),
        scale             = scale,
        sound             = false,
        callback_function = function(zone)
            zone.setValue(color)                 -- Farbe = wer sehen DARF
            zoneGUID = zone.getGUID()
            broadcastToAll("Ständer gehört jetzt " .. color .. ".", Color[color] or {1,1,1})
        end,
    })
end
