---
phase: 04-player-list-column
plan: "03"
subsystem: ui
tags: [lua, wow-addon, player-list, sorting, activity]

# Dependency graph
requires:
  - phase: 04-01
    provides: activity column layout constants (COL_X.activity, COL_W.activity) and FontString row rendering

provides:
  - Activity column header button wired to setSort("activity") via makeHeader helper
  - sortEntries() activity case: exact activity (fallback primary), nil-last regardless of ASC/DESC
  - Refresh() updates sort arrow indicator on Activity header

affects:
  - 04-04 (activity filter row — depends on column being present)
  - 05 (any future phase touching player list layout)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "nil-last sort: early return bNil before ASC/DESC flip, ensures nil entries always sort last in both directions"
    - "Exact-with-fallback sort key: exactActivity || primaryActivity, consistent with D-07 decision"

key-files:
  created: []
  modified:
    - UI/TabPlayers.lua

key-decisions:
  - "nil-last uses early return bNil (bypasses ASC/DESC comparison) — only evaluated when aNil != bNil"
  - "sort key is exactActivity (non-empty) with fallback to primaryActivity, both lowercased for case-insensitive comparison"

patterns-established:
  - "makeHeader() call between spec and time in Build() — activity slot established"
  - "headerBtns.activity guarded with if-check in Refresh() — consistent with all other sortable headers"

requirements-completed: [LIST-02]

# Metrics
duration: 3min
completed: 2026-03-25
---

# Phase 4 Plan 03: Activity Column Sort Summary

**Clickable Activity column header with exact/primary-fallback sort and nil-last behavior wired into sortEntries() and Refresh()**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-25
- **Completed:** 2026-03-25
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added "activity" sort case to sortEntries() with nil-last early return logic and exact/primary-fallback sort key
- Added makeHeader("activity") call between spec and time header calls in TL.Build()
- Added headerBtns.activity sort arrow update in TL.Refresh() header update block

## Task Commits

Each task was committed atomically:

1. **Task 1: Add "activity" sort case to sortEntries()** - `1d925b8` (feat)
2. **Task 2: Add Activity column header and Refresh() update** - `9880e09` (feat)

## Files Created/Modified

- `UI/TabPlayers.lua` - Added activity sort case in sortEntries(), makeHeader call in TL.Build(), and header arrow update in TL.Refresh()

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Activity column is sortable; header button present between Spec and Online At
- Ready for 04-04: activity filter row (second filter row in player list)

---
*Phase: 04-player-list-column*
*Completed: 2026-03-25*
