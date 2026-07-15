-- Rummy – Wertungsblatt (beschreibbar)
-- Mechanik wie beim Phase-10-Wertungsblatt: Eingabefelder pro Kachel,
-- automatische Summen, Werte bleiben ueber Speichern/Laden erhalten.

local values
local ROWS = 13
local COLS = 6
local UNIT = 500
local ES   = 0.4
local F    = 1 / ES

local sumIdx = {}

-- Layout exakt aus der Bilderzeugung (scoreboard.png, 1540x2190)
local L = {
    gridL = 0.0974, gridR = 0.9675,
    nameTop = 0.1461, nameBot = 0.1895,
    rowTop = 0.2055, rowBot = 0.9059,
    sumTop = 0.9269, sumBot = 0.9726,
}

local PAPER = {0.969, 0.953, 0.910, 1}  -- Papierton: Feld verschmilzt mit dem Blatt
local INK   = {0.10, 0.10, 0.10, 1}

function onSave()
    return JSON.encode(values)
end

function onLoad(saved)
    values = nil
    if saved and saved ~= "" then
        values = JSON.decode(saved)
    end
    if not values or not values.runde then
        values = { name = {}, runde = {} }
        for n = 1, COLS do
            values.name[n] = ""
            values.runde[n] = {}
            for r = 1, ROWS do values.runde[n][r] = "" end
        end
    end
    buildUI()
end

function updateSumme(n)
    if sumIdx[n] == nil then return end
    local sum = 0
    for r = 1, ROWS do
        sum = sum + (tonumber(values.runde[n][r]) or 0)
    end
    self.editButton({index = sumIdx[n], label = tostring(sum)})
end

function buildUI()
    self.clearInputs()
    self.clearButtons()

    local b  = self.getBoundsNormalized().size
    local sc = self.getScale()
    local w = b.x / sc.x
    local d = b.z / sc.z
    local yTop = (b.y / sc.y) / 2 + 0.06

    local gridw = (L.gridR - L.gridL) * w
    local colw  = gridw / COLS
    local function fx(i)
        return (L.gridL + (i + 0.5) * (L.gridR - L.gridL) / COLS - 0.5) * w
    end
    local function fz(a, bf) return ((a + bf) / 2 - 0.5) * d end
    local function fh(a, bf) return (bf - a) * d * UNIT end
    local fwidth = colw * UNIT * 0.92
    local rowh = (L.rowBot - L.rowTop) / ROWS

    for i = 0, COLS - 1 do
        local n = i + 1

        -- Spielername
        _G["inpName" .. n] = function(_, _, val) values.name[n] = val or "" end
        self.createInput({
            input_function = "inpName" .. n, function_owner = self,
            position = {fx(i), yTop, fz(L.nameTop, L.nameBot)},
            scale = {ES, ES, ES},
            width = fwidth * F, height = fh(L.nameTop, L.nameBot) * 0.82 * F,
            font_size = 26 * F, alignment = 3, validation = 1,
            value = values.name[n], label = "",
            color = PAPER, font_color = INK,
            tooltip = "Spielername"
        })

        -- 13 Rundenfelder
        for r = 1, ROWS do
            local a  = L.rowTop + (r - 1) * rowh
            local bf = a + rowh
            _G["inpR" .. n .. "_" .. r] = function(_, _, val)
                values.runde[n][r] = val or ""
                updateSumme(n)
            end
            self.createInput({
                input_function = "inpR" .. n .. "_" .. r, function_owner = self,
                position = {fx(i), yTop, fz(a, bf)},
                scale = {ES, ES, ES},
                width = fwidth * F, height = fh(a, bf) * 0.80 * F,
                font_size = 28 * F, alignment = 3, validation = 2,
                value = values.runde[n][r], label = "",
                color = PAPER, font_color = INK,
                tooltip = "Runde " .. r
            })
        end

        -- Summenfeld (nicht editierbar, rechnet automatisch)
        _G["noop" .. n] = function() end
        self.createButton({
            click_function = "noop" .. n, function_owner = self,
            position = {fx(i), yTop, fz(L.sumTop, L.sumBot)},
            scale = {ES, ES, ES},
            width = 0, height = 0,             -- reines Label, nicht klickbar
            font_size = 34 * F,
            label = "0",
            font_color = {0.78, 0.17, 0.21, 1},
        })
        sumIdx[n] = #self.getButtons() - 1
        updateSumme(n)
    end
end
