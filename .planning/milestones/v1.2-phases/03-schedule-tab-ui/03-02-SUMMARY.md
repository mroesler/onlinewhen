---
phase: 03-schedule-tab-ui
plan: "02"
subsystem: UI
tags: [schedule-tab, activity, validation, save, reset, populate]
dependency_graph:
  requires: [03-01]
  provides: [activity-save-validation, activity-reset, activity-populate]
  affects: [UI/TabSchedule.lua]
tech_stack:
  added: []
  patterns: [guard pattern (validate then pass to SaveMyEntry), upvalue nil reset on clear, show/hide replicated in Populate (SetValue does not trigger onChange)]
key_files:
  created: []
  modified:
    - UI/TabSchedule.lua
decisions:
  - "exactActivity declared local in onSave scope — available at SaveMyEntry call site without module-scope upvalue"
  - "TI.Populate replicates onChange show/hide logic — SetValue alone does not fire onChange handler"
  - "selectedActivity = nil in TI.Reset — ClearValue only clears widget state, not the module-scope upvalue"
metrics:
  duration: "~51 seconds"
  completed: "2026-03-25"
  tasks_completed: 2
  files_modified: 1
---

# Phase 3 Plan 02: Activity Lifecycle Wiring Summary

**One-liner:** Activity validation guard added to onSave (blocks without primary selection), SaveMyEntry extended to 8 args, TI.Reset clears both dropdowns and hides exact row, TI.Populate restores both fields with correct show/hide.

## What Was Built

- `UI/TabSchedule.lua` `onSave()`: Activity guard inserted after spec guard — reads `ddActivity:GetValue()` into `selectedActivity`, blocks with `showError("Select an activity.")` if nil, then reads optional `exactActivity` from `ddExactActivity`
- `UI/TabSchedule.lua` `onSave()`: `OnlineWhen.SaveMyEntry` call extended from 6 to 8 args — appends `selectedActivity` and `exactActivity`
- `UI/TabSchedule.lua` `TI.Reset()`: Activity cleanup block — `ddActivity:ClearValue()`, `ddExactActivity:ClearValue()`, `lblExactActivity:Hide()`, `ddExactActivity:Hide()`, `selectedActivity = nil`
- `UI/TabSchedule.lua` `TI.Populate()`: Activity restore block — reads `my.primaryActivity` and `my.exactActivity` from `OW.GetMyEntry()`, sets primary dropdown, updates `selectedActivity` upvalue, replicates onChange show/hide logic for exact row

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 90ae2a0 | feat(03-02): wire activity validation in onSave and extend SaveMyEntry to 8 args |
| Task 2 | c2a0ed8 | feat(03-02): wire TI.Reset and TI.Populate for activity fields |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The activity system is fully wired: save validates and passes activity to database, reset clears UI and upvalue state, populate restores from saved entry with correct conditional exact-row visibility.

## Self-Check: PASSED

- UI/TabSchedule.lua: FOUND
- Commit 90ae2a0: FOUND (feat(03-02): wire activity validation in onSave and extend SaveMyEntry to 8 args)
- Commit c2a0ed8: FOUND (feat(03-02): wire TI.Reset and TI.Populate for activity fields)
