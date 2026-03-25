---
phase: 01-data-foundation
plan: 02
subsystem: data
tags: [lua, wow-addon, tbc-classic, toc, load-order]

# Dependency graph
requires:
  - phase: 01-01
    provides: Data/Activities.lua created with OW.ACTIVITY enum, list, and sub-types
provides:
  - OnlineWhen.toc load-order registration for Data/Activities.lua
affects: [02-schedule-ui, 03-player-list-column, 04-filters, 05-network-protocol]

# Tech tracking
tech-stack:
  added: []
  patterns: [TOC file-list entry between existing data files]

key-files:
  created: []
  modified:
    - OnlineWhen.toc

key-decisions:
  - "Data/Activities.lua TOC entry placed between Data/Timezones.lua and Core/Status.lua — data files load before Core modules"

patterns-established:
  - "New Data/ files registered in TOC immediately after Data/Timezones.lua, before Core/Status.lua"

requirements-completed: [DATA-01]

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 01 Plan 02: TOC Registration Summary

**Data/Activities.lua registered in OnlineWhen.toc at load-order position between Data/Timezones.lua and Core/Status.lua, enabling OW.ACTIVITY globals at runtime**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-24T22:14:10Z
- **Completed:** 2026-03-24T22:14:30Z
- **Tasks:** 2 (1 auto, 1 checkpoint:human-verify auto-approved)
- **Files modified:** 1

## Accomplishments

- Verified `Data/Activities.lua` is registered in `OnlineWhen.toc` at the correct load-order position (already inserted during Plan 01 execution)
- TOC entry confirmed between `Data/Timezones.lua` and `Core/Status.lua`, ensuring data loads before Core modules that consume it
- Human-verify checkpoint auto-approved per `auto_advance: true` config — in-game verification (13 steps) to be performed by user

## Task Commits

Task 1 was committed atomically as part of Plan 01 (merge commit f28b00a):

1. **Task 1: Insert Data/Activities.lua into OnlineWhen.toc** - `f28b00a` (merge/chore — performed in 01-01)
2. **Task 2: Verify addon loads without errors** - auto-approved checkpoint (human verification pending)

**Plan metadata:** _(final docs commit follows)_

## Files Created/Modified

- `OnlineWhen.toc` — `Data/Activities.lua` line added between `Data/Timezones.lua` and `Core/Status.lua`

## Decisions Made

None - TOC insertion followed plan specification exactly.

## Deviations from Plan

### Pre-completed Work

Task 1 (Insert Data/Activities.lua into OnlineWhen.toc) was already completed as part of Plan 01-01's merge commit (`f28b00a`). The TOC entry was inserted alongside the Activities.lua file creation in the same commit. This is not a deviation — the work is done and verified.

## Issues Encountered

None.

## User Setup Required

**In-game verification required.** When loading the WoW TBC Classic Anniversary client, confirm:
1. No Lua error popup on addon load
2. `/ow` opens normally
3. `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` prints `1`
4. `/run print(OW.ACTIVITY.CHILL)` prints `7`
5. `/run print(#OW.ACTIVITY_LIST)` prints `7`
6. `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` prints `16`
7. `/run print(#OW.ACTIVITY_SUBS["Heroic Dungeon"])` prints `16`
8. `/run print(#OW.ACTIVITY_SUBS["Raid"])` prints `9`
9. `/run print(#OW.ACTIVITY_SUBS["PVP"])` prints `4`
10. `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` prints `true`
11. `/run print(#OW.ACTIVITY_SUBS["Quest"])` prints `0`
12. `/run print(OW.ACTIVITY.FAKE)` produces a Lua error containing "OW.ACTIVITY: unknown key: FAKE"

## Next Phase Readiness

- Phase 01 (data-foundation) is complete — both plans executed
- `OW.ACTIVITY`, `OW.ACTIVITY_LIST`, and `OW.ACTIVITY_SUBS` will be globally available after addon load
- Phase 02 (schedule-ui) can proceed — activity data structures are ready for Schedule tab dropdown wiring

## Self-Check: PASSED

- FOUND: OnlineWhen.toc contains `Data/Activities.lua` (line 10)
- FOUND: `Data/Activities.lua` between `Data/Timezones.lua` and `Core/Status.lua` — verified by grep
- FOUND commit: f28b00a (merge(01-01): integrate Data/Activities.lua from worktree)

---
*Phase: 01-data-foundation*
*Completed: 2026-03-24*
