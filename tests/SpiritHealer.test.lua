-- The spirit healer's resurrection prompt is accepted automatically when the option is on (and its Party and
-- death switch is on), not while shift is held, and never for other dialogs.
local function check(c, m) if not c then error("CHECK FAILED: " .. m, 2) end end
local f = assert(io.open("RGXQoL.lua")); local src = f:read("*a"); f:close()
local a = assert(src:find("local SPIRIT_HEALER_DIALOGS", 1, true))
local b = assert(src:find("\n\t\tend\n", a, true) or src:find("\r\n\t\tend\r\n", a, true))
local hook, clicked, said, shift, on = nil, nil, nil, false, true
local env = {
  SafeHookSecure = function(_, fn) hook = fn end,
  RGXQoLLC = { On = function(_, key) return key == "AutoSpiritRes" and on end },
  RGX = { After = function(_, _, fn) fn() end },
  StaticPopup_Visible = function(t) return t == "XP_LOSS" and "StaticPopup1" or nil end,
  StaticPopup_OnClick = function(dialog, i) clicked = { dialog, i } end,
  IsShiftKeyDown = function() return shift end,
  ActionStatus_DisplayMessage = function(m) said = m end,
  L = setmetatable({}, { __index = function(_, k) return k end }),
  _G = { StaticPopup1 = "dialog-frame" },
}
local chunk = assert(loadstring(src:sub(a, b)))
setfenv(chunk, setmetatable(env, { __index = _G }))
chunk()
check(type(hook) == "function", "the dialog hook is installed")
hook("XP_LOSS")
check(clicked and clicked[1] == "dialog-frame" and clicked[2] == 1, "the spirit healer prompt is accepted")
clicked = nil; hook("DEATH")
check(clicked == nil, "other dialogs are left alone")
shift = true; hook("XP_LOSS")
check(clicked == nil and said == "Spirit healer resurrection cancelled", "holding shift cancels it")
-- With resurrection sickness the prompt carries its duration and asks again after the first Accept.
local count = 0
env.StaticPopup_OnClick = function() count = count + 1 end
hook("XP_LOSS", nil, nil, 600)
check(count == 0 and said == "Spirit healer resurrection cancelled", "shift cancels the sickness prompt too")
shift = false; hook("XP_LOSS", nil, nil, 600)
check(count == 2, "the second confirmation is accepted too (" .. count .. ")")
count = 0; hook("XP_LOSS")
check(count == 1, "no second click without the sickness duration")
env.StaticPopup_OnClick = function(dialog, i) clicked = { dialog, i } end
shift, on = false, false; hook("XP_LOSS")
check(clicked == nil, "option off (or its card switched off): nothing happens")
local opts = src:find('Tick(party, L["Accept spirit healer resurrection"], "autoSpiritRes")', 1, true)
check(opts, "the option is a tick box in the Party and death card")
check(src:find('AutoSpiritRes = "ModuleParty"', 1, true), "the Party and death switch gates it")
io.write("SpiritHealer OK\n")
