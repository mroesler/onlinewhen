-- Core/Specs.lua — Class specialization definitions and enum.
-- Depends on: Core/Status.lua (for OW.CLASS_NAME used by callers).

local addonName, OW = ...

-- All spec enum values. Class-prefixed keys avoid collisions on shared names
-- (Restoration, Holy, Protection each appear in two classes).
OW.SPEC = setmetatable({
    DRUID_BALANCE       =  1,  DRUID_FERAL         =  2,  DRUID_RESTORATION   =  3,
    HUNTER_BEASTMASTER  =  4,  HUNTER_MARKSMAN     =  5,  HUNTER_SURVIVAL     =  6,
    MAGE_ARCANE         =  7,  MAGE_FIRE           =  8,  MAGE_FROST          =  9,
    PALADIN_HOLY        = 10,  PALADIN_PROTECTION  = 11,  PALADIN_RETRIBUTION = 12,
    PRIEST_DISCIPLINE   = 13,  PRIEST_HOLY         = 14,  PRIEST_SHADOW       = 15,
    ROGUE_ASSASSINATION = 16,  ROGUE_COMBAT        = 17,  ROGUE_SUBTLETY      = 18,
    SHAMAN_ELEMENTAL    = 19,  SHAMAN_ENHANCEMENT  = 20,  SHAMAN_RESTORATION  = 21,
    WARLOCK_AFFLICTION  = 22,  WARLOCK_DEMONOLOGY  = 23,  WARLOCK_DESTRUCTION = 24,
    WARRIOR_ARMS        = 25,  WARRIOR_FURY        = 26,  WARRIOR_PROTECTION  = 27,
}, {
    __index    = function(_, k) error("OW.SPEC: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.SPEC: is read-only", 2) end,
})

-- Ordered spec list per class.
-- id    = OW.SPEC enum value.
-- label = display name stored in entry.spec (wire format and SavedVariables).
OW.CLASS_SPECS = {
    Druid   = {
        { id = OW.SPEC.DRUID_BALANCE,       label = "Balance"      },
        { id = OW.SPEC.DRUID_FERAL,         label = "Feral"        },
        { id = OW.SPEC.DRUID_RESTORATION,   label = "Restoration"  },
    },
    Hunter  = {
        { id = OW.SPEC.HUNTER_BEASTMASTER,  label = "Beastmaster"  },
        { id = OW.SPEC.HUNTER_MARKSMAN,     label = "Marksman"     },
        { id = OW.SPEC.HUNTER_SURVIVAL,     label = "Survival"     },
    },
    Mage    = {
        { id = OW.SPEC.MAGE_ARCANE,         label = "Arcane"       },
        { id = OW.SPEC.MAGE_FIRE,           label = "Fire"         },
        { id = OW.SPEC.MAGE_FROST,          label = "Frost"        },
    },
    Paladin = {
        { id = OW.SPEC.PALADIN_HOLY,        label = "Holy"         },
        { id = OW.SPEC.PALADIN_PROTECTION,  label = "Protection"   },
        { id = OW.SPEC.PALADIN_RETRIBUTION, label = "Retribution"  },
    },
    Priest  = {
        { id = OW.SPEC.PRIEST_DISCIPLINE,   label = "Discipline"   },
        { id = OW.SPEC.PRIEST_HOLY,         label = "Holy"         },
        { id = OW.SPEC.PRIEST_SHADOW,       label = "Shadow"       },
    },
    Rogue   = {
        { id = OW.SPEC.ROGUE_ASSASSINATION, label = "Assassination" },
        { id = OW.SPEC.ROGUE_COMBAT,        label = "Combat"        },
        { id = OW.SPEC.ROGUE_SUBTLETY,      label = "Subtlety"      },
    },
    Shaman  = {
        { id = OW.SPEC.SHAMAN_ELEMENTAL,    label = "Elemental"    },
        { id = OW.SPEC.SHAMAN_ENHANCEMENT,  label = "Enhancement"  },
        { id = OW.SPEC.SHAMAN_RESTORATION,  label = "Restoration"  },
    },
    Warlock = {
        { id = OW.SPEC.WARLOCK_AFFLICTION,  label = "Affliction"   },
        { id = OW.SPEC.WARLOCK_DEMONOLOGY,  label = "Demonology"   },
        { id = OW.SPEC.WARLOCK_DESTRUCTION, label = "Destruction"  },
    },
    Warrior = {
        { id = OW.SPEC.WARRIOR_ARMS,        label = "Arms"         },
        { id = OW.SPEC.WARRIOR_FURY,        label = "Fury"         },
        { id = OW.SPEC.WARRIOR_PROTECTION,  label = "Protection"   },
    },
}

-- Two-level lookup: OW.SPEC_ID[className][specLabel] → SPEC enum int.
-- Disambiguates shared labels (e.g. "Restoration" for Druid vs Shaman).
OW.SPEC_ID = {}
for className, specs in pairs(OW.CLASS_SPECS) do
    OW.SPEC_ID[className] = {}
    for _, spec in ipairs(specs) do
        OW.SPEC_ID[className][spec.label] = spec.id
    end
end

-- Inverse lookup: OW.SPEC_NAME[specId] → { class = className, label = specLabel }.
OW.SPEC_NAME = {}
for className, specs in pairs(OW.CLASS_SPECS) do
    for _, spec in ipairs(specs) do
        OW.SPEC_NAME[spec.id] = { class = className, label = spec.label }
    end
end
