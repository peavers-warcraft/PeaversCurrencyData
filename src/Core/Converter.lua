-- PeaversCurrencyData/src/Core/Converter.lua
local addonName, addon = ...

-- Initialize addon namespace
PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

-- Cache for performance
local goldConversionCache = {}

--[[
    Converts WoW gold to a real-world currency
    @param goldAmount The amount of gold to convert
    @param region (optional) The WoW region (US, EU, KR, TW, default: US)
    @param currency (optional) The currency to convert to (default: region's native currency)
    @param roundDecimals (optional) Number of decimal places to round to
    @return The converted amount in the specified currency
]]
function PCD:GoldToCurrency(goldAmount, region, currency, roundDecimals)
    -- Validate input
    if not goldAmount or type(goldAmount) ~= "number" then
        return nil
    end

    region = region or "US"

    -- Check if we have token data for this region
    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]
    currency = currency or tokenData.currency

    -- Calculate the value in the region's native currency
    local value = goldAmount * tokenData.goldValue

    -- If we're requesting a different currency, convert it
    if currency ~= tokenData.currency then
        value = PCD:ConvertCurrency(value, tokenData.currency, currency)
    end

    -- Round if requested
    if roundDecimals or PCD.preferences.decimalPlaces then
        local decimals = roundDecimals or PCD.preferences.decimalPlaces
        local mult = 10 ^ decimals
        value = math.floor(value * mult + 0.5) / mult
    end

    return value
end

--[[
    Converts a real-world currency amount to WoW gold
    @param currencyAmount The amount of currency to convert
    @param currency The currency code (e.g., "USD")
    @param region (optional) The WoW region (US, EU, KR, TW, default: based on currency)
    @param roundDecimals (optional) Number of decimal places to round to
    @return The converted amount in gold
]]
function PCD:CurrencyToGold(currencyAmount, currency, region, roundDecimals)
    -- Validate input
    if not currencyAmount or type(currencyAmount) ~= "number" or not currency then
        return nil
    end

    currency = currency:upper()

    -- If region not specified, try to determine based on currency
    if not region then
        if currency == "USD" then
            region = "US"
        elseif currency == "EUR" then
            region = "EU"
        elseif currency == "KRW" then
            region = "KR"
        elseif currency == "TWD" then
            region = "TW"
        else
            -- Default to US if we can't determine
            region = "US"
        end
    end

    -- Check if we have token data for this region
    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]

    -- Convert to the region's currency if needed
    local regionCurrencyAmount = currencyAmount
    if currency ~= tokenData.currency then
        regionCurrencyAmount = PCD:ConvertCurrency(currencyAmount, currency, tokenData.currency)
        if not regionCurrencyAmount then
            return nil
        end
    end

    -- Calculate gold value
    local goldAmount = regionCurrencyAmount / tokenData.goldValue

    -- Round if requested
    if roundDecimals then
        local mult = 10 ^ roundDecimals
        goldAmount = math.floor(goldAmount * mult + 0.5) / mult
    end

    return goldAmount
end

--[[
    Gets the real-world value of 1 gold in the specified currency
    @param region (optional) The WoW region (US, EU, KR, TW, default: US)
    @param currency (optional) The currency code (default: region's native currency)
    @return The value of 1 gold in the specified currency
]]
function PCD:GetGoldValue(region, currency)
    region = region or "US"

    -- Check if we have token data for this region
    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]
    currency = currency or tokenData.currency

    -- If the requested currency is the same as the region's currency, return the gold value
    if currency == tokenData.currency then
        return tokenData.goldValue
    end

    -- Otherwise, convert the gold value from the region's currency to the requested currency
    return PCD:ConvertCurrency(tokenData.goldValue, tokenData.currency, currency)
end

--[[
    Gets WoW Token price data for the specified region
    @param region (optional) The WoW region (US, EU, KR, TW, default: US)
    @return A table with token data for the region
]]
function PCD:GetTokenData(region)
    region = region or "US"

    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    return PCD.TokenPrices.regions[region]
end

--[[
    Formats a gold amount with proper WoW formatting
    @param amount The amount of gold
    @param includeIcons (optional) Whether to include gold/silver/copper icons (default: true)
    @param colorize (optional) Whether to colorize the output (default: true)
    @return A formatted string (e.g., "1g 25s 10c" or "|cFFFFD70025|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
]]
function PCD:FormatWoWCurrency(amount, includeIcons, colorize)
    if not amount then
        return "0g"
    end

    -- Default parameters
    if includeIcons == nil then includeIcons = true end
    if colorize == nil then colorize = true end

    -- Split into gold, silver, copper
    local gold = math.floor(amount)
    local silver = math.floor((amount - gold) * 100)
    local copper = math.floor((((amount - gold) * 100) - silver) * 100)

    -- Format without icons
    if not includeIcons then
        local result = ""
        if gold > 0 then result = result .. gold .. "g " end
        if silver > 0 or gold > 0 then result = result .. silver .. "s " end
        result = result .. copper .. "c"
        return result
    end

    -- Format with icons
    local result = ""

    -- Gold
    if gold > 0 then
        if colorize then
            result = result .. "|cFFFFD700" .. gold .. "|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t "
        else
            result = result .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t "
        end
    end

    -- Silver
    if silver > 0 or gold > 0 then
        if colorize then
            result = result .. "|cFFC0C0C0" .. silver .. "|r|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t "
        else
            result = result .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t "
        end
    end

    -- Copper
    if colorize then
        result = result .. "|cFFB87333" .. copper .. "|r|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"
    else
        result = result .. copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"
    end

    return result
end
