# PeaversCurrencyData

A World of Warcraft addon providing real-time currency exchange rates and WoW token prices across all regions.

**Website:** [peavers.io](https://peavers.io) | **Addon Backup:** [vault.peavers.io](https://vault.peavers.io) | **Issues:** [GitHub](https://github.com/peavers-warcraft/PeaversCurrencyData/issues)

## Features

- Daily updated exchange rates for 12 major currencies
- WoW token price tracking across all regions (US, EU, KR, TW)
- Gold to real-world currency conversion
- Currency-to-currency conversion
- Developer-friendly API for addon integration

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaverscurrencydata)
2. Enable the addon on the character selection screen

## Usage

Use `/pcd` or `/peaverscurrency` commands:

| Command | Description |
|---------|-------------|
| `/pcd help` | Show all available commands |
| `/pcd goldvalue [amount]` | Convert gold to your default currency |
| `/pcd money [amount] [currency]` | Convert real money to gold |
| `/pcd convert [amount] [from] [to]` | Convert between currencies |
| `/pcd token` | Show token prices across all regions |
| `/pcd list` | List all supported currencies |
| `/pcd default [currency]` | Set your default currency |
| `/pcd region [region]` | Set your default region |

## Supported Currencies

USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, HKD, NZD, KRW, TWD

## For Developers

```lua
local euros = PeaversCurrencyData:ConvertCurrency(100, "USD", "EUR")
local dollars = PeaversCurrencyData:GoldToCurrency(10000, "US", "USD")
local gold = PeaversCurrencyData:CurrencyToGold(20, "USD", "US")
local tokenData = PeaversCurrencyData:GetTokenData("US")
```

## Data Sources

- Currency exchange rates: [Fawaz Ahmed Currency API](https://github.com/fawazahmed0/currency-api)
- WoW token prices: Official Blizzard API
