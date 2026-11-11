-- AQoL options: the panel opens from the minimap button and /qol, the brand is the RGX pair, and the
-- panel is two tabs of two-column card grids. Run from the repository root: luajit tests/Options.test.lua
local function check(c, m) if not c then error("CHECK FAILED: " .. m, 2) end end
local function read(p) local f = assert(io.open(p)); local s = f:read("*a"); f:close(); return s end
local src = read("RGXQoL.lua")

-- 1. The open-panel bug: a `local` declared below its first use is invisible above it, so the minimap
--    click and /qol silently did nothing. Opening is now a method resolved at call time.
check(not src:find("OpenOptionsShared", 1, true), "no bare OpenOptionsShared variable is left")
check(src:find("function RGXQoLLC:OpenOptions()", 1, true), "OpenOptions is a method on the addon table")
check(src:find("onLeftClick = function() RGXQoLLC:OpenOptions() end", 1, true), "minimap left click opens the options")
local slash = src:sub(src:find("function RGXQoLLC:SlashFunc", 1, true), src:find("Slash commands owned by the framework", 1, true))
check(slash:find("RGXQoLLC:OpenOptions()", 1, true), "/qol with no arguments opens the options")

-- Behaviour of OpenOptions: builds the panel once, then opens it.
local a = assert(src:find("function RGXQoLLC:OpenOptions()", 1, true))
local b = assert(src:find("\n\tend\n", a, true))
local built, opened = 0, 0
local RGXQoLLC = { BuildOptionsCanvas = function(self) built = built + 1; self.QoLPanel = { Open = function() opened = opened + 1 end } end }
assert(loadstring("local RGXQoLLC = ...\n" .. src:sub(a, b + 5) .. "\nreturn RGXQoLLC", "OpenOptions"))(RGXQoLLC)
RGXQoLLC:OpenOptions(); RGXQoLLC:OpenOptions()
check(built == 1 and opened == 2, "the panel is built once and opened every time (built " .. built .. ", opened " .. opened .. ")")

-- 2. RGX brand: red primary, light grey accent (not pink), Material Round, a correctly escaped title.
check(src:find("primary = { 0.545, 0.082, 0.220 }", 1, true), "primary is RGX red")
check(src:find("accent = { 0.741, 0.765, 0.780 }", 1, true), "accent is the RGX light grey")
check(not src:find("0.929, 0.420, 0.522", 1, true), "the pink accent is gone")
check(src:find('BRAND_STYLE = "materialround"', 1, true), "the panel uses the Material Round style")
check(src:find('"|cff8B1538RGX|r |cffffffff|||r |cffffffffAQoL|r"', 1, true), "the title escapes its pipe (|||r)")
check(not src:find("QoL Plus", 1, true), "no leftover QoL Plus branding")

-- 3. Layout (RGX standard, as RGX Professions): two tabs, General then Automation, each a single column of
--    full-width cards stacked in the page flow; the General tab is the framework's standard card.
local _, tabs = src:gsub("content = function%(frame%)", "")
check(tabs == 2, "the panel has two tabs (" .. tabs .. ")")
check(src:find('text = L["General"]', 1, true) < src:find('text = L["Automation"]', 1, true), "General is the first tab")
check(not src:find('text = L["Utilities"]', 1, true), "no Utilities tab")
check(not src:find("Grid(", 1, true) and not src:find("CreateColumns", 1, true) and not src:find("maxPerRow", 1, true), "no custom column grid")
check(src:find("frame._rgxFlow:Add(card)", 1, true), "cards stack in the page flow")
check(src:find("UI:CreateStandardCard(frame", 1, true), "the General tab uses the framework's standard options card")
check(src:find("RGX:CreateChat", 1, true) and src:find("self.chat:Print", 1, true), "chat goes through RGX:CreateChat")

-- 4. Removed settings and the icon.
check(not src:find("UseEnglishLanguage", 1, true) or src:find("RGXQoLDB.UseEnglishLanguage = nil", 1, true), "the English-language setting is gone")
local _, n = src:gsub("UseEnglishLanguage", "")
check(n == 1, "UseEnglishLanguage appears once, only to clear old saves (" .. n .. ")")
check(not src:find("ReloadButton", 1, true) and not src:find("ReloadCheck", 1, true), "no reload button")
check(not read("RGXQoL_Locale.lua"):find("UseEnglishLanguage", 1, true), "the locale file ignores no language override")
local toc = read("RGXQoL.toc")
check(toc:find("IconTexture: Interface\\AddOns\\RGXQoL\\media\\icon.tga", 1, true), "the TOC points at the addon's own icon")
check(io.open("media/icon.tga") ~= nil, "media/icon.tga ships")
check(io.open("RGXQoL.blp") == nil, "the unused sprite sheet is gone")
check(not src:find("RGX-Framework\\\\media\\\\logo.tga", 1, true), "no framework logo used as the addon icon")
check(toc:find("X-RGX-Framework-MinVersion: 2.17.2", 1, true), "the TOC requires the framework that has the standard card")

-- 5. Card headers carry no subtext, the chat prefix is not an option, and General comes first.
check(not src:find("Text(vendors", 1, true) and not src:find("Text(party", 1, true) and not src:find("gossip and the override key", 1, true), "no description line under a card header")
check(src:find("description = false", 1, true) and src:find("prefix = false", 1, true), "the standard card omits its description line and chat prefix box")
check(src:find('label = "AQoL"', 1, true) and src:find("media\\\\icon.tga", 1, true), "chat uses the [AQoL] label with the AQoL icon")
check(not src:find("brand = ", 1, true), "no custom brand string for chat")
print("Options.test OK")
