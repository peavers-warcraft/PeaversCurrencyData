local addonName, addon = ...

PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

local eventFrame = CreateFrame("Frame")
local commandHandlers = {}

local function LoadPreferences()
    PeaversCurrencyDataDB = PeaversCurrencyDataDB or {}

    if PeaversCurrencyDataDB.preferences then
        PCD.preferences = PeaversCurrencyDataDB.preferences
    else
        PCD.preferences = PCD.Utils.DeepCopy(PCD.Constants.DEFAULT_PREFERENCES)
    end
end

local function SavePreferences()
    PeaversCurrencyDataDB.preferences = PCD.preferences
end

local function OnAddonLoaded(name)
    if name ~= addonName then return end

    LoadPreferences()

end

local function OutputText(text, useChat)
    if useChat then
        SendChatMessage(text, "SAY")
    else
        print(text)
    end
end

commandHandlers.help = function(args, useChat)
    OutputText(PCD.Constants.ADDON_PREFIX .. " Commands:", useChat)
    OutputText("  /pcd info - Show addon information", useChat)
    OutputText("  /pcd convert [amount] [from] [to] - Convert currency", useChat)
    OutputText("  /pcd goldvalue [amount] [currency] [region] - Get the value of gold", useChat)
    OutputText("  /pcd money [amount] [currency] [region] - Convert real currency to gold", useChat)
    OutputText("  /pcd token - Show WoW token prices", useChat)
    OutputText("  /pcd list - List available currencies", useChat)
    OutputText("  /pcd default [currency] - Set default currency", useChat)
    OutputText("  /pcd region [region] - Set default region", useChat)
    OutputText("  Add --say to output results to /say channel", useChat)
end

commandHandlers.info = function(args, useChat)
    OutputText(PCD.Constants.ADDON_PREFIX .. ":", useChat)
    OutputText("  Version: " .. PCD.Constants.ADDON_VERSION, useChat)
    OutputText("  Data updated: " .. (PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "unknown"), useChat)
    OutputText("  Default currency: " .. PCD.preferences.defaultCurrency, useChat)
    OutputText("  Default region: " .. PCD.preferences.defaultRegion, useChat)
end

commandHandlers.convert = function(args, useChat)
    local amount, from, to = strsplit(" ", args, 3)
    amount = tonumber(amount)
    from = PCD.Utils.ToUpper(from)
    to = PCD.Utils.ToUpper(to)

    if not amount or not from or not to then
        OutputText("Usage: /pcd convert [amount] [from] [to]", useChat)
        return
    end

    local result = PCD:ConvertCurrency(amount, from, to)
    if result then
        local fromSymbol = PCD.CurrencyRates.symbols[from] or ""
        local toSymbol = PCD.CurrencyRates.symbols[to] or ""
        OutputText(string.format("%s%s %s = %s%s %s",
            fromSymbol, amount, from, toSymbol, result, to), useChat)
    else
        OutputText("Conversion failed. Make sure the currencies are valid.", useChat)
    end
end

commandHandlers.goldvalue = function(args, useChat)
    if not args or args == "" then
        OutputText("Usage: /pcd goldvalue [amount] [currency] [region]", useChat)
        OutputText("Example: /pcd goldvalue 1000 EUR", useChat)
        return
    end

    local amount, currency, region = strsplit(" ", args, 3)
    amount = tonumber(amount)

    if not amount then
        OutputText("Invalid amount. Usage: /pcd goldvalue [amount] [currency] [region]", useChat)
        return
    end

    currency = PCD.Utils.ToUpper(currency) or PCD.preferences.defaultCurrency
    region = PCD.Utils.ToUpper(region) or PCD.preferences.defaultRegion

    local result = PCD:GoldToCurrency(amount, region, currency)
    if result then
        local symbol = PCD.CurrencyRates.symbols[currency] or ""
        OutputText(string.format("%s = %s%s %s",
            PCD:FormatWoWCurrency(amount),
            symbol,
            string.format("%.2f", result),
            currency), useChat)
    else
        OutputText("Conversion failed. Check currency and region.", useChat)
    end
end

commandHandlers.gv = commandHandlers.goldvalue

commandHandlers.money = function(args, useChat)
    if not args or args == "" then
        OutputText("Usage: /pcd money [amount] [currency] [region]", useChat)
        OutputText("Example: /pcd money 10 USD US", useChat)
        return
    end

    local amount, currency, region = strsplit(" ", args, 3)
    amount = tonumber(amount)

    if not amount then
        OutputText("Invalid amount. Usage: /pcd money [amount] [currency] [region]", useChat)
        return
    end

    currency = PCD.Utils.ToUpper(currency) or PCD.preferences.defaultCurrency
    region = PCD.Utils.ToUpper(region) or PCD.preferences.defaultRegion

    local result = PCD:CurrencyToGold(amount, currency, region)
    if result then
        local symbol = PCD.CurrencyRates.symbols[currency] or ""
        OutputText(string.format("%s%s %s = %s",
            symbol,
            amount,
            currency,
            PCD:FormatWoWCurrency(result)), useChat)
    else
        OutputText("Conversion failed. Check currency and region.", useChat)
    end
end

commandHandlers.m = commandHandlers.money

commandHandlers.token = function(args, useChat)
    OutputText(PCD.Constants.ADDON_PREFIX .. " Token Prices:", useChat)
    for region, data in pairs(PCD.TokenPrices and PCD.TokenPrices.regions or {}) do
        local symbol = PCD.CurrencyRates.symbols[data.currency] or ""
        OutputText(string.format("  %s: %s (%s%s %s)",
            region,
            PCD:FormatWoWCurrency(data.goldPrice),
            symbol,
            data.realPrice,
            data.currency), useChat)

        local goldValue = data.goldValue
        OutputText(string.format("  1 gold = %s%s %s",
            symbol,
            string.format("%.8f", goldValue),
            data.currency), useChat)
    end
end

commandHandlers.list = function(args, useChat)
    OutputText(PCD.Constants.ADDON_PREFIX .. " Available Currencies:", useChat)
    local currencies = PCD:GetAvailableCurrencies()
    table.sort(currencies)

    for i, currency in ipairs(currencies) do
        local symbol = PCD.CurrencyRates.symbols[currency] or ""
        OutputText(string.format("  %s (%s)", currency, symbol), useChat)
    end
end

commandHandlers.default = function(args, useChat)
    if args and PCD.Utils.IsValidCurrency(args:upper()) then
        PCD.preferences.defaultCurrency = args:upper()
        OutputText("Default currency set to: " .. args:upper(), useChat)
    else
        OutputText("Current default currency: " .. PCD.preferences.defaultCurrency, useChat)
        OutputText("Usage: /pcd default [currency]", useChat)
    end
end

commandHandlers.region = function(args, useChat)
    if args and PCD.Utils.IsValidRegion(args:upper()) then
        PCD.preferences.defaultRegion = args:upper()
        OutputText("Default region set to: " .. args:upper(), useChat)
    else
        OutputText("Current default region: " .. PCD.preferences.defaultRegion, useChat)
        OutputText("Usage: /pcd region [US|EU|KR|TW]", useChat)
    end
end

local function HandleSlashCommand(msg)
    local useChat = false
    if msg:find("--say") then
        useChat = true
        msg = PCD.Utils.Trim(msg:gsub("--say", ""))
    end

    local cmd, args = strsplit(" ", msg, 2)
    cmd = cmd:lower()

    -- Check for empty command
    if cmd == "" then
        cmd = "help"
    end

    -- Check for alias
    cmd = PCD.Constants.COMMAND_ALIASES[cmd] or cmd

    -- Execute handler
    local handler = commandHandlers[cmd]
    if handler then
        handler(args, useChat)
    else
        OutputText("Unknown command. Type /pcd help for available commands.", useChat)
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "PLAYER_LOGOUT" then
        SavePreferences()
    end
end)

PCD.Utils.RegisterEvents(eventFrame, {"ADDON_LOADED", "PLAYER_LOGOUT"})

SLASH_PEAVERSCURRENCY1 = PCD.Constants.SLASH_COMMANDS.primary
SLASH_PEAVERSCURRENCY2 = PCD.Constants.SLASH_COMMANDS.secondary
SlashCmdList["PEAVERSCURRENCY"] = HandleSlashCommand
