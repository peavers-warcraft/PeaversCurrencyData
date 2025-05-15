-- PeaversCurrencyData/src/Core/API.lua
local addonName, addon = ...

-- Initialize addon namespace if not already done
PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

-- Cache for conversions
local conversionCache = {}

--[[
    Gets the exchange rate between two currencies
    @param fromCurrency The source currency code (e.g., "USD")
    @param toCurrency The target currency code (e.g., "EUR")
    @return The exchange rate or nil if not available
]]
function PCD:GetExchangeRate(fromCurrency, toCurrency)
    -- Validate input
    fromCurrency = fromCurrency and fromCurrency:upper()
    toCurrency = toCurrency and toCurrency:upper()

    if not fromCurrency or not toCurrency then
        return nil
    end

    -- Check for same currency
    if fromCurrency == toCurrency then
        return 1
    end

    -- Check if we have direct rates
    if PCD.CurrencyRates and PCD.CurrencyRates.rates[fromCurrency] and PCD.CurrencyRates.rates[fromCurrency][toCurrency] then
        return PCD.CurrencyRates.rates[fromCurrency][toCurrency]
    end

    -- If we have the inverse, use that
    if PCD.CurrencyRates and PCD.CurrencyRates.rates[toCurrency] and PCD.CurrencyRates.rates[toCurrency][fromCurrency] then
        return 1 / PCD.CurrencyRates.rates[toCurrency][fromCurrency]
    end

    -- If we have rates for both currencies to USD, we can calculate a cross rate
    if fromCurrency ~= "USD" and toCurrency ~= "USD" and
        PCD.CurrencyRates and PCD.CurrencyRates.rates["USD"] and
        PCD.CurrencyRates.rates["USD"][fromCurrency] and PCD.CurrencyRates.rates["USD"][toCurrency] then
        -- USD/FROM * USD/TO
        local usdToFrom = 1 / PCD.CurrencyRates.rates["USD"][fromCurrency]
        local usdToTo = PCD.CurrencyRates.rates["USD"][toCurrency]
        return usdToFrom * usdToTo
    end

    -- No conversion possible
    return nil
end

--[[
    Converts an amount from one currency to another
    @param amount The amount to convert
    @param fromCurrency The source currency code (e.g., "USD")
    @param toCurrency The target currency code (e.g., "EUR")
    @param roundDecimals (optional) Number of decimal places to round to
    @return The converted amount or nil if conversion is not possible
]]
function PCD:ConvertCurrency(amount, fromCurrency, toCurrency, roundDecimals)
    -- Validate input
    if not amount or type(amount) ~= "number" then
        return nil
    end

    fromCurrency = fromCurrency and fromCurrency:upper()
    toCurrency = toCurrency and toCurrency:upper()

    if not fromCurrency or not toCurrency then
        return nil
    end

    -- Same currency, no conversion needed
    if fromCurrency == toCurrency then
        return amount
    end

    -- Check cache first
    local cacheKey = fromCurrency .. ":" .. toCurrency
    if conversionCache[cacheKey] then
        return amount * conversionCache[cacheKey]
    end

    -- Get the exchange rate
    local rate = PCD:GetExchangeRate(fromCurrency, toCurrency)
    if not rate then
        return nil
    end

    -- Cache the rate for future use
    conversionCache[cacheKey] = rate

    -- Convert the amount
    local result = amount * rate

    -- Round if requested
    if roundDecimals or PCD.preferences.decimalPlaces then
        local decimals = roundDecimals or PCD.preferences.decimalPlaces
        local mult = 10 ^ decimals
        result = math.floor(result * mult + 0.5) / mult
    end

    return result
end

--[[
    Gets a list of all available currencies
    @return An array of currency codes
]]
function PCD:GetAvailableCurrencies()
    local currencies = {}

    if PCD.CurrencyRates and PCD.CurrencyRates.rates then
        for currency, _ in pairs(PCD.CurrencyRates.rates) do
            table.insert(currencies, currency)
        end
    end

    return currencies
end

--[[
    Gets the timestamp when the currency data was last updated
    @return A string with the last update date (YYYY-MM-DD)
]]
function PCD:GetLastUpdated()
    return PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "Unknown"
end

--[[
    Gets the currency symbol for a given currency code
    @param currencyCode The currency code (e.g., "USD")
    @return The currency symbol (e.g., "$") or the currency code if no symbol is found
]]
function PCD:GetCurrencySymbol(currencyCode)
    currencyCode = currencyCode and currencyCode:upper()

    if not currencyCode or not PCD.CurrencyRates or not PCD.CurrencyRates.symbols then
        return currencyCode
    end

    return PCD.CurrencyRates.symbols[currencyCode] or currencyCode
end

--[[
    Formats a currency amount with the appropriate symbol
    @param amount The amount to format
    @param currencyCode The currency code
    @param symbolPosition "before" or "after" (default based on currency)
    @param decimalPlaces Number of decimal places (default from preferences)
    @return A formatted string (e.g., "$10.50" or "10,50€")
]]
function PCD:FormatCurrency(amount, currencyCode, symbolPosition, decimalPlaces)
    if not amount or not currencyCode then
        return tostring(amount)
    end

    currencyCode = currencyCode:upper()
    decimalPlaces = decimalPlaces or PCD.preferences.decimalPlaces or 2

    local symbol = PCD:GetCurrencySymbol(currencyCode)

    -- Default symbol positions based on currency
    if not symbolPosition then
        -- These currencies typically have symbol after the amount
        local afterSymbolCurrencies = {
            EUR = true,
            SEK = true,
            NOK = true,
            DKK = true,
            PLN = true,
            CZK = true
        }

        symbolPosition = afterSymbolCurrencies[currencyCode] and "after" or "before"
    end

    -- Format the number with proper decimals
    local formattedNumber = string.format("%." .. decimalPlaces .. "f", amount)

    -- Add the symbol
    if symbolPosition == "before" then
        return symbol .. formattedNumber
    else
        return formattedNumber .. symbol
    end
end