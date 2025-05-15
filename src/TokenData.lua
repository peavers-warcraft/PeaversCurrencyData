-- Auto-generated token data file
-- Last updated: 2025-05-15

PeaversCurrencyData = PeaversCurrencyData or {}

-- WoW Token prices across regions
PeaversCurrencyData.wowToken = {
  US = {
    goldPrice = 245750,  -- Gold cost of a token
    realPrice = 20,      -- USD cost of a token
    currency = "USD",
    goldValue = 0.0000813835, -- USD value of 1 gold
  },
  EU = {
    goldPrice = 313420,  -- Gold cost of a token
    realPrice = 20,      -- EUR cost of a token
    currency = "EUR",
    goldValue = 0.0000638121, -- EUR value of 1 gold
  },
  KR = {
    goldPrice = 176420,  -- Gold cost of a token
    realPrice = 22000,      -- KRW cost of a token
    currency = "KRW",
    goldValue = 0.1247024147, -- KRW value of 1 gold
  },
  TW = {
    goldPrice = 184260,  -- Gold cost of a token
    realPrice = 500,      -- TWD cost of a token
    currency = "TWD",
    goldValue = 0.0027135569, -- TWD value of 1 gold
  },
}

-- Helper functions for token data access (these will be directly accessible)
function PeaversCurrencyData:GetGoldValue(region, currency)
  region = region or "US"
  local tokenData = self.wowToken[region]
  if not tokenData then return nil end

  currency = currency or tokenData.currency
  
  -- If the requested currency is the same as the region's currency, return the gold value
  if currency == tokenData.currency then
    return tokenData.goldValue
  end

  -- Otherwise, convert the gold value from the region's currency to the requested currency
  return self:ConvertCurrency(tokenData.goldValue, tokenData.currency, currency)
end
