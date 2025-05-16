-- PeaversCurrencyData/src/Core/Currency.lua
local addonName, addon = ...

-- Initialize addon namespace
PeaversCurrencyData = PeaversCurrencyData or {}
local PCD = PeaversCurrencyData

-- Constants for WoW currency conversion
PCD.COPPER_PER_SILVER = 100
PCD.SILVER_PER_GOLD = 100
PCD.COPPER_PER_GOLD = PCD.COPPER_PER_SILVER * PCD.SILVER_PER_GOLD -- 10000

--[[
    Converts copper to gold
    @param copper Amount in copper
    @return Amount in gold (float)
]]
function PCD:CopperToGold(copper)
	return copper / PCD.COPPER_PER_GOLD
end

--[[
    Converts gold to copper
    @param gold Amount in gold
    @return Amount in copper (integer)
]]
function PCD:GoldToCopper(gold)
	return math.floor(gold * PCD.COPPER_PER_GOLD + 0.5)
end

--[[
    Formats a gold amount with proper WoW formatting
    @param goldAmount The amount of gold (can be fractional)
    @param includeIcons (optional) Whether to include gold/silver/copper icons (default: true)
    @param colorize (optional) Whether to colorize the output (default: true)
    @return A formatted string (e.g., "1g 25s 10c" or "|cFFFFD70025|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
]]
function PCD:FormatWoWCurrency(goldAmount, includeIcons, colorize)
	if not goldAmount then
		return "0g"
	end

	-- Default parameters
	if includeIcons == nil then includeIcons = true end
	if colorize == nil then colorize = true end

	-- Convert to copper for precision
	local totalCopper = PCD:GoldToCopper(goldAmount)

	-- Split into gold, silver, copper
	local copper = totalCopper % PCD.COPPER_PER_SILVER
	local totalSilver = math.floor(totalCopper / PCD.COPPER_PER_SILVER)
	local silver = totalSilver % PCD.SILVER_PER_GOLD
	local gold = math.floor(totalSilver / PCD.SILVER_PER_GOLD)

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
