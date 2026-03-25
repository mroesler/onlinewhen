---
phase: 03-schedule-tab-ui
plan: "01"
subsystem: UI
tags: [schedule-tab, activity, dropdown, window-layout]
dependency_graph:
  requires: []
  provides: [activity-group-box, primary-activity-dropdown, exact-activity-placeholder]
  affects: [UI/Window.lua, UI/TabSchedule.lua]
tech_stack:
  added: []
  patterns: [UIDropDownMenuTemplate cascade pattern (ClearValue before SetItems), group-box hide/show for conditional rows]
key_files:
  created: []
  modified:
    - UI/Window.lua
    - UI/TabSchedule.lua
decisions:
  - "value=act.label (not act.id) for primary dropdown — OW.ACTIVITY_SUBS is keyed by label string"
  - "ClearValue() called before SetItems() in onChange handler — prevents stale selection when switching between activities with sub-types"
  - "Group 3 (Activity) height fixed at 152px regardless of exact-row visibility (D-01)"
  - "Exact row hidden (not disabled) for Quest/Farm/Chill (D-03)"
metrics:
  duration: "~1 minute"
  completed: "2026-03-24"
  tasks_completed: 2
  files_modified: 2
---

# Phase 3 Plan 01: Window Height + Activity Group Box Summary

**One-liner:** Window expanded to 680px and Activity group box added with primary dropdown (7 activities from OW.ACTIVITY_LIST) and hidden exact-activity row placeholder.

## What Was Built

- `UI/Window.lua`: `WINDOW_H` changed from 520 to 680 (adds 160px for Activity group + gap)
- `UI/TabSchedule.lua`: `contentAreaHeight` changed from 472 to 632; comment updated to document revised derivation including Activity group in bottom space budget
- `UI/TabSchedule.lua`: Three new module-scope upvalues — `ddActivity`, `ddExactActivity`, `lblExactActivity`, `selectedActivity`
- `UI/TabSchedule.lua`: Two new item builder functions — `activityItems()` iterating `OW.ACTIVITY_LIST`, `exactItemsForActivity()` using `OW.ACTIVITY_SUBS`
- `UI/TabSchedule.lua`: Group 3 (Activity) built in `TI.Build()` — 152px fixed height, positioned below Group 2 with 8px gap
- Primary dropdown `OWDdActivity`: 7 items in order from `OW.ACTIVITY_LIST`, placeholder "— Select —", onChange cascade that shows/hides exact row
- Exact-activity dropdown `OWDdExactActivity` and label `lblExactActivity`: created hidden, shown only when selected activity has sub-types

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 330ad90 | feat(03-01): increase WINDOW_H to 680 and contentAreaHeight to 632 |
| Task 2 | 6f584e4 | feat(03-01): add Activity group box with primary and exact-activity dropdowns |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

- `ddExactActivity` and `lblExactActivity` exist and are hidden by default; they will be wired to save/reset/populate in Plan 02. This is intentional per the plan's design (Plan 01 creates the visual container, Plan 02 wires the logic).
- `selectedActivity` is set in the onChange handler but not yet read by `onSave()` — Plan 02 will add activity validation to the save flow.

## Self-Check: PASSED

- UI/Window.lua: FOUND
- UI/TabSchedule.lua: FOUND
- Commit 330ad90: FOUND
- Commit 6f584e4: FOUND
