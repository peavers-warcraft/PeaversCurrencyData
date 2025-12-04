local _, addon = ...

PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

local Converter = {}
PCD.Converter = Converter

local goldValueCache = {}
local cacheTimestamps = {}

local function GetCacheKey(region, currency, isGoldToRealWorld)
    return string.format("%s:%s:%s", region, currency, isGoldToRealWorld and "gtr" or "rtg")
end

local function IsCacheExpired(key)
    local timestamp = cacheTimestamps[key]
    if not timestamp then return true end
    return (GetTime() - timestamp) > PCD.Constants.CACHE_EXPIRY
end

local function GetRegionFromCurrency(currency)
    local currencyToRegion = {
        USD = "US",
        EUR = "EU",
        KRW = "KR",
        TWD = "TW"
    }
    return currencyToRegion[currency] or "US"
end

function Converter.GoldToCurrency(goldAmount, region, currency, roundDecimals)
    if not goldAmount or type(goldAmount) ~= "number" then
        return nil
    end

    region = region or PCD.preferences.defaultRegion or "US"

    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]
    currency = currency or tokenData.currency

    local cacheKey = GetCacheKey(region, currency, true)

    local value
    if not IsCacheExpired(cacheKey) and goldValueCache[cacheKey] then
        value = goldAmount * goldValueCache[cacheKey]
    else
        value = goldAmount * tokenData.goldValue

        if currency ~= tokenData.currency then
            value = PCD.API.ConvertCurrency(value, tokenData.currency, currency)
        end

        goldValueCache[cacheKey] = value / goldAmount
        cacheTimestamps[cacheKey] = GetTime()
    end

    if roundDecimals then
        return PCD.Utils.Round(value, roundDecimals)
    elseif PCD.preferences and PCD.preferences.decimalPlaces then
        if value > 0 and value < 10^(-PCD.preferences.decimalPlaces) then
            local digits = math.ceil(math.abs(math.log10(value))) + 2
            roundDecimals = math.max(PCD.preferences.decimalPlaces, digits)
        else
            roundDecimals = PCD.preferences.decimalPlaces
        end
        return PCD.Utils.Round(value, roundDecimals)
    end

    return value
end

function Converter.CurrencyToGold(currencyAmount, currency, region, roundDecimals)
    if not currencyAmount or type(currencyAmount) ~= "number" or not currency then
        return nil
    end

    currency = currency:upper()

    if not region then
        region = GetRegionFromCurrency(currency)
    end

    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]

    local regionCurrencyAmount = currencyAmount
    if currency ~= tokenData.currency then
        regionCurrencyAmount = PCD.API.ConvertCurrency(currencyAmount, currency, tokenData.currency)
        if not regionCurrencyAmount then
            return nil
        end
    end

    local goldAmount = regionCurrencyAmount / tokenData.goldValue

    if roundDecimals then
        return PCD.Utils.Round(goldAmount, roundDecimals)
    end

    return goldAmount
end

function Converter.GetGoldValue(region, currency)
    region = region or "US"

    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    local tokenData = PCD.TokenPrices.regions[region]
    currency = currency or tokenData.currency

    if currency == tokenData.currency then
        return tokenData.goldValue
    end

    return PCD.API.ConvertCurrency(tokenData.goldValue, tokenData.currency, currency)
end

function Converter.GetTokenData(region)
    region = region or "US"

    if not PCD.TokenPrices or not PCD.TokenPrices.regions or not PCD.TokenPrices.regions[region] then
        return nil
    end

    return PCD.Utils.DeepCopy(PCD.TokenPrices.regions[region])
end

function Converter.ClearCache()
    goldValueCache = {}
    cacheTimestamps = {}
end

-- Compatibility layer
function PCD:GoldToCurrency(...)
    return Converter.GoldToCurrency(...)
end

function PCD:CurrencyToGold(...)
    return Converter.CurrencyToGold(...)
end

function PCD:GetGoldValue(...)
    return Converter.GetGoldValue(...)
end

function PCD:GetTokenData(...)
    return Converter.GetTokenData(...)
end

return Converter
