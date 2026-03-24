-- Data/Activities.lua — Activity definitions for TBC Classic Anniversary.
-- Defines: OW.ACTIVITY enum, OW.ACTIVITY_LIST, OW.ACTIVITY_SUBS.
-- No WoW API dependencies — pure Lua tables only.

local addonName, OW = ...

-- ---------------------------------------------------------------------------
-- Activity enum
-- ---------------------------------------------------------------------------

OW.ACTIVITY = setmetatable({
    NORMAL_DUNGEON  = 1,
    HEROIC_DUNGEON  = 2,
    RAID            = 3,
    PVP             = 4,
    QUEST           = 5,
    FARM            = 6,
    CHILL           = 7,
}, {
    __index    = function(_, k) error("OW.ACTIVITY: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.ACTIVITY: is read-only", 2) end,
})

-- ---------------------------------------------------------------------------
-- Ordered activity list (display order per D-01)
-- ---------------------------------------------------------------------------

OW.ACTIVITY_LIST = {
    { id = OW.ACTIVITY.NORMAL_DUNGEON, label = "Normal Dungeon" },
    { id = OW.ACTIVITY.HEROIC_DUNGEON, label = "Heroic Dungeon" },
    { id = OW.ACTIVITY.RAID,           label = "Raid"           },
    { id = OW.ACTIVITY.PVP,            label = "PVP"            },
    { id = OW.ACTIVITY.QUEST,          label = "Quest"          },
    { id = OW.ACTIVITY.FARM,           label = "Farm"           },
    { id = OW.ACTIVITY.CHILL,          label = "Chill"          },
}

-- ---------------------------------------------------------------------------
-- Sub-type lists per activity (keyed by label string)
-- ---------------------------------------------------------------------------

OW.ACTIVITY_SUBS = {
    ["Normal Dungeon"] = {
        -- Hellfire Citadel
        "Hellfire Ramparts",
        "The Blood Furnace",
        "The Shattered Halls",
        -- Coilfang Reservoir
        "The Slave Pens",
        "The Underbog",
        "The Steamvault",
        -- Auchindoun
        "Mana-Tombs",
        "Auchenai Crypts",
        "Sethekk Halls",
        "Shadow Labyrinth",
        -- Caverns of Time
        "Escape from Durnholde",
        "Opening of the Dark Portal",
        -- Tempest Keep
        "The Botanica",
        "The Mechanar",
        "The Arcatraz",
        -- Isle of Quel'Danas
        "Magisters' Terrace",
    },
    ["Heroic Dungeon"] = {
        -- Hellfire Citadel
        "Hellfire Ramparts",
        "The Blood Furnace",
        "The Shattered Halls",
        -- Coilfang Reservoir
        "The Slave Pens",
        "The Underbog",
        "The Steamvault",
        -- Auchindoun
        "Mana-Tombs",
        "Auchenai Crypts",
        "Sethekk Halls",
        "Shadow Labyrinth",
        -- Caverns of Time
        "Escape from Durnholde",
        "Opening of the Dark Portal",
        -- Tempest Keep
        "The Botanica",
        "The Mechanar",
        "The Arcatraz",
        -- Isle of Quel'Danas
        "Magisters' Terrace",
    },
    ["Raid"] = {
        -- Phase 1 (Tier 4)
        "Karazhan",
        "Gruul's Lair",
        "Magtheridon's Lair",
        -- Phase 2 (Tier 5)
        "Serpentshrine Cavern",
        "Tempest Keep",
        -- Phase 3 (Tier 6)
        "Battle for Mount Hyjal",
        "Black Temple",
        -- Phase 3.5
        "Zul'Aman",
        -- Phase 4
        "Sunwell Plateau",
    },
    ["PVP"] = {
        "Warsong Gulch",
        "Arathi Basin",
        "Alterac Valley",
        "Eye of the Storm",
    },
    ["Quest"] = {},
    ["Farm"]  = {},
    ["Chill"] = {},
}
