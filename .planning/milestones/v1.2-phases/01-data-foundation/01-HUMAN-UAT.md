---
status: partial
phase: 01-data-foundation
source: [01-VERIFICATION.md]
started: 2026-03-24T00:00:00Z
updated: 2026-03-24T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Addon loads without Lua errors
expected: No red Lua error popup appears when logging in or running `/reload`
result: passed

### 2. /ow command works
expected: `/ow` opens the OnlineWhen window normally without errors
result: passed

### 3. OW.ACTIVITY.NORMAL_DUNGEON = 1
expected: `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` prints `1`
result: [pending]

### 4. OW.ACTIVITY.CHILL = 7
expected: `/run print(OW.ACTIVITY.CHILL)` prints `7`
result: [pending]

### 5. OW.ACTIVITY_LIST has 7 entries
expected: `/run print(#OW.ACTIVITY_LIST)` prints `7`
result: [pending]

### 6. Normal Dungeon sub-type list has 16 entries
expected: `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` prints `16`
result: [pending]

### 7. Heroic Dungeon sub-type list has 16 entries
expected: `/run print(#OW.ACTIVITY_SUBS["Heroic Dungeon"])` prints `16`
result: [pending]

### 8. Raid sub-type list has 9 entries
expected: `/run print(#OW.ACTIVITY_SUBS["Raid"])` prints `9`
result: [pending]

### 9. PVP sub-type list has 4 entries
expected: `/run print(#OW.ACTIVITY_SUBS["PVP"])` prints `4`
result: [pending]

### 10. Quest sub-type list is not nil
expected: `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` prints `true`
result: [pending]

### 11. Quest sub-type list is empty
expected: `/run print(#OW.ACTIVITY_SUBS["Quest"])` prints `0`
result: [pending]

### 12. Unknown key raises Lua error
expected: `/run print(OW.ACTIVITY.FAKE)` produces a Lua error containing "OW.ACTIVITY: unknown key: FAKE"
result: [pending]

## Summary

total: 12
passed: 2
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps
