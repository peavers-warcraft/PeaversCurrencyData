local _, addon = ...
local PCD = PeaversCurrencyData

local Constants = {}
PCD.Constants = Constants

-- Addon info
Constants.ADDON_NAME = "PeaversCurrencyData"
Constants.ADDON_VERSION = "1.0.1"
Constants.ADDON_PREFIX = "|cFF33FF99PeaversCurrencyData|r"

-- Currency constants
Constants.COPPER_PER_SILVER = 100
Constants.SILVER_PER_GOLD = 100
Constants.COPPER_PER_GOLD = Constants.COPPER_PER_SILVER * Constants.SILVER_PER_GOLD

-- WoW money icons
Constants.GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t"
Constants.SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t"
Constants.COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"

-- Colors
Constants.GOLD_COLOR = "|cFFFFD700"
Constants.SILVER_COLOR = "|cFFC0C0C0"
Constants.COPPER_COLOR = "|cFFB87333"
Constants.ADDON_COLOR = "|cFF33FF99"

-- Regions
Constants.REGIONS = {
    US = true,
    EU = true,
    KR = true,
    TW = true
}

Constants.DEFAULT_REGION = "US"

-- Currency codes that typically have symbols after the amount
Constants.SUFFIX_CURRENCIES = {
    EUR = true,
    SEK = true,
    NOK = true,
    DKK = true,
    PLN = true,
    CZK = true
}

-- Major currencies
Constants.MAJOR_CURRENCIES = {
	"USD", "EUR", "GBP", "JPY", "CAD", "AUD",
    "CHF", "CNY", "HKD", "NZD", "KRW", "TWD"
}

-- Token real prices by region
Constants.TOKEN_PRICES = {
    US = { price = 20, currency = "USD" },
    EU = { price = 20, currency = "EUR" },
    KR = { price = 22000, currency = "KRW" },
    TW = { price = 500, currency = "TWD" }
}

-- Cache settings
Constants.CACHE_EXPIRY = 300 -- 5 minutes

-- Default preferences
Constants.DEFAULT_PREFERENCES = {
    defaultCurrency = "USD",
    decimalPlaces = 2,
    defaultRegion = "US",
    debugMode = false,
    useColoredOutput = true,
    useMoneyIcons = true
}

-- Command aliases
Constants.SLASH_COMMANDS = {
    primary = "/pcd",
    secondary = "/peaverscurrency"
}

-- Sub-command aliases
Constants.COMMAND_ALIASES = {
    g = "gold",
    m = "money",
    gv = "goldvalue"
}

return Constants
