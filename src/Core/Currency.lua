local _, addon = ...

PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

local Currency = {}
PCD.Currency = Currency

function Currency.CopperToGold(copper)
    return copper / PCD.Constants.COPPER_PER_GOLD
end

function Currency.GoldToCopper(gold)
    return PCD.Utils.Round(gold * PCD.Constants.COPPER_PER_GOLD)
end

function Currency.FormatWoWCurrency(goldAmount, includeIcons, colorize)
    if not goldAmount then return "0g" end

    includeIcons = includeIcons ~= false
    colorize = colorize ~= false

    local totalCopper = Currency.GoldToCopper(goldAmount)

    local copper = totalCopper % PCD.Constants.COPPER_PER_SILVER
    local totalSilver = math.floor(totalCopper / PCD.Constants.COPPER_PER_SILVER)
    local silver = totalSilver % PCD.Constants.SILVER_PER_GOLD
    local gold = math.floor(totalSilver / PCD.Constants.SILVER_PER_GOLD)

    if not includeIcons then
        local parts = {}
        if gold > 0 then table.insert(parts, gold .. "g") end
        if silver > 0 then table.insert(parts, silver .. "s") end
        if copper > 0 or #parts == 0 then table.insert(parts, copper .. "c") end
        return table.concat(parts, " ")
    end

    local result = {}

    if gold > 0 then
        local goldStr = colorize and (PCD.Constants.GOLD_COLOR .. gold .. "|r") or tostring(gold)
        table.insert(result, goldStr .. PCD.Constants.GOLD_ICON)
    end

    if silver > 0 or gold > 0 then
        local silverStr = colorize and (PCD.Constants.SILVER_COLOR .. silver .. "|r") or tostring(silver)
        table.insert(result, silverStr .. PCD.Constants.SILVER_ICON)
    end

    local copperStr = colorize and (PCD.Constants.COPPER_COLOR .. copper .. "|r") or tostring(copper)
    table.insert(result, copperStr .. PCD.Constants.COPPER_ICON)

    return table.concat(result, " ")
end

-- Compatibility layer
function PCD:CopperToGold(copper)
    return Currency.CopperToGold(copper)
end

function PCD:GoldToCopper(gold)
    return Currency.GoldToCopper(gold)
end

function PCD:FormatWoWCurrency(goldAmount, includeIcons, colorize)
    return Currency.FormatWoWCurrency(goldAmount, includeIcons, colorize)
end

return Currency
