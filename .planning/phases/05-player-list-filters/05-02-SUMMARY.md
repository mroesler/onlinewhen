---
phase: 05-player-list-filters
plan: "02"
subsystem: UI/TabPlayers
tags: [filters, activity, lua, player-list, layout]
dependency_graph:
  requires: [05-01]
  provides: [primaryActivityFilterBtn-widget, exactActivityFilterBtn-widget, filterBar2Y-layout, columnHeaderY-two-row]
  affects: [UI/TabPlayers.lua]
tech_stack:
  added: []
  patterns: [makeDropdown-factory, two-row-filter-bar, OW.ACTIVITY_LIST-loop]
key_files:
  created: []
  modified:
    - UI/TabPlayers.lua
decisions:
  - columnHeaderY expanded to -80 (two FILTER_H + two FILTER_BOT_PAD) to accommodate second filter row
  - filterBar2Y = -47 uses same vertical centering formula as filterBarY for row 2
  - primaryActivityChoices built with value=act.label (string) consistent with filter comparison against entry.primaryActivity label string
  - exactActivityFilterBtn starts disabled (setActive(false)) per FILT-03; cascade wiring deferred to Plan 05-03
  - X-offset 190 for exactActivityFilterBtn = 180 (primary width) + 10 (gap)
metrics:
  duration: "~3min"
  completed: "2026-03-25"
  tasks_completed: 2
  files_modified: 1
---

# Phase 05 Plan 02: Second Filter Row UI Summary

Second filter row added to TabPlayers.lua with primary activity dropdown (180px, 8 choices from OW.ACTIVITY_LIST) and exact activity dropdown (220px, disabled by default), with columnHeaderY expanded to -80 to push column headers down for both filter rows.

## What Was Built

Extended `UI/TabPlayers.lua` with:

1. **Layout adjustment**: `columnHeaderY` changed from -44 to -80 (adding one FILTER_H + FILTER_BOT_PAD for the second row). New `filterBar2Y = -47` provides the vertical center position for row 2 buttons using the same centering formula as row 1.

2. **Primary activity dropdown**: 180px wide, choices built dynamically from `OW.ACTIVITY_LIST` loop starting with "Any Activity" (value=nil). onChange clears `filterExactActivity` and calls `TL.Refresh()`.

3. **Exact activity dropdown**: 220px wide, starts disabled (`setActive(false)`) with "Any Exact Activity" placeholder. Positioned at x=190 (180 + 10 gap). Cascade wiring (enabling on primary selection) is deferred to Plan 05-03.

Column headers, divider, and contentFrame all anchor from `columnHeaderY` and shift down automatically with no additional changes needed.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Adjust layout constants for second filter row | 57886de | UI/TabPlayers.lua |
| 2 | Build primary and exact activity filter dropdowns on row 2 | c7fa272 | UI/TabPlayers.lua |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check

- [x] `local columnHeaderY = -(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD + FILTER_H + FILTER_BOT_PAD)` at line 528
- [x] `local filterBar2Y = -(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD + math.floor((FILTER_H - 22) / 2))` at line 532
- [x] `primaryActivityFilterBtn = makeDropdown(parent, 180, "Any Activity"` at line 612
- [x] `exactActivityFilterBtn = makeDropdown(parent, 220, "Any Exact Activity"` at line 620
- [x] `exactActivityFilterBtn.setActive(false)` at line 626
- [x] primaryActivityFilterBtn anchored at `0, filterBar2Y` (line 618)
- [x] exactActivityFilterBtn anchored at `190, filterBar2Y` (line 625)
- [x] primaryActivityChoices built from OW.ACTIVITY_LIST loop with value=act.label
- [x] primaryActivityChoices starts with `{ label = "Any Activity", value = nil }`
- [x] grep -c returns 3 for primaryActivityFilterBtn
- [x] grep -c returns 4 for exactActivityFilterBtn
- [x] grep -c returns 3 for filterBar2Y
- [x] columnHeaderY shows expanded formula with two FILTER_H terms

## Self-Check: PASSED
