# PeaversCurrencyData

[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/peavers/PeaversCurrencyData)](https://github.com/peavers/PeaversCurrencyData/commits/master) [![Last commit](https://img.shields.io/github/last-commit/peavers/PeaversCurrencyData)](https://github.com/peavers/PeaversCurrencyData/master)

**A World of Warcraft addon that provides real-time currency exchange rates and WoW gold conversion directly in-game.**

### New!
Check out [peavers.io](https://peavers.io) and [bootstrap.peavers.io](https://bootstrap.peavers.io) for all my WoW addons and support.

## Overview

PeaversCurrencyData delivers up-to-date exchange rates for major world currencies and WoW token prices across all regions. This addon helps players understand the real-world value of their gold and easily convert between different currencies, making it perfect for gold farmers, traders, and anyone curious about the economics of Azeroth.

## Features

- **Daily Updated Exchange Rates**: Automatically fetches the latest currency exchange rates for 12 major currencies
- **WoW Token Price Tracking**: Monitors token prices across all regions (US, EU, KR, TW)
- **Gold Value Conversion**: Instantly see what your gold is worth in real-world currency
- **Currency Conversion**: Convert between any supported currencies with accurate exchange rates
- **In-Game Commands**: Simple slash commands for all conversions and information
- **Chat Integration**: Share conversion results with others through the chat channel
- **Centralized API**: Clean, well-documented API for developers to integrate with other addons

## Installation

1. Download from the repository or use your favorite addon manager
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Ensure your folder structure is `Interface\AddOns\PeaversCurrencyData\PeaversCurrencyData.toc`
4. Reload your UI

## Usage

1. Use `/pcd` or `/peaverscurrency` to access commands
2. For basic gold value information: `/pcd goldvalue 1000`
3. For token prices across regions: `/pcd token`
4. To convert between currencies: `/pcd convert 10 USD EUR`
5. To share results in chat: `/pcd say goldvalue 1000`

## Configuration

- `/pcd default [currency]` - Set your default currency (e.g., USD, EUR, GBP)
- `/pcd region [region]` - Set your default region (US, EU, KR, TW)
- `/pcd info` - Display current addon settings and data age
- `/pcd help` - List all available commands

### Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `goldvalue` | Convert gold to real currency | `/pcd goldvalue 1000 USD` |
| `money` | Convert real currency to gold | `/pcd money 10 USD US` |
| `convert` | Convert between currencies | `/pcd convert 10 USD EUR` |
| `token` | Show token prices | `/pcd token` |
| `list` | List available currencies | `/pcd list` |
| `say` | Share results in chat | `/pcd say goldvalue 1000` |

## Support & Feedback

If you encounter any issues with the addon or have ideas for improvement, please submit them through the [repository's issue tracker](https://github.com/peavers/PeaversCurrencyData/issues). Your feedback helps make this addon more useful for the WoW community.

*"Know thy gold's worth, and thou shalt trade more wisely."*
