-- PeaversCurrencyData luacheck config. Thin wrapper over the shared Peavers base (../wow-api).
-- The base supplies the lua51+wow standard, ignore/exclude policy, and stds.wow (WoW API:
-- generated from /papidump when present, else curated). allow_defined_top is off, so every
-- global this addon creates must be listed below — that list is its documented _G footprint.
-- Run: ../wow-api/scripts/lint.sh   (override package path with WOW_API_DIR)

local apiDir = (os and os.getenv and os.getenv("WOW_API_DIR")) or "../wow-api"
local base = assert(loadfile(apiDir .. "/config/luacheckrc.base.lua"))(apiDir)

std             = base.std
ignore          = base.ignore
exclude_files   = base.exclude
max_line_length = false
codestyle       = false
allow_defined_top = base.allow_defined_top
stds.wow        = base.wow

-- base.globals (PeaversChangelogs, SlashCmdList) + this addon's SavedVariables.
-- PeaversCurrencyData itself is listed in the base as a *read-only* global, since that is
-- how consuming addons see it. This addon is the one that publishes it, so it needs the
-- name writable here — otherwise every table it builds trips W121/W122.
globals = base.globals
for _, g in ipairs({"PeaversCurrencyData", "PeaversCurrencyDataDB"}) do globals[#globals + 1] = g end
