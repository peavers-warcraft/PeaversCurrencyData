local _, addon = ...
local PCD = PeaversCurrencyData

local Utils = {}
PCD.Utils = Utils

-- Math utilities
function Utils.Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function Utils.Clamp(num, min, max)
    return math.max(min, math.min(max, num))
end

-- String utilities
function Utils.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

function Utils.ToUpper(str)
    return str and str:upper() or nil
end

-- Table utilities
function Utils.TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.TableKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Cache utilities
function Utils.Memoize(fn)
    local cache = {}
    return function(...)
        local key = table.concat({...}, ":")
        if cache[key] == nil then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

-- Validation utilities
function Utils.IsValidCurrency(currency)
    if not currency or type(currency) ~= "string" then
        return false
    end
    currency = currency:upper()
    return PCD.CurrencyRates and PCD.CurrencyRates.rates and PCD.CurrencyRates.rates[currency] ~= nil
end

function Utils.IsValidRegion(region)
    if not region or type(region) ~= "string" then
        return false
    end
    region = region:upper()
    return PCD.TokenPrices and PCD.TokenPrices.regions and PCD.TokenPrices.regions[region] ~= nil
end

-- Formatting utilities
function Utils.FormatNumber(num, separator)
    separator = separator or ","
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1" .. separator .. "%2")
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Debug utilities
function Utils.DebugPrint(...)
    if PCD.preferences and PCD.preferences.debugMode then
        print("|cFF33FF99[PCD Debug]|r", ...)
    end
end

-- Event utilities
function Utils.RegisterEvents(frame, events)
    for _, event in ipairs(events) do
        frame:RegisterEvent(event)
    end
end

function Utils.UnregisterEvents(frame, events)
    for _, event in ipairs(events) do
        frame:UnregisterEvent(event)
    end
end

return Utils
