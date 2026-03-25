---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Activity System
status: Milestone complete
stopped_at: Completed 05-03-PLAN.md
last_updated: "2026-03-25T01:33:54.157Z"
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 13
  completed_plans: 13
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-24)

**Core value:** Players can immediately see not just *when* someone is online but *what they plan to do* — enabling at-a-glance group formation.
**Current focus:** Phase 05 — player-list-filters

## Current Position

Phase: 05
Plan: Not started

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 01-data-foundation P01 | 1 | 1 tasks | 2 files |
| Phase 01-data-foundation P02 | 1 | 2 tasks | 1 files |
| Phase 02-database-protocol P01 | 1 | 1 tasks | 1 files |
| Phase 02-database-protocol P02 | 1 | 2 tasks | 1 files |
| Phase 02-database-protocol P03 | 5 | 2 tasks | 0 files |
| Phase 03-schedule-tab-ui P01 | 64s | 2 tasks | 2 files |
| Phase 03-schedule-tab-ui P02 | 51s | 2 tasks | 1 files |
| Phase 04-player-list-column P01 | 2min | 2 tasks | 2 files |
| Phase 04-player-list-column P02 | 1min | 2 tasks | 1 files |
| Phase 04-player-list-column P03 | 3min | 2 tasks | 1 files |
| Phase 05-player-list-filters P01 | 2min | 2 tasks | 1 files |
| Phase 05-player-list-filters PP02 | 3min | 2 tasks | 1 files |
| Phase 05-player-list-filters P03 | 4min | 2 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: Hide exact-activity dropdown for Quest/Farm/Chill — no "N/A" placeholder
- [Init]: Show blank (not "Unknown") for missing activity in old peer entries
- [Init]: Append activity fields to ANN wire format (fields 11-12) — backward-compatible
- [Init]: New `Data/Activities.lua` follows existing data file pattern (Timezones.lua, Specs.lua)
- [Phase 01-data-foundation]: Plain strings in OW.ACTIVITY_SUBS (not {id,label} pairs) — downstream consumers key by label string only
- [Phase 01-data-foundation]: Quest/Farm/Chill map to empty table {} not nil — prevents nil-iteration errors in all consumers
- [Phase 01-data-foundation]: Heroic Dungeon list is identical to Normal Dungeon list — all 16 TBC dungeons have heroic versions
- [Phase 01-data-foundation]: Data/Activities.lua TOC entry placed between Data/Timezones.lua and Core/Status.lua — data files load before Core modules
- [Phase 02-database-protocol]: Pass-through only for activity values in SaveMyEntry — no validation against OW.ACTIVITY_LIST per D-05
- [Phase 02-database-protocol]: Accept exactly 10 or 12 fields in validateANN — no partial/intermediate counts
- [Phase 02-database-protocol]: No validation of activity field values in validateANN — no ACTIVITY_LIST lookup
- [Phase 02-database-protocol]: No code changes required in 02-03 — Phase 2 integration verified as correct by code trace and in-client smoke test
- [Phase 03-schedule-tab-ui]: value=act.label (not act.id) for activity dropdown — OW.ACTIVITY_SUBS keyed by label string
- [Phase 03-schedule-tab-ui]: ClearValue() before SetItems() in onChange handler — prevents stale selection when switching between activities with sub-types
- [Phase 03-schedule-tab-ui]: exactActivity declared local in onSave scope — available at SaveMyEntry call site without module-scope upvalue
- [Phase 03-schedule-tab-ui]: TI.Populate replicates onChange show/hide logic — SetValue alone does not fire onChange handler
- [Phase 03-schedule-tab-ui]: selectedActivity = nil in TI.Reset — ClearValue only clears widget state, not the module-scope upvalue
- [Phase 04-player-list-column]: No WINDOW_H change in 04-01 — height expansion handled in Phase 3; only width needed for player list column
- [Phase 04-player-list-column]: activity column at COL_X=420 COL_W=150; time shifted to x=576, actions shifted to x=828 to accommodate new column
- [Phase 04-player-list-column]: activityExact uses SetAlpha(alpha) separate from SetTextColor(DIM) to allow isPast fade while keeping DIM base color — mirrors timeSecondary pattern
- [Phase 04-player-list-column]: COL_W.activity - 4 width avoids right-edge clipping for activity FontStrings — consistent with COL_W.name - 6 pattern
- [Phase 04-player-list-column]: nil-last sort uses early return bNil before ASC/DESC flip — nil entries always last in both directions
- [Phase 04-player-list-column]: activity sort key is exactActivity (non-empty) with fallback to primaryActivity per D-07
- [Phase 05-player-list-filters]: filterPrimaryActivity and filterExactActivity as nil-or-string-label locals, AND-chain nil-guard pattern
- [Phase 05-player-list-filters]: columnHeaderY expanded to -80 for two-row filter bar; filterBar2Y=-47 for row 2 vertical centering
- [Phase 05-player-list-filters]: primaryActivityChoices value=act.label (string) consistent with entry.primaryActivity comparison; exactActivityFilterBtn starts disabled pending cascade wiring in Plan 05-03
- [Phase 05-player-list-filters]: OW.ACTIVITY_SUBS[val] with #subs > 0 check handles Quest/Farm/Chill empty tables without special-casing
- [Phase 05-player-list-filters]: primaryActivityFilterBtn reset uses ._fs:SetText(._default) not setChoices — primary choices never change

### Key Implementation Notes

- `validateANN` currently hardcodes `#fields ~= 10` — Phase 2 must change this to `#fields < 10` and treat fields 11-12 as optional
- `OW.SaveMyEntry` signature gains two params: `primaryActivity`, `exactActivity`
- Window constants to adjust: `WINDOW_W`/`WINDOW_H` in `UI/Window.lua`; `contentAreaHeight`/`dateTimeGroupHeight` in `UI/TabSchedule.lua` are derived from `WINDOW_H`
- Phase 3 and Phase 4 both depend on Phase 2 only — could parallelize, but sequential is safer for window-sizing coordination

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-03-25T01:27:38.115Z
Stopped at: Completed 05-03-PLAN.md
Resume file: None
