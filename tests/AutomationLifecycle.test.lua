-- Real addon load/login/option/quest dispatch, using the framework's real event
-- and timer owners. UI geometry and client permissions are not emulated.
local frameworkPath = os.getenv("RGXFW_PATH") or "../RGX-Framework"
local function read(path)
    local file = assert(io.open(path))
    local text = file:read("*a")
    file:close()
    return text
end
local source = read("RGXQoL.lua")
local function check(value, message) assert(value, message) end
local function noop() end

local function boot(loadedName, saved)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local Frame = {}
    function Frame:SetScript(key, fn) self.scripts[key] = fn end
    function Frame:RegisterEvent(key) self.events[key] = true end
    function Frame:UnregisterEvent(key) self.events[key] = nil end
    function Frame:IsEventRegistered(key) return self.events[key] == true end
    function Frame:Show() self.shown = true end
    function Frame:Hide() self.shown = false end
    function Frame:IsShown() return self.shown == true end
    function Frame:SetChecked(value) self.checked = value end
    function Frame:GetChecked() return self.checked end
    local function frame()
        return setmetatable({ scripts = {}, events = {} }, {
            __index = function(_, key) return Frame[key] or noop end,
        })
    end
    Frame.CreateTexture, Frame.CreateFontString = frame, frame
    env.CreateFrame = frame
    env.WorldFrame, env.UIParent, env.MerchantFrame = frame(), frame(), frame()
    env.QuestFrameGreetingPanel = frame()
    env.SlashCmdList = {}
    env.GetBuildInfo = function() return "1.60.1", "70938", "", 16001 end
    env.GetLocale = function() return "enUS" end
    env.UnitClass = function() return "Warrior", "WARRIOR" end
    env.UnitGUID = function() return nil end
    env.UnitExists = function() return true end
    env.RAID_CLASS_COLORS = {}
    env.InCombatLockdown, env.IsAltKeyDown, env.IsControlKeyDown, env.IsMetaKeyDown =
        function() return false end, function() return false end, function() return false end, function() return false end
    local shift = false
    env.IsShiftKeyDown = function() return shift end
    env.GetTimePreciseSec = function() return 0 end
    env.UpdateAddOnMemoryUsage, env.hooksecurefunc, env.print = noop, noop, noop
    env.wipe = function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
    env.strsplit = function(delimiter, text)
        local parts, start = {}, 1
        while true do
            local index = text:find(delimiter, start, true)
            parts[#parts + 1] = text:sub(start, index and index - 1 or #text)
            if not index then return unpack(parts) end
            start = index + #delimiter
        end
    end
    local errors, accepted, selected, confirmed = {}, 0, nil, 0
    env.geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
    env.AcceptQuest = function() accepted = accepted + 1 end
    env.ConfirmAcceptQuest = function() confirmed = confirmed + 1 end
    env.StaticPopup_Hide = noop
    local available = {}
    env.C_AddOns = {
        IsAddOnLoaded = function() return false end,
        GetAddOnMetadata = function(name, field)
            if name == loadedName and field == "Version" then return "test-version" end
        end,
    }
    env.C_GossipInfo = {
        GetAvailableQuests = function() return available end,
        GetActiveQuests = function() return {} end,
        SelectAvailableQuest = function(id)
            selected = id
            env.RGXFramework:FireEvent("QUEST_DETAIL")
        end,
    }
    env.C_Item = { GetItemCount = function() return 0 end }
    local RGX = {
        eventFrame = frame(),
        API = { CanAccessValue = function() return true end, CanAccessTable = function() return true end },
        GetMinimap = function() return nil end,
        GetAuras = function() return {} end,
        GetDesign = function() return nil end,
        RegisterModule = noop,
    }
    env.RGXFramework = RGX
    local function load(text, path, ...)
        local chunk = assert(loadstring(text, "@" .. path))
        setfenv(chunk, env)
        return chunk(...)
    end
    load(read(frameworkPath .. "/core/systems/runtime.lua"), "runtime.lua", "RGX-Framework", RGX)
    load(read(frameworkPath .. "/core/systems/events.lua"), "events.lua", "RGX-Framework", RGX)
    env.RGXQoLDB = saved or { AutomateQuests = "On" }
    load(source, "RGXQoL.lua", loadedName, { L = setmetatable({}, { __index = function(_, key) return key end }) })
    local addon
    for i = 1, 30 do
        local name, value = debug.getupvalue(RGX.events.ADDON_LOADED.RGXQoL_AddonLoaded.callback, i)
        if not name then break end
        if name == "RGXQoLLC" then addon = value end
    end
    check(addon, "real lifecycle handler owns the addon")
    -- Options geometry is tested separately; retain the real state loading.
    addon.BuildOptionsCanvas = noop
    RGX:FireEvent("ADDON_LOADED", loadedName)
    RGX:FireEvent("PLAYER_LOGIN")
    local start = assert(source:find("local BridgeKeys = ", 1, true))
    local finish = assert(source:find("function RGXQoLLC:BuildOptionsCanvas()", start, true))
    local change = load("local RGXQoLLC = ...\n" .. source:sub(start, finish - 1)
        .. "\nreturn OnBridgeChange", "real-option-bridge", addon)
    return {
        addon = addon, env = env, errors = errors, change = change,
        fire = function(event, ...) RGX:FireEvent(event, ...) end,
        accepted = function() return accepted end,
        confirmed = function() return confirmed end,
        selected = function() return selected end,
        quests = function(value) available = value end,
        shift = function(value) shift = value end,
        load = load,
    }
end

local passed = 0
local function scenario(name, fn)
    fn()
    passed = passed + 1
    print("PASS " .. name)
end
for _, loadedName in ipairs({ "RGXQoL", "RGXAQoL" }) do
    scenario("saved quest automation initializes for loaded addon " .. loadedName, function()
        local test = boot(loadedName)
        check(#test.errors == 0, table.concat(test.errors, "\n"))
        check(test.addon.AutomateQuests == "On" and test.addon.AutoQuestAvailable == "On",
            "matching ADDON_LOADED must initialize settings before feature setup")
        test.fire("QUEST_DETAIL")
        check(test.accepted() == 1, "enabled detail must be accepted")
        test.fire("QUEST_ACCEPT_CONFIRM")
        check(test.confirmed() == 1, "shared quest confirmation must still run")
        check(test.addon:GetAddonVersion() == "test-version", "metadata follows the loaded addon name")
    end)
end
scenario("option bridge enables, disables and saves real quest registrations", function()
    local test = boot("RGXQoL", { AutomateQuests = "Off" })
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 0, "master off must not accept")
    test.change("automateQuests", true)
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "master on installs quest handlers")
    test.shift(true)
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "override key suppresses acceptance")
    test.shift(false)
    test.change("autoQuestAvailable", false)
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "accept option off suppresses acceptance")
    test.change("autoQuestAvailable", true)
    test.change("automateQuests", false)
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "master off removes quest handlers")
    test.fire("PLAYER_LOGOUT")
    check(test.env.RGXQoLDB.AutomateQuests == "Off", "option state survives the real save path")
    check(#test.errors == 0, table.concat(test.errors, "\n"))
end)
scenario("gossip selection reaches quest detail and uses quest titles for requirements", function()
    local test = boot("RGXQoL")
    test.quests({ { questID = 1, title = "A Donation of Wool" }, { questID = 2, title = "Ordinary quest" } })
    test.fire("GOSSIP_SHOW")
    check(test.selected() == 2 and test.accepted() == 1,
        "skip unaffordable repeatable turn-ins, then select and accept the available quest")
    check(#test.errors == 0, table.concat(test.errors, "\n"))
end)
scenario("escort acceptance is opt-in and preserves other quest guards", function()
    local test = boot("RGXQoL")
    test.env.UnitGUID = function() return "Creature-0-0-0-0-467-0" end
    check(test.addon.AutoQuestEscort == "Off", "existing saves default to manual escorts")
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 0, "escort remains manual by default")
    test.change("autoQuestEscort", true)
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "escort opt-in accepts without reload")
    test.shift(true); test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "override still pauses escorts")
    test.shift(false); test.change("autoQuestAvailable", false); test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "escort opt-in does not override accept toggle")
    test.change("autoQuestAvailable", true)
    test.change("automateQuests", false); test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "escort opt-in does not override master toggle")
    test.change("automateQuests", true)
    test.env.UnitGUID = function() return "Creature-0-0-0-0-15192-0" end
    test.fire("QUEST_DETAIL")
    check(test.accepted() == 1, "consequential non-escort NPC exclusion stays intact")
    test.fire("PLAYER_LOGOUT")
    check(test.env.RGXQoLDB.AutoQuestEscort == "On", "escort preference is saved")
    local reload = boot("RGXQoL", test.env.RGXQoLDB)
    reload.env.UnitGUID = function() return "Creature-0-0-0-0-467-0" end
    reload.fire("QUEST_DETAIL")
    check(reload.accepted() == 1, "saved escort opt-in survives reload")
    reload.change("autoQuestEscort", false); reload.fire("QUEST_DETAIL")
    check(reload.accepted() == 1, "disabling immediately restores manual escorts")
    check(#test.errors == 0 and #reload.errors == 0, "escort paths report no callback errors")
end)
scenario("real checkbox changes survive a fresh load without a logout callback", function()
    local test = boot("RGXQoL")
    local UI = {}
    test.load(read(frameworkPath .. "/libraries/ui/controls.lua"), "real-controls.lua", "RGX-Framework", UI)
    local storage = {}
    local row = UI:CreateCheckbox(test.env.UIParent, "Accept escort quests", {
        storage = storage, key = "autoQuestEscort", default = false,
        onChange = function(value) test.change("autoQuestEscort", value) end,
    })
    row.checkbox:SetChecked(true)
    row.checkbox.scripts.OnClick(row.checkbox)
    check(storage.autoQuestEscort == true and test.addon.AutoQuestEscort == "On", "real framework checkbox reaches runtime")
    check(test.env.RGXQoLDB.AutoQuestEscort == "On", "changes go directly to SavedVariables, not only to a logout-time mirror")
    test.change("moduleParty", false)
    test.change("autoReleaseDelay", 1750)
    test.change("autoQuestKeyMenu", 3)
    local saved = {}
    for key, value in pairs(test.env.RGXQoLDB) do saved[key] = value end
    local reload = boot("RGXQoL", saved)
    check(reload.addon.AutoQuestEscort == "On" and reload.addon.ModuleParty == "Off"
        and reload.addon.AutoReleaseDelay == 1750 and reload.addon.AutoQuestKeyMenu == 3,
        "checkbox, module, slider and key selection survive a new load without PLAYER_LOGOUT")
    check(#test.errors == 0 and #reload.errors == 0, "reload has no callback errors")
end)
print("AutomationLifecycle OK " .. passed .. " scenarios")
