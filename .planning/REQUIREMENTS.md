# Requirements: OnlineWhen — Activity Scheduling Feature

**Defined:** 2026-03-24
**Core Value:** Players can immediately see not just *when* someone is online but *what they plan to do* — enabling at-a-glance group formation.

## v1.2 Requirements

### Data

- [x] **DATA-01**: `Data/Activities.lua` defines 7 primary activities: Quest, PVP, Normal Dungeon, Heroic Dungeon, Raid, Farm, Chill
- [x] **DATA-02**: All TBC Classic Anniversary dungeons listed as sub-options for Normal Dungeon and Heroic Dungeon
- [x] **DATA-03**: All TBC Classic Anniversary raids listed as sub-options for Raid
- [x] **DATA-04**: All TBC Anniversary Classic battlegrounds listed as sub-options for PVP
- [x] **DATA-05**: Activities with no sub-types (Quest, Farm, Chill) have an empty sub-type list

### Schedule Form

- [x] **SCHED-01**: Activity section appears at the bottom of the Schedule tab, inside a labeled group box
- [x] **SCHED-02**: Primary activity dropdown shows all 7 activities
- [x] **SCHED-03**: Selecting Normal Dungeon, Heroic Dungeon, Raid, or PVP reveals a second dependent dropdown with relevant sub-options
- [x] **SCHED-04**: Selecting Quest, Farm, or Chill hides the exact activity dropdown entirely
- [x] **SCHED-05**: Activity is required — Save button is blocked and shows an error if no primary activity is selected
- [x] **SCHED-06**: Activity fields are cleared/reset when the form is reset (TI.Reset())
- [x] **SCHED-07**: Activity fields are restored when the form is populated from an existing entry (TI.Populate())
- [x] **SCHED-08**: Main window height is increased to accommodate the new activity section in the schedule tab

### Network Protocol

- [x] **NET-01**: `primaryActivity` and `exactActivity` fields appended to the ANN wire message
- [x] **NET-02**: Old clients (missing activity fields) are handled gracefully — activity treated as blank
- [x] **NET-03**: `OW.SaveMyEntry` accepts and stores activity fields in `OnlineWhenDB.myEntry`
- [x] **NET-04**: `OW.UpsertPeer` stores activity fields from deserialized ANN messages

### Player List

- [x] **LIST-01**: "Activity" column added after Spec column, showing primary and exact activity on separate lines in one cell
- [x] **LIST-02**: Activity column is sortable by exact activity (falls back to primary activity when exact is absent)
- [x] **LIST-03**: Entries with no activity data show a blank Activity cell (graceful degradation for old peers)
- [x] **LIST-04**: Main window width is increased to accommodate the new Activity column while maintaining relative layout proportions

### Filters

- [x] **FILT-01**: Second filter row added below the existing filter row with primary activity and exact activity dropdowns
- [x] **FILT-02**: Primary activity filter shows all 7 activities plus "Any Activity"
- [x] **FILT-03**: Exact activity filter is disabled until a primary activity with sub-types is selected
- [ ] **FILT-04**: Selecting a primary activity with sub-types enables the exact activity filter and populates it with that activity's sub-options
- [x] **FILT-05**: Changing the primary activity filter clears and disables the exact activity filter (same pattern as class→spec)
- [x] **FILT-06**: Selecting Quest, Farm, or Chill in the primary filter keeps the exact activity filter disabled (no sub-types)
- [ ] **FILT-07**: "Reset Filters" clears both activity filters and resets the exact activity filter to disabled state

## Out of Scope

| Feature | Reason |
|---------|--------|
| Custom activity labels | Predefined list only — free-text creates sync/filter complexity |
| Activity icons or color coding | Text-only to stay consistent with existing UI style |
| Multiple simultaneous activities | One activity per entry — keeps the data model simple |
| Activity history or logs | Only current scheduled activity; history not in scope |
| "Unknown" for missing activity | Show blank — cleaner than false signal |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 1 | Complete |
| DATA-02 | Phase 1 | Complete |
| DATA-03 | Phase 1 | Complete |
| DATA-04 | Phase 1 | Complete |
| DATA-05 | Phase 1 | Complete |
| NET-01 | Phase 2 | Complete |
| NET-02 | Phase 2 | Complete |
| NET-03 | Phase 2 | Complete |
| NET-04 | Phase 2 | Complete |
| SCHED-01 | Phase 3 | Complete |
| SCHED-02 | Phase 3 | Complete |
| SCHED-03 | Phase 3 | Complete |
| SCHED-04 | Phase 3 | Complete |
| SCHED-05 | Phase 3 | Complete |
| SCHED-06 | Phase 3 | Complete |
| SCHED-07 | Phase 3 | Complete |
| SCHED-08 | Phase 3 | Complete |
| LIST-01 | Phase 4 | Complete |
| LIST-02 | Phase 4 | Complete |
| LIST-03 | Phase 4 | Complete |
| LIST-04 | Phase 4 | Complete |
| FILT-01 | Phase 5 | Complete |
| FILT-02 | Phase 5 | Complete |
| FILT-03 | Phase 5 | Complete |
| FILT-04 | Phase 5 | Pending |
| FILT-05 | Phase 5 | Complete |
| FILT-06 | Phase 5 | Complete |
| FILT-07 | Phase 5 | Pending |

**Coverage:**
- v1.2 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0

---
*Requirements defined: 2026-03-24*
*Last updated: 2026-03-24 — traceability corrected after roadmap finalized (SCHED→Phase 3, NET→Phase 2)*
