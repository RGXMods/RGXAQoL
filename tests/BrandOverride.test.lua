-- The brand pair follows the framework's beta theme override: the own pair (and Material Round) while it is
-- off, the framework's main colour and chosen style while it is on. References held by windows follow too.
local function check(c, m) if not c then error("CHECK FAILED: " .. m, 2) end end
local f = assert(io.open("RGXQoL.lua")); local src = f:read("*a"); f:close()
local a = assert(src:find("\tRGXQoLLC.OwnBrand = ", 1, true))
local b = assert(src:find("\t-- The interface style:", a, true))
local RGXQoLLC = {}
assert(loadstring("local RGXQoLLC = ...\n" .. src:sub(a, b - 1), "brand"))(RGXQoLLC)

local GOLD, PURPLE = { 1, 0.843, 0 }, { 0.737, 0.435, 0.659 }
local override = false
local listener
_G.RGXDesign = { RegisterBrand = function(_, id, own, style)
    return { id = id, OnChange = function(_, fn) listener = fn end, Build = function(_, fn) return fn() end,
        Resolve = function()
            if override then return { primary = GOLD, accent = PURPLE }, "forever" end
            return { primary = own.primary, accent = own.accent }, style
        end }
end }
local ring = RGXQoLLC.Brand.primary
check(RGXQoLLC:RefreshBrand() == "materialround" and ring[1] == 0.545, "override off: own pair, Material Round")
check(RGXQoLLC.BrandTitle:find("|cff8B1538RGX|r", 1, true) == 1, "override off: the title keeps the RGX red")
override = true
check(RGXQoLLC:RefreshBrand() == "forever", "override on: the chosen style")
check(ring[1] == GOLD[1] and RGXQoLLC.Brand.accent[1] == PURPLE[1], "override on: held references follow the framework colour")
check(RGXQoLLC.BrandTitle:find("|cffFFD700RGX|r", 1, true) == 1, "override on: the title follows (" .. RGXQoLLC.BrandTitle .. ")")
check(RGXQoLLC.BrandTitle:find("|||r", 1, true), "the pipe stays escaped")
override = false
RGXQoLLC:RefreshBrand()
check(ring[1] == 0.545 and RGXQoLLC.BrandTitle:find("|cff8B1538RGX|r", 1, true) == 1, "override off again: back to the own pair")
check(type(listener) == "function", "the brand listens for theme changes (the options panel redraws itself)")
override = true
listener()
check(RGXQoLLC.BrandTitle:find("|cffFFD700RGX|r", 1, true) == 1, "a theme change re-colours the title live")
local f2 = assert(io.open("RGXQoL.lua")); local full = f2:read("*a"); f2:close()
check(full:find("brand = RGXQoLLC:GetBrand(),", 1, true), "the options panel is built with the brand")
io.write("BrandOverride OK\n")
