---
status: approved
phase: 05-player-list-filters
source: [05-VERIFICATION.md]
started: 2026-03-25T00:00:00Z
updated: 2026-03-25T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Second Filter Row Visual Layout

expected: Two distinct filter rows visible — row 1 with Status/Level/Class/Spec dropdowns, row 2 with "Any Activity" and a greyed-out "Any Exact Activity" dropdown below it. Column headers and player rows appear below row 2 with no overlap.
result: [pending]

### 2. Primary Activity Cascade — Sub-type Activities

expected: Click "Any Activity" dropdown, select "Normal Dungeon". The "Any Exact Activity" dropdown becomes enabled (not greyed out) and its menu contains "Any Exact Activity" plus all 16 TBC dungeon names.
result: [pending]

### 3. Primary Activity Cascade — No Sub-type Activities

expected: With "Normal Dungeon" selected in primary, switch to "Quest". Exact activity dropdown returns to greyed-out/disabled state and its label resets to "Any Exact Activity".
result: [pending]

### 4. Filter Application

expected: With at least two players visible (different activities), select "Raid" in the primary filter. Only players with primaryActivity == "Raid" remain visible; others disappear. Pagination and counts update correctly.
result: [pending]

### 5. Reset Filters

expected: Set both a primary and exact activity filter (e.g., Raid → Karazhan). Click "Reset Filters". Both dropdowns return to "Any Activity"/"Any Exact Activity" defaults, exact dropdown disables, full player list reappears.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
