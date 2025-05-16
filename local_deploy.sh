#!/bin/bash

# PeaversCurrencyData local deployment script for macOS
# This script copies the addon files to the WoW retail addon directory

# Default WoW addon path for macOS
WOW_ADDON_PATH="/Applications/World of Warcraft/_retail_/Interface/AddOns/PeaversCurrencyData"

# Get the current directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if WoW is installed at the default location
if [ ! -d "/Applications/World of Warcraft" ]; then
    echo "World of Warcraft not found at default location: /Applications/World of Warcraft"
    echo "Please modify the WOW_ADDON_PATH variable in this script"
    exit 1
fi

# Create the destination directory if it doesn't exist
if [ ! -d "$WOW_ADDON_PATH" ]; then
    echo "Creating addon directory: $WOW_ADDON_PATH"
    mkdir -p "$WOW_ADDON_PATH"
fi

# Use rsync to synchronize directories
echo "Deploying PeaversCurrencyData to: $WOW_ADDON_PATH"
rsync -av --delete \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='node_modules' \
    --exclude='scripts' \
    --exclude='CLAUDE.md' \
    --exclude='local_deploy.sh' \
    --exclude='local_deploy.ps1' \
    "$CURRENT_DIR/" "$WOW_ADDON_PATH/"

echo "Deployment complete! Reload your UI in-game with /reload"