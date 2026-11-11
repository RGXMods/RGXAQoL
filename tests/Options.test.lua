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

-- 3. Layout: one page of four cards in two framework columns; the General card is the framework's standard card.
local _, tabs = src:gsub("content = function%(frame%)", "")
check(tabs == 1 and src:find("tabs = { { text = L[\"Settings\"], content = function(frame)", 1, true) and not src:find("\n\t\t\tcontent = function(frame)", 1, true), "the page is a one-tab panel, not the tab-less content form (" .. tabs .. ")")
check(src:find("Grid(frame, {", 1, true) and src:find("UI:CreateColumns(canvas, #builders)", 1, true), "the page is a two-column card grid")
check(not src:find('text = L["Utilities"]', 1, true) and not src:find('text = L["Automation"]', 1, true), "no Utilities or Automation tab")
check(src:find("UI:CreateStandardCard(host", 1, true) and src:find("if UI.CreateStandardCard then", 1, true), "the General card is the framework's standard card, with a local fallback for an older framework")
local cards = select(2, src:gsub("= Card%(host, ", ""))
check(cards == 4, "Vendors, Questing, Party and death and the fallback General are built here (" .. cards .. ")")
check(src:find("GeneralCard(host)", 1, true), "the General card is the fourth card on the page")
check(src:find("KeyChoice, questing", 1, true) and not src:find("CreateNestedDropdown", 1, true) and not src:find('Slider(questing', 1, true), "the override key is one compact button, not a dropdown or slider")
check(src:find("RGX.CreateChat and RGX:CreateChat", 1, true) and src:find("self.chat:Print", 1, true), "chat goes through RGX:CreateChat")

-- 4. Removed settings and the icon.
check(not src:find("UseEnglishLanguage", 1, true) or src:find("RGXQoLDB.UseEnglishLanguage = nil", 1, true), "the English-language setting is gone")
local _, n = src:gsub("UseEnglishLanguage", "")
check(n == 1, "UseEnglishLanguage appears once, only to clear old saves (" .. n .. ")")
check(not src:find("ReloadButton", 1, true) and not src:find("ReloadCheck", 1, true), "no reload button")
check(not read("RGXQoL_Locale.lua"):find("UseEnglishLanguage", 1, true), "the locale file ignores no language override")
local toc = read("RGXQoL.toc")
check(toc:find("IconTexture: Interface\\AddOns\\RGX-Framework\\media\\logo.tga", 1, true), "the TOC uses the RGX-Framework icon")
check(src:find("RGX-Framework\\\\media\\\\round.tga", 1, true) and src:find("RGX-Framework\\\\media\\\\square.tga", 1, true), "minimap and chat use round.tga, the panel uses square.tga")
check(io.open("media/icon.tga") == nil and io.open("RGXQoL.blp") == nil, "AQoL ships no icon file of its own")
check(toc:find("X-RGX-Framework-MinVersion: 2.17.4", 1, true), "the TOC requires the framework that has the standard card")

-- 5. Card headers carry no subtext, the chat prefix is not an option, and General comes first.
check(not src:find("Text(vendors", 1, true) and not src:find("Text(party", 1, true) and not src:find("gossip and the override key", 1, true), "no description line under a card header")
check(src:find("description = false", 1, true) and src:find("prefix = false", 1, true), "the standard card omits its description line and chat prefix box")
check(src:find('label = "AQoL"', 1, true), "chat uses the [AQoL] label")
local chatBlock = src:sub(src:find("RGXQoLLC.chat = RGX.CreateChat", 1, true), src:find("function RGXQoLLC:Print", 1, true))
check(not chatBlock:find("brand", 1, true), "no custom brand string for chat")
check(src:find("addonMenu = false", 1, true), "the Addons menu entry is not an option")
check(src:find("local function FallbackChat", 1, true) and src:find("RGX:CreateChatPrefix", 1, true), "chat keeps the icon and [AQoL] prefix on an older framework")
check(not src:find("loginMessage = false", 1, true) and src:find('login = L["Show welcome message"]', 1, true) and src:find('chat = L["Show chat messages"]', 1, true), "Show welcome message and Show chat messages are options")
check(not src:find("FirstRunMessageSeen", 1, true) and src:find("RGXQoLLC.chat:Login(", 1, true), "the welcome message prints on every login, not only the first run")
check(not src:find("compartment = RGXQoLDB", 1, true), "the Addons menu entry is always on")
check(src:find('author = "DonnieDice"', 1, true) and src:find("cffffd700Mods", 1, true), "the panel header says RGX Mods by DonnieDice")
check(src:find('local function Safe(name, fn, ...)', 1, true) and src:find('Safe("General card", GeneralCard, host)', 1, true) and src:find('Safe("override key", KeyChoice', 1, true), "a card that fails to build is reported and skipped")
check(src:find("Loaded successfully. Type |cfffff569/qol help|r for commands.", 1, true) and src:find("|cffffff00Version:|r", 1, true), "the login message is the two-line RGX format with a version line")
check(src:find('CHAT_COLOR = "8B1538"', 1, true) and src:find("tagColor = CHAT_COLOR", 1, true), "the chat prefix uses the primary brand colour")
check(src:find('RGX:After(delay, reflow)', 1, true) and src:find('str == "panel"', 1, true), "the page re-lays out after build and /qol panel reports its state")
check(src:find("panel.tabs[1]:Hide()", 1, true), "the lone tab button is hidden")
check(src:find("hideTabRow = true", 1, true), "the lone tab row is hidden so the page starts under the header")
print("Options.test OK")
