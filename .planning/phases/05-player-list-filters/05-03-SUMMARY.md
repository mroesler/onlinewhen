---
phase: 05-player-list-filters
plan: "03"
subsystem: UI/TabPlayers
tags: [filters, activity, cascade, lua, player-list]
dependency_graph:
  requires: [05-02]
  provides: [activity-cascade-wiring, reset-filters-activity-support]
  affects: [UI/TabPlayers.lua]
tech_stack:
  added: []
  patterns: [ACTIVITY_SUBS-cascade-lookup, setChoices-setActive-cascade, six-filter-reset]
key_files:
  created: []
  modified:
    - UI/TabPlayers.lua
key_decisions:
  - "OW.ACTIVITY_SUBS[val] lookup with #subs > 0 check correctly handles Quest/Farm/Chill empty tables without special-casing"
  - "filterExactActivity cleared in both primaryActivity onChange and Reset Filters — consistent with filterSpec cleared in class onChange and Reset Filters"
  - "primaryActivityFilterBtn._fs:SetText(_default) resets label text without triggering onChange — same pattern as statusFilterBtn/levelFilterBtn/classFilterBtn reset"
requirements-completed: [FILT-04, FILT-05, FILT-06, FILT-07]
duration: "~4min"
completed: "2026-03-25"
---

# Phase 05 Plan 03: Activity Filter Cascade Wiring Summary

**ACTIVITY_SUBS cascade wiring for primary->exact activity dropdown and Reset Filters extended to clear all 6 filter variables including both activity filters**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-25T02:25:00Z
- **Completed:** 2026-03-25T02:29:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Primary activity onChange now looks up `OW.ACTIVITY_SUBS[val]` and enables/populates exactActivityFilterBtn when sub-types exist (Normal Dungeon, Heroic Dungeon, Raid, PVP), disables it for Quest/Farm/Chill
- Reset Filters OnClick extended with `filterPrimaryActivity = nil`, `filterExactActivity = nil`, primary label reset via `_fs:SetText(_default)`, and exact dropdown reset to single "Any Exact Activity" item with `setActive(false)`
- All 6 filter variables (filterStatus, filterLevel, filterClass, filterSpec, filterPrimaryActivity, filterExactActivity) are now cleared by Reset Filters

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire primary activity onChange cascade logic** - `d0e17ed` (feat)
2. **Task 2: Extend Reset Filters to clear activity filters** - `98927f2` (feat)

## Files Created/Modified

- `UI/TabPlayers.lua` - primaryActivityFilterBtn onChange with ACTIVITY_SUBS cascade; Reset Filters extended for activity filter cleanup

## Decisions Made

- `OW.ACTIVITY_SUBS[val]` lookup with `#subs > 0` check handles Quest/Farm/Chill empty tables (`{}`) correctly — the same guard used in the Schedule tab for hiding the exact-activity dropdown
- Reset approach for primaryActivityFilterBtn uses `._fs:SetText(._default)` (not `setChoices`) since primary choices never change — consistent with statusFilterBtn/levelFilterBtn/classFilterBtn reset pattern

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Worktree branch was behind `main` and missing the 05-01/05-02 implementation commits from parallel worktrees. Resolved by merging `main` then `worktree-agent-a7d72eaf` before starting task execution.

## Next Phase Readiness

Phase 05 (player-list-filters) is now complete. All activity filter interactions are wired:
- Primary activity dropdown populates/enables exact based on ACTIVITY_SUBS
- Quest/Farm/Chill selections correctly keep exact dropdown disabled
- Reset Filters restores all 6 filters to default state

---
*Phase: 05-player-list-filters*
*Completed: 2026-03-25*
