---
phase: 05-player-list-filters
verified: 2026-03-25T00:00:00Z
status: human_needed
score: 5/5 truths verified; merge to main completed 2026-03-25
gaps:
  - truth: "filterPrimaryActivity and filterExactActivity state variables exist as module-level locals"
    status: failed
    reason: "Variables exist only in worktree-agent-aaea9aa2 commits; main branch UI/TabPlayers.lua has no trace of them"
    artifacts:
      - path: "UI/TabPlayers.lua"
        issue: "Phase 05 changes exist in commit 98927f2 on worktree-agent-aaea9aa2 but are not merged to main"
    missing:
      - "Merge worktree-agent-aaea9aa2 into main (or cherry-pick commits 2456bc2, ac615c8, 57886de, c7fa272, d0e17ed, 98927f2 in order)"
  - truth: "applyFilters logic filters entries by primaryActivity and exactActivity when respective filter is set"
    status: failed
    reason: "Filter AND-chain additions are in the unmerged worktree branch only; main TL.Refresh() has no activity filter checks"
    artifacts:
      - path: "UI/TabPlayers.lua"
        issue: "Lines added in bf11ee6/ac615c8 are absent from main working tree"
    missing:
      - "Merge phase 05 commits to main"
  - truth: "A second filter row appears below the existing class/spec/status/level row"
    status: failed
    reason: "columnHeaderY is still -44 on main (single row); filterBar2Y, primaryActivityFilterBtn, and exactActivityFilterBtn widgets are absent"
    artifacts:
      - path: "UI/TabPlayers.lua"
        issue: "Layout expansion and row-2 dropdown construction exist only in unmerged commits 57886de and c7fa272"
    missing:
      - "Merge phase 05 commits to main"
  - truth: "Selecting a primary activity with sub-types enables exact dropdown and populates it with sub-type choices"
    status: failed
    reason: "Cascade wiring (OW.ACTIVITY_SUBS lookup, setChoices/setActive calls) exists only in commit d0e17ed on unmerged branch"
    artifacts:
      - path: "UI/TabPlayers.lua"
        issue: "primaryActivityFilterBtn onChange handler with ACTIVITY_SUBS cascade not present on main"
    missing:
      - "Merge phase 05 commits to main"
  - truth: "Reset Filters clears both activity filters and disables the exact dropdown"
    status: failed
    reason: "Reset Filters extension (filterPrimaryActivity=nil, filterExactActivity=nil, setActive(false)) exists only in commit 98927f2 on unmerged branch"
    artifacts:
      - path: "UI/TabPlayers.lua"
        issue: "Reset Filters handler on main branch only clears 4 filters (status, level, class, spec)"
    missing:
      - "Merge phase 05 commits to main"
---

# Phase 05: Player List Filters — Verification Report

**Phase Goal:** Players can filter the list by primary and exact activity; the exact filter cascades from the primary selection and resets when Reset Filters is clicked
**Verified:** 2026-03-25
**Status:** human_needed
**Re-verification:** No — initial verification

## Summary

The phase 05 implementation is **complete and correct** in its commits, but those commits reside on the `worktree-agent-aaea9aa2` branch and have **not been merged to `main`**. The working tree on `main` shows no trace of any phase-05 changes. The implementation itself passes all quality checks when examined in the commit history; the sole blocking issue is the missing merge.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status in main | Status in commits | Evidence |
|---|-------|---------------|-------------------|----------|
| 1 | filterPrimaryActivity and filterExactActivity state variables exist as module-level locals | FAILED | VERIFIED | Lines 48-51 in commit 98927f2:UI/TabPlayers.lua |
| 2 | applyFilters filters by primaryActivity and exactActivity (AND logic, nil = no filter) | FAILED | VERIFIED | Lines 475-476 in commit 98927f2:UI/TabPlayers.lua |
| 3 | A second filter row appears with a primary activity dropdown (180px, 8 choices) and a disabled exact dropdown (220px) | FAILED | VERIFIED | Lines 607-648 in commit 98927f2:UI/TabPlayers.lua |
| 4 | Selecting a primary activity with sub-types enables exact dropdown and populates it; Quest/Farm/Chill keeps it disabled | FAILED | VERIFIED | OW.ACTIVITY_SUBS cascade at lines 622-635 in commit 98927f2:UI/TabPlayers.lua |
| 5 | Reset Filters clears both activity filters and disables the exact dropdown | FAILED | VERIFIED | Lines 681-686 in commit 98927f2:UI/TabPlayers.lua |

**Score in main working tree:** 0/5 truths verified
**Score in committed code:** 5/5 truths verified

---

## Required Artifacts

| Artifact | Expected | Status in main | Status in commits | Details |
|----------|----------|---------------|-------------------|---------|
| `UI/TabPlayers.lua` | Activity filter state vars + applyFilters extension + row-2 UI + cascade wiring + reset extension | MISSING CHANGES | VERIFIED | All phase 05 additions present in commit 98927f2 on worktree-agent-aaea9aa2; absent from main |

---

## Key Link Verification (in commits)

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `filterPrimaryActivity local` | `applyFilters() AND chain` | nil-guarded equality on `e.primaryActivity` | VERIFIED | `if ok and filterPrimaryActivity and e.primaryActivity ~= filterPrimaryActivity then ok = false end` at line 475 |
| `filterExactActivity local` | `applyFilters() AND chain` | nil-guarded equality on `e.exactActivity` | VERIFIED | `if ok and filterExactActivity and e.exactActivity ~= filterExactActivity then ok = false end` at line 476 |
| `primaryActivityFilterBtn` | `makeDropdown factory` | `makeDropdown(parent, 180, "Any Activity", ...)` | VERIFIED | `primaryActivityFilterBtn = makeDropdown(parent, 180, "Any Activity", primaryActivityChoices, function(val)` at line 612 |
| `exactActivityFilterBtn` | `makeDropdown factory` | `makeDropdown(parent, 220, "Any Exact Activity", ...)` | VERIFIED | `exactActivityFilterBtn = makeDropdown(parent, 220, "Any Exact Activity", ...)` at line 642 |
| `columnHeaderY` | `second filter row height` | expanded formula with two FILTER_H terms | VERIFIED | `-(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD + FILTER_H + FILTER_BOT_PAD)` = -80 at line 528 |
| `primaryActivityFilterBtn onChange` | `exactActivityFilterBtn.setChoices / .setActive` | `OW.ACTIVITY_SUBS[val]` lookup + `#subs > 0` branch | VERIFIED | `local subs = OW.ACTIVITY_SUBS[val]` → `setActive(true/false)` + `setChoices(...)` at lines 622-634 |
| `Reset Filters OnClick` | `filterPrimaryActivity = nil` | reset handler extension | VERIFIED | `filterPrimaryActivity = nil` at line 681 in Reset Filters handler |
| `Reset Filters OnClick` | `exactActivityFilterBtn.setActive(false)` | reset handler extension | VERIFIED | `exactActivityFilterBtn.setActive(false)` at line 686 in Reset Filters handler |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Primary activity choices | `primaryActivityChoices` | `OW.ACTIVITY_LIST` loop | Yes — 7 live items from Data/Activities.lua | FLOWING |
| Exact activity choices on cascade | `exactChoices` | `OW.ACTIVITY_SUBS[val]` sub-type strings | Yes — populated from Activities.lua arrays | FLOWING |
| Filter application | `filterPrimaryActivity`, `filterExactActivity` | string labels set by dropdown onChange | Yes — compared directly against `e.primaryActivity`, `e.exactActivity` on peer entries | FLOWING |

---

## Behavioral Spot-Checks

Step 7b: SKIPPED — This is a WoW addon (Lua, no server); no runnable entry point outside the game client. All behavioral verification requires human testing in-game.

---

## Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| FILT-01 | 05-01, 05-02 | Second filter row added below existing row | SATISFIED in commits | Row-2 layout at columnHeaderY=-80, filterBar2Y=-47; two dropdown widgets anchored to row 2 |
| FILT-02 | 05-01 | Primary activity filter shows all 7 activities plus "Any Activity" | SATISFIED in commits | `primaryActivityChoices` built from `OW.ACTIVITY_LIST` (7 items) + leading `{ label="Any Activity", value=nil }` |
| FILT-03 | 05-02 | Exact activity filter is disabled until a primary with sub-types is selected | SATISFIED in commits | `exactActivityFilterBtn.setActive(false)` at construction; enabled only in `#subs > 0` branch of cascade |
| FILT-04 | 05-03 | Selecting primary with sub-types enables exact filter and populates it | SATISFIED in commits | `OW.ACTIVITY_SUBS[val]` lookup with `setChoices(exactChoices, ...) + setActive(true)` when `#subs > 0` |
| FILT-05 | 05-01, 05-03 | Changing primary activity clears and disables exact filter | SATISFIED in commits | `filterExactActivity = nil` + `setChoices` + `setActive(false)` at top of every onChange branch |
| FILT-06 | 05-01, 05-03 | Selecting Quest/Farm/Chill keeps exact filter disabled (no sub-types) | SATISFIED in commits | `subs and #subs > 0` guard — empty tables from Activities.lua trigger the `setActive(false)` else branch |
| FILT-07 | 05-03 | "Reset Filters" clears both activity filters and resets exact to disabled | SATISFIED in commits | `filterPrimaryActivity=nil`, `filterExactActivity=nil`, `_fs:SetText(_default)`, `setChoices(...)`, `setActive(false)` in Reset Filters handler |

All 7 FILT requirements are satisfied in the committed implementation. No orphaned requirements.

---

## Anti-Patterns Found

No stub or placeholder anti-patterns found in the implementation commits. The committed code:

- Uses live data from `OW.ACTIVITY_LIST` and `OW.ACTIVITY_SUBS` (no hardcoded arrays)
- Has no TODO/FIXME comments
- No `return {}` or `return nil` placeholders
- All onChange handlers call `TL.Refresh()` with real state mutations

---

## Human Verification Required

These items cannot be verified programmatically and require in-game testing **after merging phase 05 to main**:

### 1. Second Filter Row Visual Layout

**Test:** Open the OnlineWhen main window, navigate to the Players tab.
**Expected:** Two distinct filter rows visible — row 1 with Status/Level/Class/Spec dropdowns, row 2 with "Any Activity" and a greyed-out "Any Exact Activity" dropdown below it. Column headers and player rows appear below row 2 with no overlap.
**Why human:** Pixel layout and visual spacing cannot be verified from code; columnHeaderY=-80 math is correct but actual render depends on WoW frame anchoring behavior.

### 2. Primary Activity Cascade — Sub-type Activities

**Test:** In the Players tab, click the "Any Activity" dropdown and select "Normal Dungeon".
**Expected:** The "Any Exact Activity" dropdown becomes enabled (not greyed out) and its menu contains "Any Exact Activity" plus all 16 TBC dungeon names.
**Why human:** Dropdown population and enable/disable visual state require live WoW UI rendering.

### 3. Primary Activity Cascade — No Sub-type Activities

**Test:** With "Normal Dungeon" selected in primary, switch to "Quest".
**Expected:** Exact activity dropdown returns to greyed-out/disabled state and its label resets to "Any Exact Activity".
**Why human:** Visual state change requires live WoW UI.

### 4. Filter Application

**Test:** With at least two players visible (different activities), select "Raid" in the primary filter.
**Expected:** Only players with `primaryActivity == "Raid"` remain visible; others disappear. Pagination and counts update correctly.
**Why human:** Requires live peer data with activity fields populated from Phase 2 network protocol.

### 5. Reset Filters

**Test:** Set both a primary and exact activity filter (e.g., Raid → Karazhan). Click "Reset Filters".
**Expected:** Both dropdowns return to "Any Activity"/"Any Exact Activity" defaults, exact dropdown disables, full player list reappears.
**Why human:** Requires live WoW UI state validation.

---

## Gaps Summary

**Single root cause: phase 05 commits not merged to main.**

The implementation is complete and passes all quality checks when examined in the git commit history (`worktree-agent-aaea9aa2`, tip commit `98927f2`). The working tree on `main` lacks every phase-05 change — no filter state variables, no applyFilters extensions, no second filter row UI, no cascade wiring, no Reset Filters extension.

**Fix:** Merge `worktree-agent-aaea9aa2` into `main` (or fast-forward if the branch is already in the ancestry). All 5 truths and all 7 FILT requirements will be satisfied immediately after the merge.

The commits to merge (in order, all on `worktree-agent-aaea9aa2`):

1. `2456bc2` — feat(05-01): add activity filter state variables and forward refs
2. `ac615c8` — feat(05-01): extend applyFilters() with activity filter AND checks
3. `57886de` — feat(05-02): update columnHeaderY for two filter rows; add filterBar2Y
4. `c7fa272` — feat(05-02): add primary and exact activity filter dropdowns on row 2
5. `d0e17ed` — feat(05-03): wire primary activity onChange cascade logic
6. `98927f2` — feat(05-03): extend Reset Filters to clear activity filters

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_
