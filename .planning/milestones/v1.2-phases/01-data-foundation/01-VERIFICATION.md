---
phase: 01-data-foundation
verified: 2026-03-24T22:30:00Z
status: human_needed
score: 9/9 automated must-haves verified
human_verification:
  - test: "Load the addon in the WoW TBC Classic Anniversary client and run 13 in-game checks"
    expected: "No Lua error popup; /ow opens; OW.ACTIVITY.NORMAL_DUNGEON=1; OW.ACTIVITY.CHILL=7; #OW.ACTIVITY_LIST=7; #OW.ACTIVITY_SUBS['Normal Dungeon']=16; #OW.ACTIVITY_SUBS['Heroic Dungeon']=16; #OW.ACTIVITY_SUBS['Raid']=9; #OW.ACTIVITY_SUBS['PVP']=4; OW.ACTIVITY_SUBS['Quest'] not nil, length 0; OW.ACTIVITY.FAKE raises Lua error"
    why_human: "WoW addon Lua executes inside the WoW client sandbox. There is no way to execute or import the Lua module outside the client. All runtime behavior (namespace wiring, metatable guards, enum resolution) can only be confirmed in-game."
---

# Phase 01: Data Foundation Verification Report

**Phase Goal:** All TBC Classic Anniversary activity data exists as a queryable Lua module, ready for any other layer to import
**Verified:** 2026-03-24T22:30:00Z
**Status:** HUMAN_NEEDED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth                                                                              | Status     | Evidence                                                                 |
|----|------------------------------------------------------------------------------------|------------|--------------------------------------------------------------------------|
| 1  | OW.ACTIVITY enum exists with 7 keys mapping to sequential integers 1-7             | ✓ VERIFIED | Lines 11-22: NORMAL_DUNGEON=1 through CHILL=7                            |
| 2  | OW.ACTIVITY raises a Lua error on unknown key access and prevents mutation          | ✓ VERIFIED | Lines 20-21: __index and __newindex both call error()                    |
| 3  | OW.ACTIVITY_LIST is an ordered array of 7 {id, label} records in display order     | ✓ VERIFIED | Lines 28-36: 7 entries, first "Normal Dungeon", last "Chill"             |
| 4  | OW.ACTIVITY_SUBS has entries for all 7 activity labels                             | ✓ VERIFIED | Lines 42-116: all 7 keys present (Normal Dungeon, Heroic Dungeon, Raid, PVP, Quest, Farm, Chill) |
| 5  | OW.ACTIVITY_SUBS['Normal Dungeon'] contains 16 dungeon names                       | ✓ VERIFIED | Lines 44-65: 16 string entries (3+3+4+2+3+1)                            |
| 6  | OW.ACTIVITY_SUBS['Heroic Dungeon'] contains 16 dungeon names                       | ✓ VERIFIED | Lines 68-89: identical 16 entries                                        |
| 7  | OW.ACTIVITY_SUBS['Raid'] contains 9 raid names                                     | ✓ VERIFIED | Lines 92-105: 9 entries (3+2+2+1+1)                                     |
| 8  | OW.ACTIVITY_SUBS['PVP'] contains 4 battleground names                              | ✓ VERIFIED | Lines 108-111: Warsong Gulch, Arathi Basin, Alterac Valley, Eye of the Storm |
| 9  | OW.ACTIVITY_SUBS['Quest'], ['Farm'], ['Chill'] each return empty table {}          | ✓ VERIFIED | Lines 113-115: `["Quest"] = {}`, `["Farm"] = {}`, `["Chill"] = {}`      |

**Score:** 9/9 truths verified (automated)

---

### Required Artifacts

| Artifact               | Expected                                       | Status     | Details                                                           |
|------------------------|------------------------------------------------|------------|-------------------------------------------------------------------|
| `Data/Activities.lua`  | Activity enum, ordered list, sub-type tables   | ✓ VERIFIED | 116 lines; all three data structures present and fully populated  |
| `OnlineWhen.toc`       | Load-order registration for Data/Activities.lua | ✓ VERIFIED | Line 10: `Data/Activities.lua` between Timezones.lua and Core/Status.lua |

---

### Key Link Verification

| From                  | To                    | Via                          | Status     | Details                                                                 |
|-----------------------|-----------------------|------------------------------|------------|-------------------------------------------------------------------------|
| `Data/Activities.lua` | OW namespace          | `local addonName, OW = ...`  | ✓ VERIFIED | Line 5: exact pattern present; legacy `OW = OW or {}` absent           |
| `OnlineWhen.toc`      | `Data/Activities.lua` | TOC file-list entry          | ✓ VERIFIED | Line 10: `Data/Activities.lua`; confirmed between Timezones and Status  |

---

### Data-Flow Trace (Level 4)

Not applicable. `Data/Activities.lua` is a pure static data module — no dynamic data, no fetch calls, no DB queries. The file defines tables at module load time. All values are literal constants hardcoded correctly. There is no runtime data pipeline to trace.

---

### Behavioral Spot-Checks

Step 7b is SKIPPED for automated checks. This is a WoW addon Lua module — it cannot be executed outside the WoW client sandbox. Runtime behavior is routed to human verification below.

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                                    | Status      | Evidence                                                             |
|-------------|-------------|--------------------------------------------------------------------------------|-------------|----------------------------------------------------------------------|
| DATA-01     | 01-01, 01-02 | `Data/Activities.lua` defines 7 primary activities                            | ✓ SATISFIED | File exists; 7 keys in OW.ACTIVITY enum; 7 entries in OW.ACTIVITY_LIST; TOC registered |
| DATA-02     | 01-01       | All TBC Classic Anniversary dungeons listed as sub-options for Normal and Heroic Dungeon | ✓ SATISFIED | Lines 43-89: 16 dungeons in each of Normal Dungeon and Heroic Dungeon — all TBC dungeons present |
| DATA-03     | 01-01       | All TBC Classic Anniversary raids listed as sub-options for Raid               | ✓ SATISFIED | Lines 91-106: 9 raids across all phases (Karazhan through Sunwell Plateau) |
| DATA-04     | 01-01       | All TBC Anniversary Classic battlegrounds listed as sub-options for PVP        | ✓ SATISFIED | Lines 107-112: 4 battlegrounds (Warsong Gulch, Arathi Basin, Alterac Valley, Eye of the Storm) |
| DATA-05     | 01-01       | Activities with no sub-types (Quest, Farm, Chill) have an empty sub-type list | ✓ SATISFIED | Lines 113-115: all three map to `{}`, not nil                       |

All 5 requirements satisfied. No orphaned requirements — REQUIREMENTS.md traceability table maps exactly DATA-01 through DATA-05 to Phase 1, all accounted for by plans 01-01 and 01-02.

---

### Anti-Patterns Found

| File                  | Line | Pattern                | Severity | Impact  |
|-----------------------|------|------------------------|----------|---------|
| `Data/Activities.lua` | —    | None detected          | —        | None    |

Checks performed:
- No `TODO`, `FIXME`, `XXX`, `HACK`, or `PLACEHOLDER` comments
- No `return null`, `return {}`, or empty handler patterns (file is pure data, no functions)
- No `OW = OW or {}` legacy guard (confirmed absent)
- No WoW API calls (`C_*`, `GetSpellInfo`, `CreateFrame`) — confirmed absent; the grep match for `C_` was the substring inside `HEROIC_DUNGEON`, not an API call
- No hardcoded empty state variables that feed rendering (pure static data file, no rendering)

---

### Human Verification Required

#### 1. In-Game Runtime Verification

**Test:** Launch the WoW TBC Classic Anniversary client (or `/reload` UI). Run the following checks in sequence:

1. Confirm no red Lua error popup appears on login
2. Type `/ow` — the OnlineWhen window should open normally without errors
3. `/run print(OW.ACTIVITY.NORMAL_DUNGEON)` — expected: `1`
4. `/run print(OW.ACTIVITY.CHILL)` — expected: `7`
5. `/run print(#OW.ACTIVITY_LIST)` — expected: `7`
6. `/run print(#OW.ACTIVITY_SUBS["Normal Dungeon"])` — expected: `16`
7. `/run print(#OW.ACTIVITY_SUBS["Heroic Dungeon"])` — expected: `16`
8. `/run print(#OW.ACTIVITY_SUBS["Raid"])` — expected: `9`
9. `/run print(#OW.ACTIVITY_SUBS["PVP"])` — expected: `4`
10. `/run print(OW.ACTIVITY_SUBS["Quest"] ~= nil)` — expected: `true`
11. `/run print(#OW.ACTIVITY_SUBS["Quest"])` — expected: `0`
12. `/run print(OW.ACTIVITY.FAKE)` — expected: Lua error containing `OW.ACTIVITY: unknown key: FAKE`

**Expected:** All 12 checks pass with the values above.

**Why human:** WoW addon Lua executes inside the WoW client sandbox. The module cannot be imported or run outside that environment. Static analysis confirms the code is correct, but actual namespace wiring (`local addonName, OW = ...` receiving the real OW table from the WoW addon system), metatable guard behavior, and enum key resolution at runtime can only be confirmed in-game.

---

### Gaps Summary

No automated gaps. All 9 observable truths verified. All 5 requirements satisfied. All artifacts exist and are substantive and wired. The only open item is the in-game runtime check (Plan 02 Task 2), which was flagged as a human-verify checkpoint in the plan and auto-approved pending user confirmation.

The code is correct by static analysis. Human verification is a gate before this phase can be considered fully closed.

---

_Verified: 2026-03-24T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
