# Phase 1: Data Foundation - Research

**Researched:** 2026-03-24
**Domain:** WoW Addon Lua — Static data module authoring, TBC Classic Anniversary content lists
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Activity display order (baked into `OW.ACTIVITY_LIST`): Normal Dungeon → Heroic Dungeon → Raid → PVP → Quest → Farm → Chill. Content-first ordering — heavy group content at the top, casual solo activities at the bottom.
- **D-02:** Normal Dungeon and Heroic Dungeon use **separate** sub-type lists. `OW.ACTIVITY_SUBS["Normal Dungeon"]` lists instances available in normal mode; `OW.ACTIVITY_SUBS["Heroic Dungeon"]` lists instances available in heroic mode. Some instances appear in both; mode-only instances (e.g. normal-only) appear only in their list.
- **D-03:** Include **all** TBC Classic Anniversary instances — dungeons (all modes), all raid tiers, all battlegrounds. This includes Caverns of Time instances (Escape from Durnholde, Opening of the Dark Portal), Magisters' Terrace, and all phases of raid content. Completeness is preferred over a curated short list.
- TOC load-order position: `Data/Activities.lua` must be inserted between `Data/Timezones.lua` and `Core/Status.lua`.

### Claude's Discretion

- Exact enum integer IDs for `OW.ACTIVITY` (follow the OW.SPEC pattern: sequential integers starting at 1)
- Exact enum key names (e.g. `NORMAL_DUNGEON` vs `DUNGEON_NORMAL` — follow OW.SPEC naming style)
- Whether sub-type entries are plain strings or `{ id, label }` pairs (the ROADMAP success criteria uses string indexing, plain strings are sufficient)
- Exact dungeon/raid/BG names as they appear in-game (researcher will identify canonical TBC Classic Anniversary names)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | `Data/Activities.lua` defines 7 primary activities: Quest, PVP, Normal Dungeon, Heroic Dungeon, Raid, Farm, Chill | Enum pattern from Core/Specs.lua; OW.ACTIVITY_LIST mirrors OW.CLASS_SPECS structure |
| DATA-02 | All TBC Classic Anniversary dungeons listed as sub-options for Normal Dungeon and Heroic Dungeon | Canonical dungeon list researched and documented below; split by availability per mode |
| DATA-03 | All TBC Classic Anniversary raids listed as sub-options for Raid | All raid tiers across all phases documented below |
| DATA-04 | All TBC Anniversary Classic battlegrounds listed as sub-options for PVP | 4 battlegrounds confirmed: WSG, AB, AV, EotS |
| DATA-05 | Activities with no sub-types (Quest, Farm, Chill) have an empty sub-type list | Empty table `{}` pattern required (not nil) — confirmed by success criteria |
</phase_requirements>

---

## Summary

Phase 1 is a pure Lua data authoring task with no WoW API dependencies. The entire deliverable is a single file: `Data/Activities.lua`. All patterns for this file already exist verbatim in the codebase — the `setmetatable` read-only guard comes from `Core/Specs.lua`, the `{ id, label }` list structure comes from `OW.CLASS_SPECS`, and the file header/namespace convention comes from `Data/Timezones.lua`.

The only domain-specific research concern is the canonical list of TBC Classic Anniversary dungeon, raid, and battleground names. These have been verified and are documented below with confidence levels. Normal and Heroic dungeon lists differ: all 16 level-70-available dungeons support heroic, while the lower-level leveling dungeons (Hellfire Ramparts, Blood Furnace, Slave Pens, Underbog, Mana-Tombs, Auchenai Crypts, Old Hillsbrad Foothills) are also available on normal for leveling characters. Magisters' Terrace and Caverns of Time dungeons are available in both modes at 70.

**Primary recommendation:** Copy the `OW.SPEC` read-only metatable pattern exactly, use SCREAMING_SNAKE_CASE keys (`NORMAL_DUNGEON`, `HEROIC_DUNGEON`, `RAID`, `PVP`, `QUEST`, `FARM`, `CHILL`), sequential IDs starting at 1 in display order (D-01), and plain strings in `OW.ACTIVITY_SUBS` (no `{ id, label }` wrapping needed).

---

## Standard Stack

This phase requires no external libraries. It is pure Lua executed by the WoW client.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Lua 5.1 (WoW) | 5.1 (WoW TBC 2.5.x) | Language runtime | The only language available in WoW addons |
| `setmetatable` | Built-in | Read-only enum guard | Established pattern in this codebase; catches typos at runtime |

### No Installation Required

This phase creates one `.lua` file and modifies one `.toc` file. No packages, dependencies, or tooling changes needed.

---

## Architecture Patterns

### Recommended File Structure

```
Data/
├── Timezones.lua       # existing
└── Activities.lua      # NEW — this phase's deliverable
```

The file inserts into the TOC between `Data/Timezones.lua` and `Core/Status.lua`.

### Pattern 1: Read-Only Enum (copy from Core/Specs.lua)

**What:** A Lua table wrapped in `setmetatable` whose `__index` raises a Lua error on unknown key access and whose `__newindex` prevents mutation.

**When to use:** Every enum in this codebase uses this pattern — `OW.STATUS`, `OW.CLASS`, `OW.SPEC`.

**Example (source: Core/Specs.lua):**
```lua
-- Source: Core/Specs.lua (verbatim pattern)
OW.SPEC = setmetatable({
    DRUID_BALANCE = 1,  ...
}, {
    __index    = function(_, k) error("OW.SPEC: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.SPEC: is read-only", 2) end,
})
```

For `OW.ACTIVITY`, apply identically — only the table name and error prefix change:
```lua
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
```

**Enum key naming:** SCREAMING_SNAKE_CASE. The `OW.SPEC` precedent uses `CLASS_SPECNAME` to handle ambiguity; for activities there is no ambiguity, so single-word keys suffice except for the two dungeon modes. `NORMAL_DUNGEON` and `HEROIC_DUNGEON` follow the `CLASS_SPEC` compound format — adjective then noun.

**ID assignment:** Sequential integers 1–7 matching the D-01 display order (Normal Dungeon=1, Heroic Dungeon=2, Raid=3, PVP=4, Quest=5, Farm=6, Chill=7).

### Pattern 2: Ordered List with id+label (copy from OW.CLASS_SPECS structure)

**What:** An array of `{ id, label }` records where `id` is the enum integer and `label` is the display string.

**When to use:** `OW.ACTIVITY_LIST` must use this pattern so consumers can iterate in display order and get both the enum id and the human-readable label.

**Example (source: Core/Specs.lua, OW.CLASS_SPECS):**
```lua
-- Source: Core/Specs.lua
OW.CLASS_SPECS = {
    Druid = {
        { id = OW.SPEC.DRUID_BALANCE, label = "Balance" },
        ...
    },
}
```

For `OW.ACTIVITY_LIST`, the structure is a flat array (not nested by group):
```lua
OW.ACTIVITY_LIST = {
    { id = OW.ACTIVITY.NORMAL_DUNGEON, label = "Normal Dungeon" },
    { id = OW.ACTIVITY.HEROIC_DUNGEON, label = "Heroic Dungeon" },
    { id = OW.ACTIVITY.RAID,           label = "Raid"           },
    { id = OW.ACTIVITY.PVP,            label = "PVP"            },
    { id = OW.ACTIVITY.QUEST,          label = "Quest"          },
    { id = OW.ACTIVITY.FARM,           label = "Farm"           },
    { id = OW.ACTIVITY.CHILL,          label = "Chill"          },
}
```

### Pattern 3: Sub-type Table (plain strings, keyed by label)

**What:** A table keyed by the activity's `label` string (not its id), with each value being an array of plain strings. Activities with no sub-types map to an empty table `{}`.

**When to use:** `OW.ACTIVITY_SUBS` is the lookup mechanism for downstream UI and filter code.

**Structure:**
```lua
OW.ACTIVITY_SUBS = {
    ["Normal Dungeon"]  = { "Hellfire Ramparts", "The Blood Furnace", ... },
    ["Heroic Dungeon"]  = { "Hellfire Ramparts", "The Blood Furnace", ... },
    ["Raid"]            = { "Karazhan", "Gruul's Lair", ... },
    ["PVP"]             = { "Warsong Gulch", "Arathi Basin", ... },
    ["Quest"]           = {},
    ["Farm"]            = {},
    ["Chill"]           = {},
}
```

**Why plain strings:** The success criteria uses `OW.ACTIVITY_SUBS["Normal Dungeon"]` and checks for a list of dungeon name strings. No `{ id, label }` wrapping is required — that would add complexity with no consumer benefit at this layer.

**Why keyed by label:** Downstream consumers already have the label (from `OW.ACTIVITY_LIST`) when they need to look up sub-types. Avoids a redundant id-to-label mapping step.

### Pattern 4: File Header and Namespace

**What:** Every file opens with `local addonName, OW = ...` (no `OW = OW or {}`). The older pattern in `Data/Timezones.lua` is explicitly noted as legacy.

**Source: .planning/codebase/CONVENTIONS.md and 01-CONTEXT.md:**
```lua
-- Data/Activities.lua — Activity definitions for TBC Classic Anniversary.
-- Defines: OW.ACTIVITY enum, OW.ACTIVITY_LIST, OW.ACTIVITY_SUBS.
-- No WoW API dependencies — pure Lua tables only.

local addonName, OW = ...
```

### Pattern 5: Section Dividers

75-dash separator lines between logical sections (source: CONVENTIONS.md):
```lua
-- ---------------------------------------------------------------------------
-- Activity enum
-- ---------------------------------------------------------------------------
```

### Anti-Patterns to Avoid

- **`OW = OW or {}`** at file top: This is the old `Data/Timezones.lua` pattern. All other files use `local addonName, OW = ...` without the guard. Do not use the guard in `Data/Activities.lua`.
- **Nil instead of empty table:** `OW.ACTIVITY_SUBS["Quest"]` must return `{}`, not `nil`. Nil forces all consumers to add nil-checks. Empty table is the explicit contract.
- **WoW API calls:** No `C_*`, `GetSpellInfo`, frame creation, or event registration belongs in `Data/`. This file is pure Lua tables.
- **`{ id, label }` wrapping in sub-type lists:** Sub-type entries are plain strings. The `{ id, label }` pattern is only for `OW.ACTIVITY_LIST` (top-level activities), not for sub-type strings inside `OW.ACTIVITY_SUBS`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Read-only enum | Custom guard logic | Copy `setmetatable` pattern from `Core/Specs.lua` verbatim | Already tested, already the project standard |
| Ordered list structure | New list format | Copy `{ id, label }` pattern from `OW.CLASS_SPECS` verbatim | Downstream code in Phase 3/4/5 will expect this exact shape |

**Key insight:** This phase is 100% pattern reuse. There is nothing novel to design — the codebase already has every building block. The only genuine content work is assembling the correct canonical dungeon/raid/BG name lists.

---

## TBC Classic Anniversary Content Lists (Verified)

These lists are the primary research output for DATA-02, DATA-03, DATA-04.

### Normal Dungeon Sub-types (DATA-02)

All TBC Classic dungeons that can be run on Normal difficulty. Includes leveling dungeons (not available on heroic) and all level-70 dungeons.
Confidence: MEDIUM (web sources cross-referenced; canonical in-game name formatting should be verified against live client if possible)

**Hellfire Citadel:**
- Hellfire Ramparts
- The Blood Furnace
- The Shattered Halls

**Coilfang Reservoir:**
- The Slave Pens
- The Underbog
- The Steamvault

**Auchindoun:**
- Mana-Tombs
- Auchenai Crypts
- Sethekk Halls
- Shadow Labyrinth

**Caverns of Time:**
- Escape from Durnholde
- Opening of the Dark Portal

**Tempest Keep:**
- The Botanica
- The Mechanar
- The Arcatraz

**Isle of Quel'Danas:**
- Magisters' Terrace

### Heroic Dungeon Sub-types (DATA-02)

All TBC Classic dungeons that can be run on Heroic difficulty. Heroic requires level 70 and reputation keys. All dungeons that are available at level 70 have a heroic mode; the lower-level leveling dungeons (Hellfire Ramparts, Blood Furnace, Slave Pens, Underbog, Mana-Tombs, Auchenai Crypts, Old Hillsbrad Foothills) also have heroic versions in TBC.
Confidence: MEDIUM

Per D-02, the two lists may overlap — instances available in both modes appear in both lists. The full heroic list is:

- Hellfire Ramparts
- The Blood Furnace
- The Shattered Halls
- The Slave Pens
- The Underbog
- The Steamvault
- Mana-Tombs
- Auchenai Crypts
- Sethekk Halls
- Shadow Labyrinth
- Escape from Durnholde
- Opening of the Dark Portal
- The Botanica
- The Mechanar
- The Arcatraz
- Magisters' Terrace

Note: In original TBC, all 16 dungeons (including leveling dungeons) have heroic versions. This matches D-03 (completeness preferred).

### Raid Sub-types (DATA-03)

All raid tiers across all TBC Classic Anniversary phases. D-03 explicitly requires all phases, including future ones.
Confidence: HIGH (Wowhead and Warcraft Tavern phase guides cross-verified)

**Phase 1 (Tier 4):**
- Karazhan
- Gruul's Lair
- Magtheridon's Lair

**Phase 2 (Tier 5):**
- Serpentshrine Cavern
- Tempest Keep

**Phase 3 (Tier 6):**
- Battle for Mount Hyjal
- Black Temple

**Phase 3.5:**
- Zul'Aman

**Phase 4:**
- Sunwell Plateau

### PVP Sub-types (DATA-04)

All battlegrounds available in TBC Classic Anniversary.
Confidence: HIGH (multiple sources agree on exactly 4 battlegrounds)

- Warsong Gulch
- Arathi Basin
- Alterac Valley
- Eye of the Storm

---

## Common Pitfalls

### Pitfall 1: Forgetting the TOC entry

**What goes wrong:** `Data/Activities.lua` exists but is never loaded by the WoW client because it is not in `OnlineWhen.toc`.

**Why it happens:** Developers sometimes create the Lua file and test it by loading another file, not noticing the TOC was not updated.

**How to avoid:** The TOC edit is part of the same task as the file creation. The required position is after `Data/Timezones.lua` and before `Core/Status.lua`.

**Warning signs:** Any file that references `OW.ACTIVITY` at load time will silently get nil — no error if you use `OW.ACTIVITY` without the read-only guard having been applied yet.

### Pitfall 2: Using `OW = OW or {}` (old pattern)

**What goes wrong:** Copying from `Data/Timezones.lua` instead of from `Core/Specs.lua` for the namespace setup results in the old legacy pattern being used.

**Why it happens:** `Data/Timezones.lua` is the natural reference for a `Data/` file header, but its namespace line is noted as legacy in CONTEXT.md.

**How to avoid:** Use `local addonName, OW = ...` with no `OW or {}` guard. The addon loader always passes the shared namespace table.

### Pitfall 3: nil sub-type entry instead of empty table

**What goes wrong:** `OW.ACTIVITY_SUBS["Quest"]` returns nil. Any consumer that iterates `for _, v in ipairs(OW.ACTIVITY_SUBS[activityLabel])` will error on nil.

**Why it happens:** Omitting the key from `OW.ACTIVITY_SUBS` entirely, or explicitly setting it to nil.

**How to avoid:** Every activity label must be a key in `OW.ACTIVITY_SUBS`. Quest, Farm, and Chill map to `{}`.

### Pitfall 4: In-game name formatting errors

**What goes wrong:** Sub-type strings like "Hellfire Ramparts" are subtly wrong (e.g. "Hellfire Citadel: Hellfire Ramparts" with the zone prefix, or "Black Morass" without "The").

**Why it happens:** Different sources use different formats. The WoW client's dungeon names and Wowhead sometimes differ.

**How to avoid:** Use short, commonly recognized names without zone prefixes. "Hellfire Ramparts" not "Hellfire Citadel: Hellfire Ramparts". "Opening of the Dark Portal" with article where the dungeon name includes it. These names are display-only strings stored in SavedVariables — they do not need to match any WoW API key. Consistency within the list matters most.

### Pitfall 5: Load-order dependency violation

**What goes wrong:** Some file in the load order after `Data/Activities.lua` attempts to reference `OW.ACTIVITY` before `Data/Activities.lua` has been loaded.

**Why it happens:** Incorrect TOC position.

**How to avoid:** `Data/Activities.lua` must be positioned in TOC after `Data/Timezones.lua` and before `Core/Status.lua`. No file before position 2.5 in load order references activities. `Core/Database.lua` (position 6) is the first consumer — it will load after.

---

## Code Examples

### Complete file skeleton
```lua
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
        -- same 16 dungeons (all have heroic versions in TBC)
        "Hellfire Ramparts",
        "The Blood Furnace",
        "The Shattered Halls",
        "The Slave Pens",
        "The Underbog",
        "The Steamvault",
        "Mana-Tombs",
        "Auchenai Crypts",
        "Sethekk Halls",
        "Shadow Labyrinth",
        "Escape from Durnholde",
        "Opening of the Dark Portal",
        "The Botanica",
        "The Mechanar",
        "The Arcatraz",
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
```

### TOC edit (OnlineWhen.toc)
```
Locales/enUS.lua
Data/Timezones.lua
Data/Activities.lua        ← INSERT HERE
Core/Status.lua
Core/Classes.lua
...
```

---

## Runtime State Inventory

This is a greenfield data file addition — no rename or migration is involved. No runtime state is affected.

**Stored data:** None — `Data/Activities.lua` contributes no SavedVariables.
**Live service config:** None — no external services.
**OS-registered state:** None.
**Secrets/env vars:** None.
**Build artifacts:** None — the WoW client reads `.lua` files directly; no compilation step.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is a pure code/config change (one new `.lua` file, one `.toc` line). No external tools, services, CLIs, or runtimes beyond the existing WoW addon development setup are required.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — WoW addon Lua cannot be unit-tested with standard frameworks outside the WoW client |
| Config file | none |
| Quick run command | Manual: load addon in WoW client, `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` |
| Full suite command | Manual: verify all 5 success criteria in-game |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | `OW.ACTIVITY` enum has 7 keys; unknown key raises error | manual-only | `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` then `/run print(OW.ACTIVITY.FAKE)` | ❌ Wave 0 |
| DATA-02 | `OW.ACTIVITY_SUBS["Normal Dungeon"]` and `["Heroic Dungeon"]` return correct dungeon lists | manual-only | `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` | ❌ Wave 0 |
| DATA-03 | `OW.ACTIVITY_SUBS["Raid"]` returns all 9 raid names | manual-only | `/run print(#OW.ACTIVITY_SUBS["Raid"])` | ❌ Wave 0 |
| DATA-04 | `OW.ACTIVITY_SUBS["PVP"]` returns 4 battleground names | manual-only | `/run print(#OW.ACTIVITY_SUBS["PVP"])` | ❌ Wave 0 |
| DATA-05 | `OW.ACTIVITY_SUBS["Quest"]`, `["Farm"]`, `["Chill"]` each return `{}` (not nil) | manual-only | `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` | ❌ Wave 0 |

**Justification for manual-only:** WoW addon Lua executes inside the WoW client sandbox. There is no standalone Lua test runner configured for this project. All validation is done in-game via slash commands in the WoW chat window.

### Sampling Rate

- **Per task commit:** Load addon and run the relevant `/run` command above
- **Per wave merge:** Run all 5 manual checks in sequence
- **Phase gate:** All 5 success criteria verified before marking phase complete

### Wave 0 Gaps

- [ ] No automated test infrastructure exists or is needed for this phase — all checks are manual in-game `/run` commands

---

## Open Questions

1. **Canonical in-game names for dungeons**
   - What we know: Web sources use "Hellfire Ramparts", "The Blood Furnace", etc. with articles ("The") where present in the dungeon's proper name
   - What's unclear: Whether "Escape from Durnholde" or "Escape from Durnholde" is the player-facing name the user would recognize ("Escape from Durnholde" is the zone; "Escape from Durnholde" is the dungeon name)
   - Recommendation: Use "Escape from Durnholde" for Normal Dungeon (the name players use when searching/talking), and "Opening of the Dark Portal" for the other CoT instance. These are display-only strings — use what is most recognizable. Can be adjusted post-implementation with a one-line edit.

2. **Caverns of Time CONTEXT.md reference uses different names than web sources**
   - What we know: CONTEXT.md (D-03) lists "Escape from Durnholde" and "Opening of the Dark Portal" as the canonical names
   - What's unclear: "Escape from Durnholde" vs "Escape from Durnholde" — both refer to the same instance
   - Recommendation: Honor CONTEXT.md D-03 explicitly — use "Escape from Durnholde" and "Opening of the Dark Portal" as those are the dungeon names (not the zone names). Update the code example accordingly.

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `OW = OW or {}` namespace guard | `local addonName, OW = ...` only | `Data/Timezones.lua` uses the old pattern; all other files use the current pattern |

---

## Sources

### Primary (HIGH confidence)
- `Core/Specs.lua` — Read directly; source of the setmetatable enum pattern and `{ id, label }` list structure
- `Data/Timezones.lua` — Read directly; source of file header convention and namespace pattern
- `OnlineWhen.toc` — Read directly; current load order confirmed
- `.planning/codebase/CONVENTIONS.md` — Read directly; all naming and comment conventions
- `.planning/codebase/STRUCTURE.md` — Read directly; load order rules and Data/ directory purpose
- `.planning/phases/01-data-foundation/01-CONTEXT.md` — Read directly; all locked decisions

### Secondary (MEDIUM confidence)
- [Classic Burning Crusade Dungeons Overview - Wowhead](https://www.wowhead.com/tbc/guide/dungeons-overview-burning-crusade-classic) — Dungeon list with difficulty modes
- [The Burning Crusade Classic Anniversary Phase Release Roadmap - Wowhead](https://www.wowhead.com/tbc/guide/the-burning-crusade-classic-anniversary-phase-release-roadmap) — Raid tier by phase
- [TBC Anniversary Phases, Schedule & Roadmap - Warcraft Tavern](https://www.warcrafttavern.com/tbc/guides/phases/) — Cross-verification of raid phases
- [WoW TBC PvP Overview - Overgear](https://overgear.com/guides/wow-classic/tbc-anniversary-pvp-overview/) — Battleground list (4 BGs confirmed)

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external libraries; pure in-project patterns
- Architecture: HIGH — exact patterns read directly from codebase source files
- Pitfalls: HIGH — derived from direct code inspection and convention documents
- Content lists (dungeon/raid/BG names): MEDIUM — web sources cross-referenced but not verified against live client

**Research date:** 2026-03-24
**Valid until:** 2026-06-24 (stable domain — TBC Classic content list is fixed; Lua patterns don't change)
