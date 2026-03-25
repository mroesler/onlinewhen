---
phase: 01-data-foundation
plan: 01
subsystem: data
tags: [lua, wow-addon, tbc-classic, static-data, enum]

# Dependency graph
requires: []
provides:
  - OW.ACTIVITY read-only enum (7 keys, sequential IDs 1-7)
  - OW.ACTIVITY_LIST ordered array of 7 {id, label} records
  - OW.ACTIVITY_SUBS sub-type tables (16 Normal Dungeon, 16 Heroic Dungeon, 9 Raid, 4 PVP, 3 empty)
affects: [02-schedule-ui, 03-player-list-column, 04-filters, 05-network-protocol]

# Tech tracking
tech-stack:
  added: []
  patterns: [setmetatable read-only enum guard, ordered {id,label} list, label-keyed sub-type table]

key-files:
  created:
    - Data/Activities.lua
  modified:
    - OnlineWhen.toc

key-decisions:
  - "Plain strings in OW.ACTIVITY_SUBS (not {id,label} pairs) — downstream consumers key by label, no id needed at sub-type level"
  - "Quest/Farm/Chill map to empty table {} not nil — prevents nil-iteration errors in all consumers"
  - "Data/Activities.lua inserted in TOC between Timezones.lua and Core/Status.lua per load-order rules"

patterns-established:
  - "OW.ACTIVITY enum: setmetatable read-only guard matching OW.SPEC pattern from Core/Specs.lua"
  - "OW.ACTIVITY_LIST: flat ordered array of {id, label} records (not nested by group)"
  - "OW.ACTIVITY_SUBS: table keyed by label string with plain string values"
  - "File header: 3 comment lines + blank line + local addonName, OW = ... (no OW = OW or {} guard)"

requirements-completed: [DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 01 Plan 01: Activity Data Foundation Summary

**OW.ACTIVITY enum + OW.ACTIVITY_LIST + OW.ACTIVITY_SUBS for all TBC Classic Anniversary content (7 activities, 16+16+9+4 sub-types) in a single pure-Lua data file**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-24T22:10:17Z
- **Completed:** 2026-03-24T22:11:17Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Created `Data/Activities.lua` with three data structures: read-only enum, ordered display list, and sub-type lookup table
- Populated all TBC Classic Anniversary content: 16 Normal Dungeons (Hellfire Ramparts through Magisters' Terrace), 16 Heroic Dungeons (same list), 9 Raids across all phases (Karazhan through Sunwell Plateau), 4 Battlegrounds
- Updated `OnlineWhen.toc` to load `Data/Activities.lua` in the correct position (after Timezones.lua, before Core/Status.lua)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Data/Activities.lua with enum, ordered list, and sub-type tables** - `2c7ad6d` (feat)

**Plan metadata:** _(final docs commit follows)_

## Files Created/Modified

- `Data/Activities.lua` — Complete activity data module: OW.ACTIVITY enum, OW.ACTIVITY_LIST, OW.ACTIVITY_SUBS
- `OnlineWhen.toc` — Added Data/Activities.lua entry between Data/Timezones.lua and Core/Status.lua

## Decisions Made

- Plain strings used for sub-type entries in OW.ACTIVITY_SUBS (not {id, label} pairs) — downstream UI code only needs the display string; no numeric ID required at sub-type level
- Quest, Farm, and Chill mapped to empty tables `{}` rather than omitted — prevents nil-iteration errors in all future consumers
- Heroic Dungeon list is identical to Normal Dungeon list (all 16 TBC dungeons have heroic versions per D-02/research)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `OW.ACTIVITY`, `OW.ACTIVITY_LIST`, and `OW.ACTIVITY_SUBS` are available globally via the OW namespace after addon load
- All downstream phases (Schedule UI, Player List column, Filters, Network protocol) can reference these structures directly
- No blockers — single source of truth for activity data is complete

## Self-Check: PASSED

- FOUND: Data/Activities.lua
- FOUND: .planning/phases/01-data-foundation/01-01-SUMMARY.md
- FOUND commit: 2c7ad6d (feat(01-01): create Data/Activities.lua with activity enum, list, and sub-types)

---
*Phase: 01-data-foundation*
*Completed: 2026-03-24*
