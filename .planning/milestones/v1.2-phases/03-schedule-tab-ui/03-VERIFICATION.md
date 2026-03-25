---
phase: 03-schedule-tab-ui
verified: 2026-03-25T00:00:00Z
status: passed
score: 10/10 must-haves verified
gaps: []
human_verification:
  - test: "Open Schedule tab — confirm Activity group box renders below Date & Time group"
    expected: "Three labeled group boxes visible: Character, Date & Time, Activity"
    why_human: "Visual layout cannot be verified by code inspection alone"
  - test: "Select Normal Dungeon — confirm exact dropdown appears with dungeon list"
    expected: "Specific Activity row becomes visible; dropdown shows TBC dungeons"
    why_human: "UIDropDownMenu show/hide behavior requires in-client render verification"
  - test: "Select Quest — confirm exact dropdown hides"
    expected: "Specific Activity label and dropdown are hidden"
    why_human: "Hide/show conditional requires live WoW frame evaluation"
  - test: "Click Save without selecting activity — confirm error flash"
    expected: "Save button flashes 'Select an activity.' for 2.5s then reverts"
    why_human: "Timer + text flash requires in-client execution"
  - test: "Full save/reset/populate cycle"
    expected: "After save with Raid + Karazhan, form resets (both activity fields cleared), re-open restores Raid + Karazhan with exact row visible"
    why_human: "Full lifecycle requires in-client session state"
---

# Phase 3: Schedule Tab UI Verification Report

**Phase Goal:** Players can select an activity when scheduling — primary activity is required and blocks Save when unset; exact-activity dropdown appears only for activities that have sub-types
**Verified:** 2026-03-25
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Window is 680px tall (160px taller than before) | VERIFIED | `UI/Window.lua:8` — `local WINDOW_H  = 680` |
| 2 | Activity group box is visible below Date & Time in Schedule tab | VERIFIED | `UI/TabSchedule.lua:508` — `makeGroupBox(parent, "Activity", ...)` anchored at `dateTimeGroupY - dateTimeGroupHeight - 8` |
| 3 | Primary activity dropdown shows 7 activities from OW.ACTIVITY_LIST | VERIFIED | `activityItems()` iterates `ipairs(OW.ACTIVITY_LIST)` (7 entries confirmed in Data/Activities.lua); `OWDdActivity` created with this list |
| 4 | Exact-activity row is hidden on first open | VERIFIED | `UI/TabSchedule.lua:543-544` — `lblExactActivity:Hide()` and `ddExactActivity:Hide()` called immediately after creation |
| 5 | Save is blocked with "Select an activity." when no primary selected | VERIFIED | `UI/TabSchedule.lua:259-260` — guard reads `ddActivity:GetValue()` into `selectedActivity`; `if not selectedActivity then showError("Select an activity.") return end` |
| 6 | Save passes activity fields to OW.SaveMyEntry as args 7 and 8 | VERIFIED | `UI/TabSchedule.lua:279-280` — `OnlineWhen.SaveMyEntry(name, selectedSpec, myClass, level, utcTs, selectedTzId, selectedActivity, exactActivity)` |
| 7 | TI.Reset() clears both activity dropdowns and hides exact-activity row | VERIFIED | `UI/TabSchedule.lua:317-321` — `ddActivity:ClearValue()`, `ddExactActivity:ClearValue()`, `lblExactActivity:Hide()`, `ddExactActivity:Hide()`, `selectedActivity = nil` |
| 8 | TI.Populate() restores primaryActivity and exactActivity from myEntry | VERIFIED | `UI/TabSchedule.lua:577-590` — reads `my.primaryActivity`, calls `ddActivity:SetValue()`, updates `selectedActivity` upvalue, replicates show/hide logic for exact row |
| 9 | Selecting activities with sub-types (Normal Dungeon, Heroic Dungeon, Raid, PVP) shows exact dropdown | VERIFIED | `UI/TabSchedule.lua:521-525` — onChange: `if #subs > 0 then ClearValue(); SetItems(...); Show()` |
| 10 | Selecting activities without sub-types (Quest, Farm, Chill) hides exact dropdown | VERIFIED | `UI/TabSchedule.lua:526-530` — onChange: `else ClearValue(); Hide()` |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `UI/Window.lua` | Increased WINDOW_H | VERIFIED | Line 8: `local WINDOW_H  = 680` |
| `UI/TabSchedule.lua` | Activity group box with primary dropdown | VERIFIED | 591 lines; contains full Group 3 implementation, all lifecycle hooks |
| `UI/TabSchedule.lua` | onSave activity validation and 8-arg SaveMyEntry call | VERIFIED | Lines 259-280: guard + extended call |
| `UI/TabSchedule.lua` | TI.Reset activity cleanup | VERIFIED | Lines 316-321: full cleanup block |
| `UI/TabSchedule.lua` | TI.Populate activity restore | VERIFIED | Lines 576-590: full restore block with show/hide |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `UI/TabSchedule.lua` | `OW.ACTIVITY_LIST` | `activityItems()` iterates `ipairs(OW.ACTIVITY_LIST)` | WIRED | Line 227: `for _, act in ipairs(OW.ACTIVITY_LIST)` |
| `UI/TabSchedule.lua` | `UI/Window.lua` | `contentAreaHeight` derived from WINDOW_H | WIRED | Line 391: `contentAreaHeight = 632` (= 680 - 32 - 6 - 6 - 4) |
| `UI/TabSchedule.lua onSave()` | `OW.SaveMyEntry` | 8-arg call with primaryActivity, exactActivity | WIRED | Lines 279-280: full 8-arg call confirmed |
| `UI/TabSchedule.lua TI.Populate()` | `OW.GetMyEntry()` | reads `my.primaryActivity`, `my.exactActivity` | WIRED | Lines 577, 578, 583: both fields read |
| `UI/TabSchedule.lua TI.Reset()` | `ddActivity`, `ddExactActivity` | ClearValue + Hide | WIRED | Lines 317-320: all four operations present |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `ddActivity` dropdown | `OW.ACTIVITY_LIST` items | `Data/Activities.lua` — 7 hardcoded activity entries | Yes (static lookup data, not DB-backed — correct for this use case) | FLOWING |
| `ddExactActivity` dropdown | `OW.ACTIVITY_SUBS[label]` items | `Data/Activities.lua` — populated arrays for Normal Dungeon (16), Heroic Dungeon (16), Raid (9), PVP (4); empty for Quest/Farm/Chill | Yes | FLOWING |
| `onSave()` activity args | `selectedActivity`, `exactActivity` | `ddActivity:GetValue()` and `ddExactActivity:GetValue()` — live dropdown state | Yes (passes through to SaveMyEntry) | FLOWING |
| `TI.Populate()` restore | `my.primaryActivity`, `my.exactActivity` | `OnlineWhen.GetMyEntry()` — reads `OnlineWhenDB.myEntry` (written by SaveMyEntry in Phase 2) | Yes (stored by Phase 2 database layer) | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — addon Lua files require the WoW client runtime. No standalone runnable entry points exist for automated behavioral testing. Human verification items cover these behaviors.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SCHED-01 | 03-01 | Activity section appears at bottom of Schedule tab inside a labeled group box | SATISFIED | `makeGroupBox(parent, "Activity", ...)` at line 508, positioned below Date & Time group |
| SCHED-02 | 03-01 | Primary activity dropdown shows all 7 activities | SATISFIED | `activityItems()` iterates `OW.ACTIVITY_LIST` (7 entries); `OWDdActivity` initialized with this list |
| SCHED-03 | 03-02 | Selecting Normal Dungeon, Heroic Dungeon, Raid, or PVP reveals a second dependent dropdown | SATISFIED | onChange handler: `if #subs > 0 then ... Show()` — all four of these activities have non-empty `OW.ACTIVITY_SUBS` arrays |
| SCHED-04 | 03-02 | Selecting Quest, Farm, or Chill hides the exact activity dropdown | SATISFIED | onChange handler: `else ... Hide()` — Quest/Farm/Chill have empty `OW.ACTIVITY_SUBS` arrays |
| SCHED-05 | 03-02 | Activity is required — Save blocked with error if no primary activity selected | SATISFIED | Lines 259-260: guard with `showError("Select an activity.") return` |
| SCHED-06 | 03-02 | Activity fields cleared/reset when form is reset (TI.Reset()) | SATISFIED | Lines 316-321: full cleanup block with both dropdowns cleared, row hidden, upvalue nilled |
| SCHED-07 | 03-02 | Activity fields restored when form populated from existing entry (TI.Populate()) | SATISFIED | Lines 576-590: full restore block with primary + exact fields, correct show/hide |
| SCHED-08 | 03-01 | Main window height increased to accommodate new activity section | SATISFIED | `UI/Window.lua:8` — `WINDOW_H = 680` (was 520); `contentAreaHeight = 632` derived correctly |

All 8 SCHED requirements satisfied. No orphaned requirements detected (all SCHED-01 through SCHED-08 appear in plan frontmatter and are accounted for).

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `UI/TabSchedule.lua` | 107, 112, 141, 158 | `placeholder` keyword | Info | Internal `makeDropdown` implementation parameter name — not a stub; this is the dropdown's "— Select —" text parameter. Not load-bearing for goal. |

No blockers or warnings found. The placeholder matches are the dropdown factory's `placeholder` parameter (the visual "— Select —" text shown before user picks a value), which is correct behavior, not a stub.

**ClearValue-before-SetItems ordering confirmed:** Line 522 calls `ddExactActivity:ClearValue()` before line 523 calls `ddExactActivity:SetItems(...)` in the onChange handler — the anti-pattern pitfall documented in the plan is correctly avoided.

**selectedActivity upvalue reset confirmed:** Line 321 `selectedActivity = nil` is present in TI.Reset() — the upvalue is not left stale.

---

### Human Verification Required

#### 1. Activity Group Box Visual Layout

**Test:** Open the addon in WoW client, open the Schedule tab
**Expected:** Three labeled group boxes visible stacked vertically — Character, Date & Time, Activity — with the Activity group at the bottom above the Save button
**Why human:** Frame anchor calculations and pixel geometry require live WoW rendering to verify visual correctness

#### 2. Exact Dropdown Conditional Show/Hide

**Test:** In the Schedule tab, select "Normal Dungeon" from the primary Activity dropdown
**Expected:** "Specific Activity" label and a second dropdown appear below the primary dropdown, populated with TBC dungeon names (Hellfire Ramparts, etc.)
**Why human:** UIDropDownMenu:Show()/Hide() behavior requires in-client frame evaluation; cannot be verified by static code inspection

#### 3. Quest/Farm/Chill Hides Exact Dropdown

**Test:** Select "Quest" (or "Farm" or "Chill") from the primary Activity dropdown
**Expected:** The Specific Activity row is hidden (not disabled) — completely absent from view
**Why human:** Same as above

#### 4. Save Blocked Without Activity — Error Flash

**Test:** Fill all fields except Activity, click Save
**Expected:** Save button text changes to red "Select an activity." for 2.5 seconds then reverts to "Save"
**Why human:** C_Timer.After() execution and text color flash require live client runtime

#### 5. Full Save/Reset/Populate Lifecycle

**Test:** Select Raid + Karazhan, fill remaining fields, click Save. Observe form reset, then re-open Schedule tab.
**Expected:** After save: form resets (both activity dropdowns cleared, Specific Activity row hidden). After re-open: primary shows "Raid", Specific Activity row visible with "Karazhan" selected.
**Why human:** Requires in-client session with OnlineWhenDB persistence across TI.Reset() and TI.Populate() calls

---

### Gaps Summary

No gaps. All 10 observable truths verified at all levels (exists, substantive, wired, data-flowing). All 8 SCHED requirements satisfied. All 4 phase commits confirmed present in git history (330ad90, 6f584e4, 90ae2a0, c2a0ed8). No blocker anti-patterns found.

The only outstanding items are 5 human verification tests that require the WoW client runtime — these are standard for a WoW addon UI phase and do not indicate code defects.

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_
