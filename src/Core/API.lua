local _, addon = ...

PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

local API = {}
PCD.API = API

local conversionCache = {}
local cacheTimestamps = {}

local function GetCacheKey(fromCurrency, toCurrency)
	return fromCurrency .. ":" .. toCurrency
end

local function IsCacheExpired(key)
	local timestamp = cacheTimestamps[key]
	if not timestamp then return true end
	return (GetTime() - timestamp) > PCD.Constants.CACHE_EXPIRY
end

function API.GetExchangeRate(fromCurrency, toCurrency)
	fromCurrency = PCD.Utils.ToUpper(fromCurrency)
	toCurrency = PCD.Utils.ToUpper(toCurrency)

	if not fromCurrency or not toCurrency then return nil end
	if fromCurrency == toCurrency then return 1 end

	local cacheKey = GetCacheKey(fromCurrency, toCurrency)
	if conversionCache[cacheKey] and not IsCacheExpired(cacheKey) then
		return conversionCache[cacheKey]
	end

	local rates = PCD.CurrencyRates and PCD.CurrencyRates.rates
	if not rates then return nil end

	local rate = nil

	if rates[fromCurrency] and rates[fromCurrency][toCurrency] then
		rate = rates[fromCurrency][toCurrency]
	elseif rates[toCurrency] and rates[toCurrency][fromCurrency] then
		rate = 1 / rates[toCurrency][fromCurrency]
	elseif fromCurrency ~= "USD" and toCurrency ~= "USD" then
		if rates["USD"] and rates["USD"][fromCurrency] and rates["USD"][toCurrency] then
			rate = rates["USD"][toCurrency] / rates["USD"][fromCurrency]
		end
	end

	if rate then
		conversionCache[cacheKey] = rate
		cacheTimestamps[cacheKey] = GetTime()
	end

	return rate
end

function API.ConvertCurrency(amount, fromCurrency, toCurrency, roundDecimals)
	if not amount or type(amount) ~= "number" then return nil end

	fromCurrency = PCD.Utils.ToUpper(fromCurrency)
	toCurrency = PCD.Utils.ToUpper(toCurrency)

	if not fromCurrency or not toCurrency then return nil end
	if fromCurrency == toCurrency then return amount end

	local rate = API.GetExchangeRate(fromCurrency, toCurrency)
	if not rate then return nil end

	local result = amount * rate

	if roundDecimals then
		result = PCD.Utils.Round(result, roundDecimals)
	elseif PCD.preferences and PCD.preferences.decimalPlaces then
		result = PCD.Utils.Round(result, PCD.preferences.decimalPlaces)
	end

	return result
end

function API.GetAvailableCurrencies()
	if not PCD.CurrencyRates or not PCD.CurrencyRates.rates then
		return {}
	end

	return PCD.Utils.TableKeys(PCD.CurrencyRates.rates)
end

function API.GetLastUpdated()
	return PCD.CurrencyRates and PCD.CurrencyRates.lastUpdated or "Unknown"
end

function API.GetCurrencySymbol(currencyCode)
	currencyCode = PCD.Utils.ToUpper(currencyCode)

	if not currencyCode or not PCD.CurrencyRates or not PCD.CurrencyRates.symbols then
		return currencyCode
	end

	return PCD.CurrencyRates.symbols[currencyCode] or currencyCode
end

function API.FormatCurrency(amount, currencyCode, symbolPosition, decimalPlaces)
	if not amount or not currencyCode then
		return tostring(amount)
	end

	currencyCode = currencyCode:upper()
	decimalPlaces = decimalPlaces or PCD.preferences.decimalPlaces or 2

	local symbol = API.GetCurrencySymbol(currencyCode)

	if not symbolPosition then
		symbolPosition = PCD.Constants.SUFFIX_CURRENCIES[currencyCode] and "after" or "before"
	end

	local formattedNumber = string.format("%." .. decimalPlaces .. "f", amount)

	return symbolPosition == "before" and (symbol .. formattedNumber) or (formattedNumber .. symbol)
end

function API.ClearCache()
	conversionCache = {}
	cacheTimestamps = {}
end

-- Compatibility layer
function PCD:GetExchangeRate(...)
	return API.GetExchangeRate(...)
end

function PCD:ConvertCurrency(...)
	return API.ConvertCurrency(...)
end

function PCD:GetAvailableCurrencies()
	return API.GetAvailableCurrencies()
end

function PCD:GetLastUpdated()
	return API.GetLastUpdated()
end

function PCD:GetCurrencySymbol(...)
	return API.GetCurrencySymbol(...)
end

function PCD:FormatCurrency(...)
	return API.FormatCurrency(...)
end

return API
