---
status: partial
phase: 03-schedule-tab-ui
source: [03-VERIFICATION.md]
started: 2026-03-24T23:45:06Z
updated: 2026-03-24T23:45:06Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Visual layout — three group boxes render correctly
expected: Schedule tab shows Character, Date & Time, and Activity group boxes stacked vertically; Activity group is fully visible without clipping; window is visibly taller than before (680px)
result: [pending]

### 2. Exact dropdown shows for sub-type activities
expected: Selecting "Normal Dungeon" from the primary dropdown causes the "Specific Activity" label and dropdown to appear, populated with the TBC dungeon list
result: [pending]

### 3. Exact dropdown hides for non-sub-type activities
expected: Selecting "Quest" (or "Farm" or "Chill") causes the "Specific Activity" row to disappear
result: [pending]

### 4. Save error flash when no activity selected
expected: Clicking Save without selecting a primary activity causes a "Select an activity." error message to flash on the Save button for ~2.5 seconds, then revert — no entry is saved
result: [pending]

### 5. Full save/reset/populate lifecycle
expected: Select "Raid" + "Karazhan" (or any dungeon), fill other required fields, Save — entry saves; form resets (both activity dropdowns cleared, exact row hidden); re-open Schedule tab restores "Raid" in primary dropdown and "Karazhan" in exact dropdown with row visible
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
