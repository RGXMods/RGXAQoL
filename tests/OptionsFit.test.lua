-- Real framework flow/card sizing with conservative row heights. This checks
-- a single-page height budget, not client font rendering or pixel fidelity.
local function read(path)
    local f = assert(io.open(path)); local text = f:read("*a"); f:close(); return text
end
local fw = os.getenv("RGXFW_PATH") or "../RGX-Framework"
local Widget = {}
function Widget:GetWidth() return self.width or 320 end
function Widget:GetHeight() return self.height or 20 end
function Widget:SetHeight(v) self.height = v end
function Widget:SetWidth(v) self.width = v end
function Widget:SetSize(w, h) self.width, self.height = w, h end
function Widget:SetPoint() end
function Widget:ClearAllPoints() end
function Widget:HookScript() end
function Widget:SetFrameLevel() end
function Widget:GetFrameLevel() return 1 end
function Widget:SetAllPoints() end
function Widget:EnableMouse() end
function Widget:SetAlpha() end
function Widget:Show() end
function Widget:Hide() end
function Widget:SetText() end
local function widget() return setmetatable({}, { __index = Widget }) end
local UI, columns = {}, {}
local addon = {
    FeatureSetup = {}, ModuleOf = {},
    Themed = function(_, fn) return fn() end,
    GetBrand = function() return {} end,
    GetAddonVersion = function() return "test" end,
    ActiveStyle = function() return "materialround" end,
    Print = function(_, msg) error(msg) end,
}
local env = setmetatable({
    RGXQoLLC = addon, RGXQoLDB = {}, RGXUI = UI, CreateFrame = widget,
    L = setmetatable({}, { __index = function(_, k) return k end }),
    RGX = { After = function(_, _, fn) fn() end },
    RGXFramework = {},
}, { __index = _G })
env._G = env
local function load(text)
    local chunk = assert(loadstring(text)); setfenv(chunk, env); return chunk
end
load(read(fw .. "/libraries/ui/layout.lua"))("RGX-Framework", UI)
function UI:CreateSection(parent, opts)
    local card = widget()
    card.title, card.headerBand, card.content = opts.title, widget(), widget()
    parent.cards[#parent.cards + 1] = card
    return card
end
function UI:CreateColumns(_, count)
    assert(count == 2)
    columns = { widget(), widget() }
    for _, column in ipairs(columns) do column.cards = {} end
    return unpack(columns)
end
function UI:CreateSwitch() return widget() end
function UI:CreateCheckbox() local w = widget(); w:SetHeight(28); return w end
function UI:CreateSlider() local w = widget(); w:SetHeight(38); return w end
function UI:CreateButton() local w = widget(); w:SetHeight(22); return w end
local extent
function UI:CreateOptionsPanel(opts)
    assert(#opts.tabs == 1 and opts.hideTabRow, "one page, no extra tabs")
    local page = widget()
    function page:SetContentHeight(height) extent = height end
    opts.tabs[1].content(page)
    return {}
end
local source = read("RGXQoL.lua")
local first = assert(source:find("local BridgeKeys = ", 1, true))
load(source:sub(first))()
addon:BuildOptionsCanvas()
local heights = {}
for i, column in ipairs(columns) do
    heights[i] = 0
    for _, card in ipairs(column.cards) do heights[i] = heights[i] + card:GetHeight() + 8 end
    heights[i] = heights[i] - 8
end
assert(extent and extent == math.max(unpack(heights)), "declares the actual tallest column via the framework helper")
assert(heights[1] <= 550 and heights[2] <= 550, "both columns fit the screenshot-sized content budget")
assert(math.abs(heights[1] - heights[2]) <= 80, "columns are balanced instead of stacking both long cards together")
print("OptionsFit OK: left " .. heights[1] .. "px, right " .. heights[2] .. "px")
