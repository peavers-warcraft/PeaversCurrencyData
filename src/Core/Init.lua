-- PeaversCurrencyData/src/Core/Init.lua
local addonName, addon = ...

-- Initialize addon namespace
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
                defaultRegion = "US",
                -- Add more preferences as needed
            }
        end

        -- Print loaded message
        print("|cFF33FF99PeaversCurrencyData|r: Loaded successfully. Currency data from " ..
        (PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "unknown date"))

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
    -- Check for chat output flag
    local useChat = false
    if msg:find("%-%-say") then
        useChat = true
        msg = msg:gsub("%-%-say", ""):trim()
    end

    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()

    if cmd == "help" or cmd == "" then
        OutputText("|cFF33FF99PeaversCurrencyData Commands:|r", useChat)
        OutputText("  /pcd info - Show addon information", useChat)
        OutputText("  /pcd convert [amount] [from] [to] - Convert currency", useChat)
        OutputText("  /pcd gold [amount] [region] [currency] - Convert WoW gold to real currency", useChat)
        OutputText("  /pcd goldvalue [amount] [currency] [region] - Get the value of gold in real currency", useChat)
        OutputText("  /pcd money [amount] [currency] [region] - Convert real currency to WoW gold", useChat)
        OutputText("  /pcd token - Show WoW token prices across regions", useChat)
        OutputText("  /pcd list - List available currencies", useChat)
        OutputText("  /pcd default [currency] - Set default currency", useChat)
        OutputText("  /pcd region [region] - Set default region", useChat)
        OutputText("  /pcd clearcache - Clear conversion cache", useChat)
        OutputText("  Add --say to any command to output results to /say channel", useChat)
    elseif cmd == "info" then
        OutputText("|cFF33FF99PeaversCurrencyData:|r", useChat)
        OutputText("  Version: 1.0", useChat)
        OutputText("  Data updated: " .. (PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "unknown"), useChat)
        OutputText("  Cache entries: " .. PCD:GetCacheSize(), useChat)
        OutputText("  Default currency: " .. PCD.preferences.defaultCurrency, useChat)
        OutputText("  Default region: " .. (PCD.preferences.defaultRegion or "US"), useChat)
    elseif cmd == "convert" and arg then
        local amount, from, to = strsplit(" ", arg, 3)
        amount = tonumber(amount)
        from = from and from:upper()
        to = to and to:upper()

        if not amount or not from or not to then
            OutputText("Usage: /pcd convert [amount] [from] [to]", useChat)
            return
        end

        local result = PCD:ConvertCurrency(amount, from, to)
        if result then
            local fromSymbol = PCD.CurrencyRates.symbols[from] or ""
            local toSymbol = PCD.CurrencyRates.symbols[to] or ""
            OutputText(string.format("%s%s %s = %s%s %s", fromSymbol, amount, from, toSymbol, result, to), useChat)
        else
            OutputText("Conversion failed. Make sure the currencies are valid.", useChat)
        end
    elseif cmd == "gold" or cmd == "g" then
        if not arg or arg == "" then
            print("|cFF33FF99WoW Token Prices:|r")
            for region, data in pairs(PCD.TokenPrices and PCD.TokenPrices.regions or {}) do
                local symbol = PCD.CurrencyRates.symbols[data.currency] or ""
                print(string.format("  %s: %s (%s%s %s)", region, PCD:FormatWoWCurrency(data.goldPrice / 10000), symbol,
                    data.realPrice, data.currency))
            end
            print("Usage: /pcd gold value [region] [currency]")
            print("Example: /pcd gold 100000 US EUR")
            return
        end

        local amount, region, currency = strsplit(" ", arg, 3)
        amount = tonumber(amount)

        if not amount then
            print("Invalid amount. Usage: /pcd gold [amount] [region] [currency]")
            return
        end

        region = region and region:upper() or PCD.preferences.defaultRegion or "US"
        currency = currency and currency:upper() or nil

        local result = PCD:GoldToCurrency(amount / 10000, region, currency)
        if result then
            local tokenData = PCD.TokenPrices.regions[region]
            local currencyCode = currency or tokenData.currency
            local symbol = PCD.CurrencyRates.symbols[currencyCode] or ""

            print(string.format("%s = %s%s %s",
                PCD:FormatWoWCurrency(amount / 10000),
                symbol,
                string.format("%.2f", result),
                currencyCode))
        else
            print("Conversion failed. Check region and currency.")
        end
    elseif cmd == "money" or cmd == "m" then
        if not arg or arg == "" then
            print("Usage: /pcd money [amount] [currency] [region]")
            print("Example: /pcd money 10 USD US")
            return
        end

        local amount, currency, region = strsplit(" ", arg, 3)
        amount = tonumber(amount)

        if not amount then
            print("Invalid amount. Usage: /pcd money [amount] [currency] [region]")
            return
        end

        currency = currency and currency:upper() or PCD.preferences.defaultCurrency
        region = region and region:upper() or PCD.preferences.defaultRegion or "US"

        local result = PCD:CurrencyToGold(amount, currency, region)
        if result then
            local symbol = PCD.CurrencyRates.symbols[currency] or ""

            print(string.format("%s%s %s = %s",
                symbol,
                amount,
                currency,
                PCD:FormatWoWCurrency(result)))
        else
            print("Conversion failed. Check currency and region.")
        end
    elseif cmd == "token" then
        print("|cFF33FF99WoW Token Prices:|r")
        for region, data in pairs(PCD.TokenPrices and PCD.TokenPrices.regions or {}) do
            local symbol = PCD.CurrencyRates.symbols[data.currency] or ""
            print(string.format("  %s: %s (%s%s %s)",
                region,
                PCD:FormatWoWCurrency(data.goldPrice),  -- Pass the raw gold amount directly
                symbol,
                data.realPrice,
                data.currency))

            -- Show the value of 1 gold in the region's currency
            local goldValue = PCD:GoldToCurrency(1, region, nil, 8) -- Force 8 decimal places

            -- If for some reason we still get 0, use the raw goldValue
            if goldValue == 0 then
                goldValue = data.goldValue
            end

            print(string.format("  1 gold = %s%s %s",
                symbol,
                string.format("%.8f", goldValue),  -- 8 decimal places for small values
                data.currency))
        end
    elseif cmd == "list" then
        print("|cFF33FF99Available Currencies:|r")
        local currencies = PCD:GetAvailableCurrencies()
        table.sort(currencies)

        for i, currency in ipairs(currencies) do
            local symbol = PCD.CurrencyRates.symbols[currency] or ""
            print(string.format("  %s (%s)", currency, symbol))
        end
    elseif cmd == "default" then
        if arg and PCD.CurrencyRates.rates[arg:upper()] then
            PCD.preferences.defaultCurrency = arg:upper()
            print("Default currency set to: " .. arg:upper())
        else
            print("Current default currency: " .. PCD.preferences.defaultCurrency)
            print("Usage: /pcd default [currency]")
        end
    elseif cmd == "region" then
        local validRegions = { US = true, EU = true, KR = true, TW = true }
        if arg and validRegions[arg:upper()] then
            PCD.preferences.defaultRegion = arg:upper()
            print("Default region set to: " .. arg:upper())
        else
            print("Current default region: " .. (PCD.preferences.defaultRegion or "US"))
            print("Usage: /pcd region [US|EU|KR|TW]")
        end
    elseif cmd == "goldvalue" or cmd == "gv" then
        if not arg or arg == "" then
            print("Usage: /pcd goldvalue [amount] [currency] [region]")
            print("Example: /pcd goldvalue 1000 EUR")
            print("Converts the specified amount of gold to real currency")
            return
        end

        local amount, currency, region = strsplit(" ", arg, 3)
        amount = tonumber(amount)

        if not amount then
            print("Invalid amount. Usage: /pcd goldvalue [amount] [currency] [region]")
            return
        end

        currency = currency and currency:upper() or PCD.preferences.defaultCurrency or "USD"
        region = region and region:upper() or PCD.preferences.defaultRegion or "US"

        local result = PCD:GoldToCurrency(amount, region, currency, 2)
        if result then
            local symbol = PCD.CurrencyRates.symbols[currency] or ""

            print(string.format("%s = %s%s %s",
                PCD:FormatWoWCurrency(amount),
                symbol,
                string.format("%.2f", result),
                currency))
        else
            print("Conversion failed. Check currency and region.")
        end
    end
end

-- Helper function to trim whitespace
local function trim(s)
   return s:match'^%s*(.*%S)' or ''
end

-- Add a trim method to the string metatable if it doesn't exist
if not string.trim then
    string.trim = trim
end

-- Helper function to output text to chat or say channel
local function OutputText(text, useChat)
    if useChat then
        SendChatMessage(text, "SAY")
    else
        print(text)
    end
end
