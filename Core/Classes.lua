-- Core/Classes.lua — Class enum and lookup tables for all TBC classes.

local addonName, OW = ...

OW.CLASS = setmetatable({
    DRUID   = 1, HUNTER  = 2, MAGE    = 3,
    PALADIN = 4, PRIEST  = 5, ROGUE   = 6,
    SHAMAN  = 7, WARLOCK = 8, WARRIOR = 9,
}, {
    __index    = function(_, k) error("OW.CLASS: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.CLASS: is read-only", 2) end,
})

-- Wire-format class string (stored in entries) → CLASS enum value
OW.CLASS_ID = {
    Druid = OW.CLASS.DRUID, Hunter  = OW.CLASS.HUNTER, Mage    = OW.CLASS.MAGE,
    Paladin = OW.CLASS.PALADIN, Priest = OW.CLASS.PRIEST, Rogue = OW.CLASS.ROGUE,
    Shaman = OW.CLASS.SHAMAN, Warlock = OW.CLASS.WARLOCK, Warrior = OW.CLASS.WARRIOR,
}

-- WoW API uppercase token (from UnitClass) → display name
OW.CLASS_TOKEN_NAME = {
    DRUID = "Druid", HUNTER = "Hunter", MAGE = "Mage",
    PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue",
    SHAMAN = "Shaman", WARLOCK = "Warlock", WARRIOR = "Warrior",
}

-- CLASS enum value → display name (inverse of CLASS_ID)
OW.CLASS_NAME = {}
for cname, cid in pairs(OW.CLASS_ID) do OW.CLASS_NAME[cid] = cname end

-- Official WoW class colors { r, g, b }
OW.CLASS_COLOR = {
    Druid   = { 1.000, 0.490, 0.039 },
    Hunter  = { 0.671, 0.831, 0.451 },
    Mage    = { 0.412, 0.800, 0.941 },
    Paladin = { 0.961, 0.549, 0.729 },
    Priest  = { 1.000, 1.000, 1.000 },
    Rogue   = { 1.000, 0.961, 0.412 },
    Shaman  = { 0.000, 0.439, 0.871 },
    Warlock = { 0.580, 0.510, 0.788 },
    Warrior = { 0.780, 0.612, 0.431 },
}
