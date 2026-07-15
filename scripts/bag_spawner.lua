--[[ Rummikub-Steinebeutel  ─────────────────────────────────────────
Dieses Script auf einen Beutel legen (Objects → Components → Tools → Bag,
dann Rechtsklick → Scripting → Lua Editor).

WICHTIG: BASE_URL unten anpassen! Sie muss auf den tiles/-Ordner deines
GitHub-Repos zeigen (raw-Link, siehe README).

Rechtsklick auf den Beutel → "106 Steine erzeugen" füllt ihn mit dem
kompletten Satz: 2× (1–13 in Schwarz, Rot, Blau, Orange) + 2 Joker.
--------------------------------------------------------------------]]

-- >>> HIER ANPASSEN <<<
local BASE_URL = "https://raw.githubusercontent.com/Pausebanause/Rummy/main/tiles/"

local TILE_SCALE     = 0.5    -- Größe der Steine (an den Ständer anpassen)
local TILE_THICKNESS = 0.135    -- Dicke (relativ); zusammen mit Scale tunen
local COLORS = {"black", "red", "blue", "orange"}

function onLoad()
    self.addContextMenuItem("106 Steine erzeugen", function() startLuaCoroutine(self, "spawnAllCo") end, false)
    self.addContextMenuItem("Beutel leeren", emptyBag, false)
end

function emptyBag()
    self.reset()
    broadcastToAll("Beutel geleert.", {0.9, 0.9, 0.9})
end

function buildFaceList()
    local faces = {}
    for _, c in ipairs(COLORS) do
        for n = 1, 13 do
            table.insert(faces, string.format("%s_%02d.png", c, n))
        end
    end
    table.insert(faces, "joker_red.png")
    table.insert(faces, "joker_black.png")
    return faces
end

function spawnAllCo()
    local faces = buildFaceList()
    local total = #faces * 2
    local made  = 0
    broadcastToAll("Erzeuge " .. total .. " Steine – beim ersten Mal dauert das etwas (Bilder-Download)…", {1, 0.8, 0.2})

    for _, face in ipairs(faces) do
        for copy = 1, 2 do
            local tile = spawnObject({
                type     = "Custom_Tile",
                position = self.getPosition() + Vector(0, 3, 0),
                scale    = {TILE_SCALE, 1, TILE_SCALE},
                sound    = false,
            })
            tile.setCustomObject({
                image        = BASE_URL .. "back.png",   -- Oberseite = Rücken:
                image_bottom = BASE_URL .. face,          -- Steine liegen von Natur aus verdeckt
                type         = 3,              -- 3 = abgerundetes Rechteck
                thickness    = TILE_THICKNESS,
                stackable    = false,
            })
            tile = tile.reload()
            tile.setName("")           -- kein Tooltip, sonst verrät er die Zahl!
            -- kurz warten, bis der Stein fertig geladen ist, dann einpacken
            local frames = 0
            while tile.spawning and frames < 300 do
                coroutine.yield(0)
                frames = frames + 1
            end
            self.putObject(tile)
            made = made + 1
        end
        coroutine.yield(0)
    end

    self.shuffle()
    broadcastToAll(made .. " Steine im Beutel – gemischt und bereit!", {0.2, 0.8, 0.2})
    return 1
end


--[[ Auto-Ausrichtung ─────────────────────────────────────────────────
Wird ein Stein in der Nähe eines Ständers abgelegt, dreht er sich
automatisch in dessen Blickrichtung – egal von welcher Tischseite man
zieht, die Zahlen stehen dann richtig herum.
--------------------------------------------------------------------]]
local ORIENT_RADIUS = 14   -- Wirkungskreis um jeden Ständer (Einheiten)

function onObjectDrop(_, obj)
    if obj == nil or obj.type ~= "Tile" then return end
    local ok, custom = pcall(function() return obj.getCustomObject() end)
    if not ok or custom == nil or custom.image == nil
       or not string.find(custom.image, BASE_URL, 1, true) then
        return   -- fremdes Tile, nicht anfassen
    end

    local p = obj.getPosition()
    local best, bestDist = nil, ORIENT_RADIUS
    for _, o in ipairs(getAllObjects()) do
        local n = o.getName() or ""
        if string.find(n, "Ständer", 1, true) then
            local d = Vector.distance(p, o.getPosition())
            if d < bestDist then best, bestDist = o, d end
        end
    end
    if best == nil then return end

    local r  = obj.getRotation()
    local ry = (best.getRotation().y + 180) % 360   -- +180: Zahlen zum Spieler hin
    obj.setRotationSmooth({r.x, ry, r.z}, false, true)   -- Flip-Zustand bleibt erhalten
end
