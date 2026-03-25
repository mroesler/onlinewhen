---
phase: 05-player-list-filters
plan: "01"
subsystem: UI/TabPlayers
tags: [filters, activity, lua, player-list]
dependency_graph:
  requires: []
  provides: [filterPrimaryActivity-state, filterExactActivity-state, applyFilters-activity-checks]
  affects: [UI/TabPlayers.lua]
tech_stack:
  added: []
  patterns: [nil-filter-AND-chain, forward-ref-locals]
key_files:
  created: []
  modified:
    - UI/TabPlayers.lua
decisions:
  - filterPrimaryActivity and filterExactActivity stored as nil-or-string-label locals, consistent with filterClass/filterSpec pattern
  - AND-chain filter checks use nil-guard (skip when nil) so no filter = show all
metrics:
  duration: "~2min"
  completed: "2026-03-25"
  tasks_completed: 2
  files_modified: 1
---

# Phase 05 Plan 01: Activity Filter State and applyFilters Extension Summary

Activity filter state variables and applyFilters AND-chain checks added to TabPlayers.lua — four new module-level locals plus two nil-guarded filter lines inside the entry loop.

## What Was Built

Extended `UI/TabPlayers.lua` with two activity filter state variables (`filterPrimaryActivity`, `filterExactActivity`), two forward-ref button locals (`primaryActivityFilterBtn`, `exactActivityFilterBtn`), and two new AND-chain filter checks inside the `TL.Refresh()` entry loop. The checks follow the exact same nil-guard pattern as the existing class/spec/status/level filters, so nil means no filter applied and a string label value means only matching entries pass.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add activity filter state variables and forward refs | 5365bde | UI/TabPlayers.lua |
| 2 | Extend applyFilters() with activity filter checks | bf11ee6 | UI/TabPlayers.lua |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check

- [x] `filterPrimaryActivity` declared at line 48 in UI/TabPlayers.lua
- [x] `filterExactActivity` declared at line 49 in UI/TabPlayers.lua
- [x] `primaryActivityFilterBtn` declared at line 50 in UI/TabPlayers.lua
- [x] `exactActivityFilterBtn` declared at line 51 in UI/TabPlayers.lua
- [x] Filter check for `filterPrimaryActivity` at line 460 inside the entry loop
- [x] Filter check for `filterExactActivity` at line 461 inside the entry loop
- [x] Both filter checks appear after `filterSpec` check and before `if ok then entries[#entries + 1] = e end`
- [x] grep -c returns 2 for filterPrimaryActivity, 2 for filterExactActivity
- [x] grep -c returns 1 for primaryActivityFilterBtn, 1 for exactActivityFilterBtn

## Self-Check: PASSED
