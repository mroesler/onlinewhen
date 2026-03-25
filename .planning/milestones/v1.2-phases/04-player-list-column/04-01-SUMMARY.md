---
phase: 04-player-list-column
plan: 01
subsystem: ui
tags: [lua, wow-addon, layout, constants]

# Dependency graph
requires:
  - phase: 03-schedule-tab-ui
    provides: WINDOW_H expansion already done; window sizing baseline established
provides:
  - WINDOW_W = 950 in UI/Window.lua
  - CONTENT_W = 938 in UI/TabPlayers.lua
  - COL_X and COL_W tables with activity column (x=420, w=150), time shifted to x=576, actions shifted to x=828
affects:
  - 04-02 (activity column header and row rendering — reads COL_X/COL_W.activity)
  - 04-03 (activity filter row — reads CONTENT_W for filter bar sizing)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Layout constants as local tables (COL_X, COL_W) — single source of truth for all column geometry"

key-files:
  created: []
  modified:
    - UI/Window.lua
    - UI/TabPlayers.lua

key-decisions:
  - "No changes to WINDOW_H — height expansion was handled in Phase 3 (TabSchedule); only width needed for player list column"
  - "activity column slot inserted at x=420 (after spec at x=314+w=100=414, with 6px gap) with w=150; time/actions shifted right by 150px"

patterns-established:
  - "Column layout constants live in TabPlayers.lua as local tables; adding a column requires updating both COL_X and COL_W entries"

requirements-completed: [LIST-04]

# Metrics
duration: 2min
completed: 2026-03-25
---

# Phase 04 Plan 01: Layout Constants Summary

**Window widened to 950px and Activity column slot added to TabPlayers layout constants (COL_X.activity=420, COL_W.activity=150), shifting time and actions columns right by 150px**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-25T00:38:00Z
- **Completed:** 2026-03-25T00:40:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- WINDOW_W updated from 800 to 950 in UI/Window.lua — main window is now 150px wider
- CONTENT_W updated from 788 to 938 in UI/TabPlayers.lua — tab content area matches new window width
- Activity column added to COL_X and COL_W tables; time and actions columns shifted right by 150px to accommodate

## Task Commits

Each task was committed atomically:

1. **Task 1: Update WINDOW_W in UI/Window.lua** - `8efb819` (feat)
2. **Task 2: Update CONTENT_W, COL_X, and COL_W in UI/TabPlayers.lua** - `02beeb1` (feat)

## Files Created/Modified

- `UI/Window.lua` - WINDOW_W changed from 800 to 950
- `UI/TabPlayers.lua` - CONTENT_W changed from 788 to 938; COL_X and COL_W updated with activity column, time/actions shifted

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Layout foundation is complete; Plan 02 can now add the Activity column header and row rendering using COL_X.activity and COL_W.activity
- Plan 03 can add the second filter row using CONTENT_W = 938 for sizing

---
*Phase: 04-player-list-column*
*Completed: 2026-03-25*
