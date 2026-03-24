# Roadmap: OnlineWhen — Activity Scheduling (v1.2)

## Overview

This milestone adds an activity system to OnlineWhen. Players select what they plan to do
(primary activity) and, for content-specific choices, a dependent exact-activity sub-type.
The data flows from a new static data file through the database and network protocol, then
surfaces in the Schedule tab form, the player list table, and the player list filters. Five
phases each deliver a complete, testable vertical slice — each phase's output is loadable in
WoW without breaking anything that came before.

## Milestones

- 🚧 **v1.2 Activity System** - Phases 1-5 (in progress)

## Phases

- [ ] **Phase 1: Data Foundation** - `Data/Activities.lua` with 7 primary activities and all TBC sub-type lists
- [ ] **Phase 2: Database + Protocol** - Entry schema extended; ANN wire format gains activity fields (backward-compatible)
- [ ] **Phase 3: Schedule Tab UI** - Activity group box with primary dropdown and conditional exact-activity dropdown
- [ ] **Phase 4: Player List Column** - Activity column added, sortable, window widened
- [ ] **Phase 5: Player List Filters** - Second filter row with cascading primary + exact activity filters

## Phase Details

### Phase 1: Data Foundation
**Goal**: All TBC Classic Anniversary activity data exists as a queryable Lua module, ready for any other layer to import
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):
  1. `OW.ACTIVITY` enum exists with 7 keys and raises a Lua error on unknown key access (same read-only metatable pattern as `OW.SPEC`)
  2. `OW.ACTIVITY_LIST` provides an ordered array of `{ id, label }` records covering all 7 primary activities
  3. `OW.ACTIVITY_SUBS["Normal Dungeon"]` returns the full list of TBC dungeon names; same for Heroic Dungeon, Raid, and PVP
  4. `OW.ACTIVITY_SUBS["Quest"]`, `["Farm"]`, and `["Chill"]` each return an empty table (no sub-types)
  5. `Data/Activities.lua` appears in `OnlineWhen.toc` between `Data/Timezones.lua` and `Core/Status.lua` (load-order safe)
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Create complete Data/Activities.lua with OW.ACTIVITY enum, OW.ACTIVITY_LIST, and OW.ACTIVITY_SUBS
- [x] 01-02-PLAN.md — Register Data/Activities.lua in OnlineWhen.toc; smoke-test in WoW client

### Phase 2: Database + Protocol
**Goal**: Activity fields are stored in every entry record and transmitted in the ANN wire message; old-client peers degrade gracefully to blank activity
**Depends on**: Phase 1
**Requirements**: NET-01, NET-02, NET-03, NET-04
**Success Criteria** (what must be TRUE):
  1. `OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity)` writes both activity fields to `OnlineWhenDB.myEntry`
  2. `OW.Protocol.SerializeANN` produces a 12-field semicolon string ending in `;primaryActivity;exactActivity`
  3. A new peer running the updated client sends an ANN that another updated client parses correctly — activity fields appear in the received entry
  4. An ANN from an old client (10 fields) is accepted and produces an entry where `primaryActivity` and `exactActivity` are both nil (no error, no rejection)
  5. `OW.UpsertPeer` stores `primaryActivity` and `exactActivity` from deserialized ANN messages
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — Extend OW.SaveMyEntry in Core/Database.lua to accept and store primaryActivity and exactActivity
- [x] 02-02-PLAN.md — Fix split() for empty tokens; extend SerializeANN, validateANN, and HandleANN for 12-field activity wire format
- [x] 02-03-PLAN.md — Verify end-to-end round-trip and backward compatibility; in-client smoke test

### Phase 3: Schedule Tab UI
**Goal**: Players can select an activity when scheduling — primary activity is required and blocks Save when unset; exact-activity dropdown appears only for activities that have sub-types
**Depends on**: Phase 2
**Requirements**: SCHED-01, SCHED-02, SCHED-03, SCHED-04, SCHED-05, SCHED-06, SCHED-07, SCHED-08
**Success Criteria** (what must be TRUE):
  1. A labeled "Activity" group box appears below the Date & Time group in the Schedule tab, visible on first open
  2. Clicking Save with no primary activity selected shows an error message and does not save the entry
  3. Selecting "Quest", "Farm", or "Chill" hides the exact-activity dropdown; the section remains compact
  4. Selecting "Normal Dungeon", "Heroic Dungeon", "Raid", or "PVP" shows the exact-activity dropdown populated with the correct sub-type list
  5. Clicking Save with a valid activity saves the entry — `OnlineWhenDB.myEntry.primaryActivity` is set to the selected label
  6. Resetting the form (after save or manual reset) clears both activity dropdowns back to their placeholder state
  7. Re-opening the Schedule tab when an entry already exists restores both activity fields from `myEntry`
  8. The main window is tall enough that the Activity group box is fully visible without clipping
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Increase WINDOW_H to 680; add Activity group box with primary dropdown and hidden exact-activity row
- [ ] 03-02-PLAN.md — Wire onSave() validation, TI.Reset() cleanup, and TI.Populate() restore for activity fields

### Phase 4: Player List Column
**Goal**: The Activity column is visible in the player list table, sortable, and the window is wide enough to display it without layout overflow
**Depends on**: Phase 2
**Requirements**: LIST-01, LIST-02, LIST-03, LIST-04
**Success Criteria** (what must be TRUE):
  1. An "Activity" column header appears after "Spec" in the player list; clicking it sorts the list by exact activity (falling back to primary when exact is absent)
  2. Rows for peers with activity data show the primary activity on the first line and the exact activity (if set) on the second line within the same cell
  3. Rows for old-client peers (nil activity fields) show a blank Activity cell — no "Unknown", no error
  4. The main window is wide enough that all columns including Activity fit without horizontal overlap
**Plans**: 3 plans

Plans:
- [ ] 04-01: Increase `WINDOW_W` in `UI/Window.lua`; update `COL_X`/`COL_W` constants in `UI/TabPlayers.lua` to insert the Activity column after Spec while preserving existing column proportions
- [ ] 04-02: Extend the row pool in `UI/TabPlayers.lua` — add `activity` FontString fields (primary line + exact line) to each row; wire them in `updateRows()`
- [ ] 04-03: Add "Activity" column header button and extend `sortEntries()` with the `"activity"` sort case (exact activity label, fallback to primary activity label)

### Phase 5: Player List Filters
**Goal**: Players can filter the list by primary and exact activity; the exact filter cascades from the primary selection and resets when Reset Filters is clicked
**Depends on**: Phase 4
**Requirements**: FILT-01, FILT-02, FILT-03, FILT-04, FILT-05, FILT-06, FILT-07
**Success Criteria** (what must be TRUE):
  1. A second filter row appears below the existing class/spec/status/level row, containing a primary activity dropdown and an exact activity dropdown
  2. Selecting a primary activity with sub-types (Normal Dungeon, Heroic Dungeon, Raid, PVP) enables the exact activity dropdown and populates it with that activity's options
  3. Selecting Quest, Farm, or Chill in the primary filter keeps the exact activity filter visually disabled and empty
  4. Changing the primary activity filter clears the exact activity filter and disables it (mirrors class→spec behavior)
  5. Clicking "Reset Filters" clears both activity filters and returns the exact activity dropdown to its disabled state — the player list shows all entries again
**Plans**: 3 plans

Plans:
- [ ] 05-01: Add `filterPrimaryActivity` and `filterExactActivity` state variables; extend the `applyFilters()` logic in `UI/TabPlayers.lua` to respect both new filters
- [ ] 05-02: Build the second filter row UI — primary activity dropdown (7 items + "Any Activity") and exact activity dropdown (disabled until triggered); uses the existing closure-based dropdown pattern from TabPlayers
- [ ] 05-03: Wire cascading behavior — primary onChange populates/enables exact or disables it; "Reset Filters" clears and disables both; verify filter interaction with existing class/spec filters

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

Note: Phase 3 and Phase 4 both depend on Phase 2 (not on each other) and could be worked
in parallel if needed, but sequential execution is recommended to keep the window-sizing
changes consolidated.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Foundation | 2/2 | Complete | - |
| 2. Database + Protocol | 3/3 | Complete | - |
| 3. Schedule Tab UI | 1/2 | In Progress|  |
| 4. Player List Column | 0/3 | Not started | - |
| 5. Player List Filters | 0/3 | Not started | - |
