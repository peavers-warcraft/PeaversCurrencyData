-- PeaversCurrencyData/core.lua
local addonName, addon = ...

-- Initialize addon namespace if not already done in data.lua
PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

-- Create frame for events
local eventFrame = CreateFrame("Frame")

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

-- Local cache for performance
local cachedConversions = {}

-- Handle events
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize saved variables
        PeaversCurrencyDataDB = PeaversCurrencyDataDB or {}

        -- Copy saved preferences if they exist
        if PeaversCurrencyDataDB.preferences then
            PCD.preferences = PeaversCurrencyDataDB.preferences
        else
            -- Default preferences
            PCD.preferences = {
                defaultCurrency = "USD",
                decimalPlaces = 2,
                -- Add more preferences as needed
            }
        end

        -- Print loaded message
        print("|cFF33FF99PeaversCurrencyData|r: Loaded successfully. Currency data from " ..
        (PCD.lastUpdated or "unknown date"))

        -- Clear cache on load
        cachedConversions = {}
    elseif event == "PLAYER_LOGOUT" then
        -- Save preferences
        PeaversCurrencyDataDB.preferences = PCD.preferences
    end
end)

-- Internal utility functions
function PCD:ClearCache()
    cachedConversions = {}
    return true
end

function PCD:GetCacheSize()
    local count = 0
    for _ in pairs(cachedConversions) do
        count = count + 1
    end
    return count
end

-- Set up console command
SLASH_PEAVERSCURRENCY1 = "/pcd"
SLASH_PEAVERSCURRENCY2 = "/peaverscurrency"

SlashCmdList["PEAVERSCURRENCY"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()

    if cmd == "help" or cmd == "" then
        print("|cFF33FF99PeaversCurrencyData Commands:|r")
        print("  /pcd info - Show addon information")
        print("  /pcd convert [amount] [from] [to] - Convert currency")
        print("  /pcd list - List available currencies")
        print("  /pcd default [currency] - Set default currency")
        print("  /pcd clearcache - Clear conversion cache")
    elseif cmd == "info" then
        print("|cFF33FF99PeaversCurrencyData:|r")
        print("  Version: 1.0")
        print("  Data updated: " .. (PCD.lastUpdated or "unknown"))
        print("  Cache entries: " .. PCD:GetCacheSize())
        print("  Default currency: " .. PCD.preferences.defaultCurrency)
    elseif cmd == "convert" and arg then
        local amount, from, to = strsplit(" ", arg, 3)
        amount = tonumber(amount)
        from = from and from:upper()
        to = to and to:upper()

        if not amount or not from or not to then
            print("Usage: /pcd convert [amount] [from] [to]")
            return
        end

        local result = PCD:ConvertCurrency(amount, from, to)
        if result then
            local fromSymbol = PCD.symbols[from] or ""
            local toSymbol = PCD.symbols[to] or ""
            print(string.format("%s%s %s = %s%s %s", fromSymbol, amount, from, toSymbol, result, to))
        else
            print("Conversion failed. Make sure the currencies are valid.")
        end
    elseif cmd == "list" then
        print("|cFF33FF99Available Currencies:|r")
        local currencies = PCD:GetAvailableCurrencies()
        table.sort(currencies)

        for i, currency in ipairs(currencies) do
            local symbol = PCD.symbols[currency] or ""
            print(string.format("  %s (%s)", currency, symbol))
        end
    elseif cmd == "default" then
        if arg and PCD.rates[arg:upper()] then
            PCD.preferences.defaultCurrency = arg:upper()
            print("Default currency set to: " .. arg:upper())
        else
            print("Current default currency: " .. PCD.preferences.defaultCurrency)
            print("Usage: /pcd default [currency]")
        end
    elseif cmd == "clearcache" then
        local size = PCD:GetCacheSize()
        PCD:ClearCache()
        print("Cache cleared. " .. size .. " entries removed.")
    else
        print("Unknown command. Type /pcd help for a list of commands.")
    end
end
