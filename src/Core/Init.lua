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
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd:lower()

    if cmd == "help" or cmd == "" then
        print("|cFF33FF99PeaversCurrencyData Commands:|r")
        print("  /pcd info - Show addon information")
        print("  /pcd convert [amount] [from] [to] - Convert currency")
        print("  /pcd gold [amount] [region] [currency] - Convert WoW gold to real currency")
        print("  /pcd money [amount] [currency] [region] - Convert real currency to WoW gold")
        print("  /pcd token - Show WoW token prices across regions")
        print("  /pcd list - List available currencies")
        print("  /pcd default [currency] - Set default currency")
        print("  /pcd region [region] - Set default region")
        print("  /pcd clearcache - Clear conversion cache")
    elseif cmd == "info" then
        print("|cFF33FF99PeaversCurrencyData:|r")
        print("  Version: 1.0")
        print("  Data updated: " .. (PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "unknown"))
        print("  Cache entries: " .. PCD:GetCacheSize())
        print("  Default currency: " .. PCD.preferences.defaultCurrency)
        print("  Default region: " .. (PCD.preferences.defaultRegion or "US"))
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
            local fromSymbol = PCD.CurrencyRates.symbols[from] or ""
            local toSymbol = PCD.CurrencyRates.symbols[to] or ""
            print(string.format("%s%s %s = %s%s %s", fromSymbol, amount, from, toSymbol, result, to))
        else
            print("Conversion failed. Make sure the currencies are valid.")
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
                PCD:FormatWoWCurrency(data.goldPrice / 10000),
                symbol,
                data.realPrice,
                data.currency))

            -- Show the value of 1000g in the region's currency
            local goldValue = PCD:GoldToCurrency(1, region)
            print(string.format("  1 gold = %s%s %s",
                symbol,
                string.format("%.5f", goldValue),
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
    elseif cmd == "clearcache" then
        local size = PCD:GetCacheSize()
        PCD:ClearCache()
        print("Cache cleared. " .. size .. " entries removed.")
    else
        print("Unknown command. Type /pcd help for a list of commands.")
    end
end

-- Create sample data for testing if needed (will be overridden by actual files if present)
function PCD:CreateSampleData()
    if not PCD.CurrencyRates then
        PCD.CurrencyRates = {
            lastUpdated = date("%Y-%m-%d"),
            rates = {
                USD = {
                    EUR = 0.85,
                    GBP = 0.75,
                    JPY = 110.25,
                    CAD = 1.25,
                    AUD = 1.35,
                    CHF = 0.92,
                    CNY = 6.45,
                    HKD = 7.78,
                    NZD = 1.42,
                    KRW = 1150.50,
                    USD = 1,
                },
                EUR = {
                    USD = 1.18,
                    GBP = 0.88,
                    JPY = 130.00,
                    CAD = 1.47,
                    AUD = 1.59,
                    CHF = 1.08,
                    CNY = 7.60,
                    HKD = 9.17,
                    NZD = 1.67,
                    KRW = 1357.32,
                    EUR = 1,
                },
            },
            symbols = {
                USD = "$",
                EUR = "€",
                GBP = "£",
                JPY = "¥",
                CAD = "C$",
                AUD = "A$",
                CHF = "Fr",
                CNY = "¥",
                HKD = "HK$",
                NZD = "NZ$",
                KRW = "₩",
                TWD = "NT$",
            }
        }

        print("|cFF33FF99PeaversCurrencyData:|r Created sample currency data for testing")
    end

    if not PCD.TokenPrices then
        PCD.TokenPrices = {
            lastUpdated = date("%Y-%m-%d"),
            regions = {
                US = {
                    goldPrice = 250000, -- 250k gold for a token
                    realPrice = 20,     -- $20 USD
                    currency = "USD",
                    goldValue = 20 / 250000, -- Value of 1 gold in USD
                },
                EU = {
                    goldPrice = 300000, -- 300k gold for a token
                    realPrice = 20,     -- €20 EUR
                    currency = "EUR",
                    goldValue = 20 / 300000, -- Value of 1 gold in EUR
                },
                KR = {
                    goldPrice = 150000, -- 150k gold for a token
                    realPrice = 22000,  -- ₩22,000 KRW
                    currency = "KRW",
                    goldValue = 22000 / 150000, -- Value of 1 gold in KRW
                },
                TW = {
                    goldPrice = 200000, -- 200k gold for a token
                    realPrice = 500,    -- NT$500 TWD
                    currency = "TWD",
                    goldValue = 500 / 200000, -- Value of 1 gold in TWD
                },
            }
        }

        print("|cFF33FF99PeaversCurrencyData:|r Created sample token data for testing")
    end

    return true
end

-- Create sample data if needed
PCD:CreateSampleData()