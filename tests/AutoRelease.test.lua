-- Auto release: in battlegrounds with "Release in PvP", in the open world with "Release in the open world",
-- never in dungeons or raids, never with a self-resurrection or a resurrection offered, never while shift is
-- held, and only once the release button is usable.
local function check(c, m) if not c then error("CHECK FAILED: " .. m, 2) end end
local f = assert(io.open("RGXQoL.lua")); local src = f:read("*a"); f:close()
local a = assert(src:find("local function ReleaseReady", 1, true))
local b = assert(src:find("\n\t\tend\n", a, true) or src:find("\r\n\t\tend\r\n", a, true))

local opts, instance, selfRes, offerer, shift, enabled, visible
local clicks, said, pending
local button = { IsEnabled = function() return enabled end }
local frame = { GetButton1 = function() return button end }
local function reset()
  opts = { AutoReleasePvP = true, AutoReleaseWorld = false }
  instance, selfRes, offerer, shift, enabled, visible = { false, "none" }, {}, nil, false, true, true
  clicks, said, pending = 0, nil, {}
end
local hook
local env = {
  SafeHookSecure = function(_, fn) hook = fn end,
  RGXQoLLC = setmetatable({ On = function(_, key) return opts[key] == true end }, { __index = function(_, k)
    if k == "AutoReleaseDelay" then return 200 end
    if k == "AutoReleaseNoAlterac" then return opts.NoAlterac and "On" or "Off" end
  end }),
  RGX = { After = function(_, _, fn) pending[#pending + 1] = fn end },
  C_DeathInfo = { GetSelfResurrectOptions = function() return selfRes end },
  C_Map = { GetBestMapForUnit = function() return 1459 end },
  ResurrectGetOfferer = function() return offerer end,
  IsInInstance = function() return instance[1], instance[2] end,
  StaticPopup_Visible = function(t) return t == "DEATH" and visible and "StaticPopup1" or nil end,
  StaticPopup_OnClick = function(dialog, i) if dialog == frame and i == 1 then clicks = clicks + 1 end end,
  IsShiftKeyDown = function() return shift end,
  ActionStatus_DisplayMessage = function(m) said = m end,
  L = setmetatable({}, { __index = function(_, k) return k end }),
  _G = { StaticPopup1 = frame },
}
local chunk = assert(loadstring(src:sub(a, b)))
setfenv(chunk, setmetatable(env, { __index = _G }))
chunk()
check(type(hook) == "function", "the death dialog hook is installed")

local function run()
  local n = 0
  while #pending > 0 and n < 100 do n = n + 1; table.remove(pending, 1)() end
end
local function die(where) instance = where; hook("DEATH"); run() end

reset(); die({ true, "pvp" })
check(clicks == 1, "released in a battleground with Release in PvP on")
reset(); opts.AutoReleasePvP = false; die({ true, "pvp" })
check(clicks == 0, "Release in PvP off: no release in a battleground")
reset(); opts.NoAlterac = true; die({ true, "pvp" })
check(clicks == 0, "Skip Alterac Valley keeps you there")
reset(); die({ false, "none" })
check(clicks == 0, "the open world needs its own option")
reset(); opts.AutoReleaseWorld = true; die({ false, "none" })
check(clicks == 1, "released in the open world with Release in the open world on")
reset(); opts.AutoReleaseWorld = true; die({ true, "party" })
check(clicks == 0, "never in a dungeon")
reset(); opts.AutoReleaseWorld = true; die({ true, "raid" })
check(clicks == 0, "never in a raid")
reset(); opts.AutoReleaseWorld = true; selfRes = { { name = "Soulstone" } }; die({ false, "none" })
check(clicks == 0, "a soulstone or other self-resurrection keeps you there")
reset(); opts.AutoReleaseWorld = true; offerer = "Priest"; die({ false, "none" })
check(clicks == 0, "a pending resurrection keeps you there")
reset(); opts.AutoReleaseWorld = true; shift = true; die({ false, "none" })
check(clicks == 0 and said == "Automatic Release Cancelled", "holding shift cancels it")
reset(); opts.AutoReleaseWorld = true; instance = { false, "none" }; hook("HARDCORE_DEATH"); run()
check(clicks == 0, "hardcore deaths are never touched")

-- Release button disabled (falling, no-release aura): wait, then release once it is usable.
reset(); opts.AutoReleaseWorld = true; enabled = false; instance = { false, "none" }; hook("DEATH")
for _ = 1, 3 do table.remove(pending, 1)() end
check(clicks == 0 and #pending == 1, "waits while the release button is disabled")
enabled = true; run()
check(clicks == 1, "releases once the button is usable")
reset(); opts.AutoReleaseWorld = true; enabled = false; instance = { false, "none" }; hook("DEATH"); run()
check(clicks == 0 and #pending == 0, "gives up after a while instead of retrying forever")

check(src:find('Tick(party, L["Release in the open world"], "autoReleaseWorld")', 1, true), "the option is a tick box in the Party and death card")
check(src:find('AutoReleaseWorld = "ModuleParty"', 1, true), "the Party and death switch gates it")
check(src:find('LoadVarChk("AutoReleaseWorld", "Off")', 1, true), "it is off unless chosen")
io.write("AutoRelease OK\n")
