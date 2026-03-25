---
phase: 04-player-list-column
verified: 2026-03-25T00:00:00Z
status: passed
score: 9/9 must-haves verified
re_verification: false
---

# Phase 4: Player List Column Verification Report

**Phase Goal:** The Activity column is visible in the player list table, sortable, and the window is wide enough to display it without layout overflow
**Verified:** 2026-03-25
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                 | Status     | Evidence                                                                   |
|----|---------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------|
| 1  | An "Activity" column header appears after "Spec" in the player list                  | VERIFIED   | `makeHeader("activity", "Activity", COL_X.activity, COL_W.activity)` at line 667, positioned between spec (line 666) and time (line 668) calls |
| 2  | Clicking the Activity header sorts the list by exact activity (fallback to primary)   | VERIFIED   | `sortColumn == "activity"` case at lines 82-89; sort key is `exactActivity` falling back to `primaryActivity` |
| 3  | Entries with nil primaryActivity always sort to the bottom regardless of ASC/DESC    | VERIFIED   | Early `return bNil` at line 86 bypasses the ASC/DESC flip at line 99 — nil entries sort last in both directions |
| 4  | Rows with activity data show primary on the first line and exact on the second line  | VERIFIED   | `row.activityPrimary:SetText(entry.primaryActivity or "")` at line 212; `row.activityExact:SetText(entry.exactActivity or "")` at line 215 |
| 5  | Rows for old-client peers (nil activity fields) show a blank Activity cell, no error | VERIFIED   | `or ""` fallback on both SetText calls (lines 212, 215) — nil produces empty string, no error |
| 6  | The main window is wide enough that all columns fit without horizontal overlap        | VERIFIED   | `WINDOW_W = 950` in Window.lua line 7; `CONTENT_W = 938` in TabPlayers.lua line 17; COL_X.actions = 828, COL_W.actions = 90 — rightmost edge is 918, within 938 |
| 7  | CONTENT_W reflects new window width minus insets                                     | VERIFIED   | `CONTENT_W = 938` (950 - 6*2 = 938); comment in source confirms: "WINDOW_W 950 - INSET*2 6" |
| 8  | All column X positions and widths include the activity column slot                   | VERIFIED   | `COL_X = { ..., activity = 420, time = 576, actions = 828 }` and `COL_W = { ..., activity = 150, ... }` at lines 26-27 |
| 9  | Sort arrow updates on the Activity header when Refresh() is called                   | VERIFIED   | `headerBtns.activity:SetText("Activity" .. arrowFor("activity"))` at lines 506-508 in Refresh() |

**Score:** 9/9 truths verified

---

### Required Artifacts

#### Plan 01 Artifacts

| Artifact           | Expected                                    | Level 1 (Exists) | Level 2 (Substantive)      | Level 3 (Wired)                     | Status     |
|--------------------|---------------------------------------------|------------------|----------------------------|-------------------------------------|------------|
| `UI/Window.lua`    | Updated WINDOW_W constant (950)             | FOUND            | `local WINDOW_W  = 950` at line 7 | Used by TAB frame sizing throughout Window.lua | VERIFIED |
| `UI/TabPlayers.lua`| Updated CONTENT_W and COL_X/COL_W with activity column | FOUND | `CONTENT_W = 938`, `activity = 420` in COL_X, `activity = 150` in COL_W at lines 17, 26-27 | Layout constants consumed by all row/header creation code | VERIFIED |

#### Plan 02 Artifacts

| Artifact           | Expected                                           | Level 1 (Exists) | Level 2 (Substantive)                  | Level 3 (Wired)                              | Status     |
|--------------------|----------------------------------------------------|------------------|-----------------------------------------|----------------------------------------------|------------|
| `UI/TabPlayers.lua`| Activity FontStrings in row pool and updateRows wiring | FOUND        | `activityPrimary` FontString at line 735; `activityExact` at line 742; both stored in rowPool at lines 797-798 | `SetText` calls in updateRows() at lines 212-217 reading `entry.primaryActivity` and `entry.exactActivity` | VERIFIED |

#### Plan 03 Artifacts

| Artifact           | Expected                                           | Level 1 (Exists) | Level 2 (Substantive)                            | Level 3 (Wired)                                  | Status     |
|--------------------|----------------------------------------------------|------------------|--------------------------------------------------|--------------------------------------------------|------------|
| `UI/TabPlayers.lua`| Activity column header and sort case               | FOUND            | `makeHeader("activity", ...)` at line 667; `sortColumn == "activity"` case at lines 82-89 | makeHeader wires OnClick to setSort("activity"); Refresh() updates arrow at lines 506-508 | VERIFIED |

---

### Key Link Verification

| From                                    | To                                    | Via                             | Status   | Evidence                                                   |
|-----------------------------------------|---------------------------------------|---------------------------------|----------|------------------------------------------------------------|
| `UI/Window.lua` (WINDOW_W)              | `UI/TabPlayers.lua` (CONTENT_W)       | WINDOW_W - INSET*2              | VERIFIED | CONTENT_W = 938 matches 950 - 12; comment confirms formula |
| `UI/TabPlayers.lua` (updateRows)        | `entry.primaryActivity / entry.exactActivity` | SetText calls    | VERIFIED | Lines 212-217: both fields read with `or ""` nil guard     |
| `UI/TabPlayers.lua` (row pool)          | `COL_X.activity`                      | FontString anchor positions     | VERIFIED | Lines 736, 743: `SetPoint(..., COL_X.activity, ...)` for both FontStrings |
| `UI/TabPlayers.lua` (makeHeader activity) | `setSort("activity")`              | OnClick handler inside makeHeader | VERIFIED | makeHeader at line 667 uses same helper that wires OnClick for all other sortable columns |
| `UI/TabPlayers.lua` (sortEntries)       | `entry.exactActivity / entry.primaryActivity` | sort comparator activity case | VERIFIED | Lines 82-89: reads both fields with exact-first-then-primary fallback |

---

### Data-Flow Trace (Level 4)

The activity cell FontStrings render data from peer entries that arrive via the network protocol (OW.UpsertPeer, Phase 2). There is no local DB query to trace — the data originates from ANN wire messages deserialized upstream. Verification that `entry.primaryActivity` and `entry.exactActivity` are populated is covered by Phase 2 (NET-04: OW.UpsertPeer stores activity fields). The SetText calls in updateRows() guard against nil with `or ""`, so the data path is safe for both populated and absent fields.

| Artifact              | Data Variable                      | Source                            | Produces Real Data                  | Status   |
|-----------------------|------------------------------------|-----------------------------------|-------------------------------------|----------|
| `UI/TabPlayers.lua` (activityPrimary SetText) | `entry.primaryActivity` | ANN wire message via OW.UpsertPeer (Phase 2) | Yes — populated by NET-04 when peer has new client | FLOWING |
| `UI/TabPlayers.lua` (activityExact SetText)   | `entry.exactActivity`   | ANN wire message via OW.UpsertPeer (Phase 2) | Yes — populated by NET-04; nil for old clients, "" rendered as blank | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — this is a WoW addon (Lua). There are no runnable entry points outside the WoW client; all behavioral verification requires the in-game client.

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                                    | Status    | Evidence                                                        |
|-------------|-------------|--------------------------------------------------------------------------------|-----------|-----------------------------------------------------------------|
| LIST-01     | 04-02-PLAN  | "Activity" column added after Spec, showing primary and exact on separate lines | SATISFIED | activityPrimary (line 735) + activityExact (line 742) FontStrings; updateRows wires both at lines 212-217 |
| LIST-02     | 04-03-PLAN  | Activity column sortable by exact activity, falling back to primary            | SATISFIED | sortEntries() activity case (lines 82-89) with exact-with-primary-fallback sort key; makeHeader wires click |
| LIST-03     | 04-02-PLAN  | Entries with no activity data show blank cell (old peers)                      | SATISFIED | `entry.primaryActivity or ""` and `entry.exactActivity or ""` at lines 212, 215 — nil produces blank, no error |
| LIST-04     | 04-01-PLAN  | Main window width increased to accommodate Activity column                     | SATISFIED | `WINDOW_W = 950` in Window.lua line 7; COL_X.actions = 828 + COL_W.actions = 90 = 918 fits in CONTENT_W 938 |

**Requirement ID cross-reference:**
- Plans declare: LIST-01 (04-02), LIST-02 (04-03), LIST-03 (04-02), LIST-04 (04-01)
- REQUIREMENTS.md Phase 4 IDs: LIST-01, LIST-02, LIST-03, LIST-04
- All 4 requirement IDs accounted for. No orphaned requirements.

---

### Anti-Patterns Found

No blocker or warning anti-patterns found. Scanned for:
- TODO/FIXME/placeholder comments in modified files: none in activity-related code
- `return ""` / empty SetText: the `or ""` pattern is correct nil-guard behavior, not a stub
- Hardcoded empty props passed to the row cells: none — all text comes from live entry fields
- Missing nil guards: both `entry.primaryActivity` and `entry.exactActivity` guarded with `or ""`

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | None found |

---

### Human Verification Required

#### 1. Activity Column Visual Layout

**Test:** Open WoW, load the addon, open OnlineWhen player list. Verify the Activity column appears between Spec and Online At, that both column headers are fully readable, and that no columns overlap horizontally.
**Expected:** "Activity" header visible between "Spec" and "Online At"; all column text readable without clipping.
**Why human:** Visual layout and pixel-level overflow cannot be verified from source code alone.

#### 2. Two-Line Cell Rendering

**Test:** With at least one peer who has activity data (primaryActivity + exactActivity both set), view their row. Verify primary activity appears on the top line and exact activity on the bottom line within the Activity cell.
**Expected:** e.g., "Normal Dungeon" on top line, "The Slave Pens" on a dimmer bottom line.
**Why human:** FontString vertical stacking and visual alignment require in-client inspection.

#### 3. Sort Behavior End-to-End

**Test:** Click the "Activity" column header. Verify the list sorts alphabetically by exact activity (or primary when exact is absent). Click again to reverse sort. Verify peers with no activity data always appear at the bottom regardless of sort direction.
**Expected:** ASC: alphabetical (nil-activity rows last). DESC: reverse alphabetical (nil-activity rows still last).
**Why human:** Sort behavior with live peer data requires the WoW client runtime.

---

### Gaps Summary

No gaps. All 9 observable truths verified. All 4 phase requirements (LIST-01 through LIST-04) satisfied by evidence in the codebase. All 6 plan commits confirmed present (`8efb819`, `02beeb1` / `d3846e9`, `2e5a1b8`, `f052122`, `850c68b`, `1d925b8`, `9880e09`). No blocker anti-patterns found.

Three items flagged for human verification (visual layout, two-line rendering, sort end-to-end) — these require the WoW client runtime and cannot be verified programmatically.

---

_Verified: 2026-03-25_
_Verifier: Claude (gsd-verifier)_
