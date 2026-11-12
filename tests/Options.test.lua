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
-- Five module cards: Chat, Vendors, Minimap, Questing, Party and death. Each has a switch in its header
-- (the whole card on or off); the options inside are tick boxes, never switches.
check(src:find("local function ModuleCard(host, title, bkey)", 1, true), "module cards share one builder")
check(src:find("UI:CreateCard(host, { title = L[\"Chat\"], switch", 1, true) and src:find('ModuleCard(host, L["Vendors"], "moduleVendors")', 1, true) and src:find('ModuleCard(host, L["Questing"], "automateQuests")', 1, true) and src:find('ModuleCard(host, L["Party and death"], "moduleParty")', 1, true) and src:find('title = L["Minimap"], switch', 1, true), "Chat, Vendors, Minimap, Questing and Party and death each have a header switch")
check(not src:find("UI:CreateSwitch(card.content", 1, true) and not src:find("local function Toggle(card", 1, true), "no switches inside cards: options are tick boxes")
local ticks = select(2, src:gsub("\n%s+Tick%(", "\n")) + select(2, src:gsub("\n%s+DbTick%(", "\n"))
check(ticks == 14, "14 tick boxes across the cards (" .. ticks .. ")")
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
check(toc:find("X-RGX-Framework-MinVersion: 2.18.0", 1, true), "the TOC requires the framework that has card header switches and bound tick boxes")

-- 5. Card headers carry no subtext, the chat prefix is not an option, and General comes first.
check(not src:find("Text(vendors", 1, true) and not src:find("Text(party", 1, true) and not src:find("gossip and the override key", 1, true), "no description line under a card header")
check(not src:find("UI:CreateStandardCard(host", 1, true), "no chat prefix box: the standard card is not used")
check(src:find('label = "AQoL"', 1, true), "chat uses the [AQoL] label")
local chatBlock = src:sub(src:find("RGXQoLLC.chat = RGX.CreateChat", 1, true), src:find("function RGXQoLLC:Print", 1, true))
check(not chatBlock:find("brand", 1, true), "no custom brand string for chat")
check(not src:find('L["List in the Addons menu"]', 1, true), "the Addons menu entry is not an option")
check(src:find("local function FallbackChat", 1, true) and src:find("RGX:CreateChatPrefix", 1, true), "chat keeps the icon and [AQoL] prefix on an older framework")
check(not src:find("loginMessage = false", 1, true) and src:find('L["Show welcome message"], "loginMessage"', 1, true) and src:find('key = "chatOutput"', 1, true), "the Chat card switch is chat output and Show welcome message is a tick")
check(not src:find("FirstRunMessageSeen", 1, true) and src:find("RGXQoLLC.chat:Login(", 1, true), "the welcome message prints on every login, not only the first run")
check(not src:find("compartment = RGXQoLDB", 1, true), "the Addons menu entry is always on")
check(src:find('author = "DonnieDice"', 1, true) and src:find("cffffd700Mods", 1, true), "the panel header says RGX Mods by DonnieDice")
check(src:find('local function Safe(name, fn, ...)', 1, true) and src:find('Safe("override key", KeyChoice', 1, true) and src:find('Safe("column " .. i, build, hosts[i])', 1, true), "a column or key button that fails to build is reported and skipped")
check(src:find("Loaded successfully. Type |cfffff569/qol help|r for commands.", 1, true) and src:find("|cffffff00Version:|r", 1, true), "the login message is the two-line RGX format with a version line")
check(src:find('CHAT_COLOR = "8B1538"', 1, true) and src:find("tagColor = CHAT_COLOR", 1, true), "the chat prefix uses the primary brand colour")
check(src:find('RGX:After(delay, reflow)', 1, true) and src:find('str == "panel"', 1, true), "the page re-lays out after build and /qol panel reports its state")
check(src:find("panel.tabs[1]:Hide()", 1, true), "the lone tab button is hidden")
check(src:find("hideTabRow = true", 1, true), "the lone tab row is hidden so the page starts under the header")
-- 6. Automation compatibility on RGX Forever.
check(src:find("local function QuestIsComplete(questID)", 1, true) and src:find("C_QuestLog.IsComplete", 1, true), "gossip quests use a C_QuestLog.IsComplete shim")
check(not src:find("and IsQuestComplete(questInfo.questID)", 1, true), "no bare IsQuestComplete call in the gossip loop")
check(not src:find("GetQuestLogIndexByID(arg1)\n\t\t\t\t\t\tif GetQuestLogIsAutoComplete(index)", 1, true), "quest autocomplete does not call missing quest-log functions unguarded")
local sliderStart = src:find("local function Slider(card, label, bkey, min, max, suffix)", 1, true)
local sliderBody = src:sub(sliderStart, src:find("\n\t\tend\n", sliderStart, true))
check(sliderBody:find("onChange = function(value) OnBridgeChange(bkey, value) end", 1, true), "sliders push their value to the automation's legacy option")
check(src:find("style = RGXQoLLC.BRAND_STYLE", 1, true), "the panel passes its interface style so lazily built tab content keeps it")
print("Options.test OK")

-- 7. Module switches gate the automation, and a forward-declared local cannot be nil in a handler.
check(src:find("function RGXQoLLC:On(key)", 1, true) and src:find('RGXQoLLC:On("AutoSellJunk")', 1, true) and src:find('RGXQoLLC:On("AutoAcceptSummon")', 1, true) and src:find('RGXQoLLC:On("AutomateGossip")', 1, true), "features run only when their module switch is on")
local gossip = assert(src:find("local function OnGossipShow(event)", 1, true))
local tableAt = assert(src:find("local npcTable = {", 1, true))
check(tableAt < gossip, "npcTable is declared before the gossip handler that reads it (tContains got a nil table)")
print("Options.test OK")
