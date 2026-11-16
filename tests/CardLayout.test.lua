-- Execute the real options builders. Mock framework factories, not the card
-- ordering or option bridge; rendered geometry remains a client check.
local file = assert(io.open("RGXQoL.lua"))
local source = file:read("*a"); file:close()
local columns, controls, panelOpts = {}, {}, nil
local function host() return { HookScript = function() end, GetWidth = function() return 600 end, SetHeight = function() end } end
local UI = {}
function UI:CreateCard(_, opts)
    return { title = opts.title, content = {}, flow = { Add = function() end }, AutoHeight = function() end }
end
function UI:CreateFlowLayout(column)
    return {
        Add = function(_, card) column.cards[#column.cards + 1] = card end,
        Apply = function() return 500 end,
    }
end
function UI:CreateColumns(_, count)
    assert(count == 2, "two columns")
    columns = { host(), host() }
    for _, column in ipairs(columns) do column.cards = {} end
    return unpack(columns)
end
function UI:CreateFlowLayout(parent)
    return {
        Add = function(_, child) parent.cards[#parent.cards + 1] = child end,
        Apply = function() return 100 end,
    }
end
function UI:CreateCard(_, opts)
    local card = { title = opts.title, content = {}, AutoHeight = function() end }
    card.flow = { Add = function() end }
    return card
end
function UI:CreateCheckbox(_, label, opts)
    controls[opts.key] = { label = label, opts = opts }
    return {}
end
function UI:CreateSlider() return {} end
function UI:CreateButton() return {} end
function UI:CreateOptionsPanel(opts)
    panelOpts = opts
    opts.tabs[1].content(host())
    return {}
end
local addon = {
    FeatureSetup = {}, ModuleOf = {}, AutoQuestEscort = "Off",
    Themed = function(_, fn) return fn() end,
    GetBrand = function() return {} end,
    GetAddonVersion = function() return "test" end,
    ActiveStyle = function() return "materialround" end,
    Print = function(_, message) error(message) end,
}
local env = setmetatable({
    RGXQoLLC = addon, RGXQoLDB = {}, RGXUI = UI,
    RGX = { After = function(_, _, fn) fn() end },
    L = setmetatable({}, { __index = function(_, key) return key end }),
}, { __index = _G })
env._G = env
local first = assert(source:find("local BridgeKeys = ", 1, true))
local chunk = assert(loadstring(source:sub(first), "@real-options-builders"))
setfenv(chunk, env); chunk()
addon:BuildOptionsCanvas()
assert(panelOpts and #columns == 2, "real options content built")
assert(#columns[1].cards == 3 and columns[1].cards[1].title == "Minimap"
    and columns[1].cards[2].title == "Chat" and columns[1].cards[3].title == "Vendors",
    "left column is Minimap, Chat, Vendors")
assert(#columns[2].cards == 2 and columns[2].cards[1].title == "Questing"
    and columns[2].cards[2].title == "Party and death", "right column stays unchanged")
local escort = assert(controls.autoQuestEscort, "escort tick box is present")
assert(escort.label == "Accept escort quests" and escort.opts.default == false, "explicit opt-in checkbox")
escort.opts.onChange(true)
assert(addon.AutoQuestEscort == "On", "checkbox invokes the real legacy option bridge")
escort.opts.onChange(false)
assert(addon.AutoQuestEscort == "Off", "checkbox can restore manual escorts")
print("CardLayout OK")
