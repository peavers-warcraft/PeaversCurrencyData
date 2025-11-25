# PeaversCurrencyData
**Real-time currency exchange rates and WoW token prices for World of Warcraft**

## Overview

PeaversCurrencyData provides up-to-date exchange rates for major world currencies and WoW token prices across all regions. This addon helps players understand the real-world value of their gold and easily convert between different currencies.

## Features

- 📈 **Daily Updated Exchange Rates**: Automatically fetches latest currency exchange rates for 12 major currencies
- 🪙 **WoW Token Price Tracking**: Monitors token prices across all regions (US, EU, KR, TW)
- 💰 **Gold Value Conversion**: Instantly see what your gold is worth in real-world currency
- 💱 **Currency Conversion**: Convert between any supported currencies with accurate exchange rates
- ⚡ **Performance Optimized**: Intelligent caching system reduces calculation overhead
- 🎨 **Clean Interface**: Simple slash commands with colorized output
- 🔧 **Developer Friendly**: Well-documented API for integration with other addons

## Installation

### Curse/WowUp
1. Search for "PeaversCurrencyData" in your addon manager
2. Click Install

### Manual Installation
1. Download the latest release from GitHub
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Ensure folder structure is `AddOns/PeaversCurrencyData/PeaversCurrencyData.toc`
4. Restart WoW or type `/reload`

## Usage

The addon uses `/pcd` or `/peaverscurrency` commands:

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/pcd help` | Show all available commands | |
| `/pcd goldvalue [amount]` | Convert gold to your default currency | `/pcd goldvalue 1000` |
| `/pcd money [amount] [currency]` | Convert real money to gold | `/pcd money 10 USD` |
| `/pcd convert [amount] [from] [to]` | Convert between currencies | `/pcd convert 10 USD EUR` |
| `/pcd token` | Show token prices across all regions | |
| `/pcd list` | List all supported currencies | |

### Configuration

- `/pcd default [currency]` - Set your default currency (e.g., USD, EUR, GBP)
- `/pcd region [region]` - Set your default region (US, EU, KR, TW)
- `/pcd info` - Show current settings and data age

### Sharing Results

Add `--say` to any command to share the result in chat:
```
/pcd goldvalue 10000 --say
```

## Supported Currencies

- USD - US Dollar
- EUR - Euro
- GBP - British Pound
- JPY - Japanese Yen
- CAD - Canadian Dollar
- AUD - Australian Dollar
- CHF - Swiss Franc
- CNY - Chinese Yuan
- HKD - Hong Kong Dollar
- NZD - New Zealand Dollar
- KRW - South Korean Won
- TWD - Taiwan Dollar

## API for Developers

PeaversCurrencyData provides a clean API for integration:

```lua
-- Convert currency
local euros = PeaversCurrencyData:ConvertCurrency(100, "USD", "EUR")

-- Get gold value in real currency
local dollars = PeaversCurrencyData:GoldToCurrency(10000, "US", "USD")

-- Convert real currency to gold
local gold = PeaversCurrencyData:CurrencyToGold(20, "USD", "US")

-- Get token data for a region
local tokenData = PeaversCurrencyData:GetTokenData("US")
```

## Data Sources

- Currency exchange rates: [Fawaz Ahmed Currency API](https://github.com/fawazahmed0/currency-api)
- WoW token prices: Official Blizzard API

<!-- Workflow triggered: 2025-06-16T10:45:56.857749 -->
