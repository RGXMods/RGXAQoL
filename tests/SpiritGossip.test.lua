-- The spirit-healer option owns BOTH gossip selection and confirmation.
-- Run real feature code; do not invent a gossip option type field.
local function check(value, message) assert(value, message) end
local file = assert(io.open("RGXQoL.lua"))
local source = file:read("*a")
file:close()
local first = assert(source:find("-- Accept spirit healer resurrection", 1, true))
local last = assert(source:find("--\tMinimap button", first, true))
local code = source:sub(first, last - 1)
local enabled, module, shift, ghost, npc = true, true, false, true, "Spirit Healer"
local options = { { orderIndex = 1, name = "Return me to life" } }
local selected, clicked, pending, hook = nil, 0, {}, nil
local handlers = {}
local addon = {
    FeatureSetup = {},
    On = function(_, key) return key == "AutoSpiritRes" and enabled and module end,
}
local env = {
    RGXQoLLC = addon,
    RGX = {
        API = { GetGossipOptions = function() return options end },
        RegisterEvent = function(_, event, callback, id) handlers[id] = { event, callback } end,
        UnregisterEvent = function(_, _, id) handlers[id] = nil end,
        After = function(_, _, callback) pending[#pending + 1] = callback end,
    },
    UnitIsGhost = function(unit) check(unit == "player"); return ghost end,
    UnitName = function(unit) check(unit == "npc"); return npc end,
    IsShiftKeyDown = function() return shift end,
    SPIRIT_HEALER_RELEASE_RED = "|cffff2020Spirit Healer|r",
    C_GossipInfo = {
        SelectOptionByIndex = function(index) selected = { "index", index } end,
        SelectOption = function(id) selected = { "id", id } end,
    },
    SafeHookSecure = function(_, callback) hook = callback end,
    StaticPopup_Visible = function() return "StaticPopup1" end,
    StaticPopup_OnClick = function() clicked = clicked + 1 end,
    ActionStatus_DisplayMessage = function() end,
    L = setmetatable({}, { __index = function(_, key) return key end }),
    _G = { StaticPopup1 = {} },
}
local chunk = assert(loadstring(code))
setfenv(chunk, setmetatable(env, { __index = _G }))
chunk()
local entry = handlers.RGXQoL_SpiritHealer
check(entry and entry[1] == "GOSSIP_SHOW", "the spirit-healer feature must register the first gossip stage")
local function gossip()
    selected = nil
    if handlers.RGXQoL_SpiritHealer then handlers.RGXQoL_SpiritHealer[2]("GOSSIP_SHOW") end
end
gossip()
check(selected and selected[1] == "index" and selected[2] == 1,
    "Forever orderIndex works without a gossipOptionID")
hook("XP_LOSS")
check(clicked == 0 and #pending == 1, "confirmation stays deferred")
table.remove(pending, 1)()
check(clicked == 1, "the same feature completes the confirmation")

shift = true; gossip(); check(selected == nil, "Shift cancels the first stage")
shift = false; ghost = false; gossip(); check(selected == nil, "living players are never selected")
ghost = true; npc = "Unrelated NPC"; gossip(); check(selected == nil, "unrelated ghost gossip is not selected")
npc = "Spirit Healer"; options = { { orderIndex = 1 }, { orderIndex = 2 } }
gossip(); check(selected == nil, "ambiguous multiple choices remain manual")
options = {}; gossip(); check(selected == nil, "empty menus remain untouched")
options = { { name = "Return me to life" } }; gossip()
check(selected == nil, "a localized-looking label is not a substitute for a selection identifier")
options = { { orderIndex = 1, name = "Rendez-moi la vie" } }
env.SPIRIT_HEALER_RELEASE_RED = "|cffff2020Gardien des âmes|r"
npc = "Gardien des âmes"; gossip()
check(selected and selected[2] == 1, "NPC identity uses the client-localized healer name, not English option text")

module = false
addon.FeatureSetup.AutoSpiritRes()
check(handlers.RGXQoL_SpiritHealer == nil, "module off unregisters the gossip stage")
module = true; enabled = false
addon.FeatureSetup.AutoSpiritRes()
check(handlers.RGXQoL_SpiritHealer == nil, "option off does not require the separate gossip/quest settings")
enabled = true; addon.FeatureSetup.AutoSpiritRes()
check(handlers.RGXQoL_SpiritHealer, "enabling reinstalls the gossip stage")
hook("XP_LOSS"); enabled = false
table.remove(pending, 1)()
check(clicked == 1, "disabling after scheduling cancels confirmation too")
print("SpiritGossip OK")
