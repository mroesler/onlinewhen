---
phase: 02-database-protocol
plan: 01
subsystem: database
tags: [lua, wow-addon, savedvariables, activity-system]

# Dependency graph
requires:
  - phase: 01-data-foundation
    provides: OW.ACTIVITY_LIST and OW.ACTIVITY_SUBS data tables
provides:
  - Extended OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity) — 8-parameter signature
  - Activity fields stored in OnlineWhenDB.myEntry (primaryActivity, exactActivity)
affects:
  - 02-02 (network serialization reads myEntry.primaryActivity / myEntry.exactActivity)
  - 03-ui-schedule (caller of SaveMyEntry — needs to pass activity args)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "or nil idiom to normalize empty string to nil for optional fields in myEntry struct"

key-files:
  created: []
  modified:
    - Core/Database.lua

key-decisions:
  - "Pass-through only for activity values — no validation against OW.ACTIVITY_LIST per D-05"
  - "or nil on both fields ensures nil (not empty string) is stored when params are omitted by existing callers"

patterns-established:
  - "Optional trailing parameters use 'param or nil' idiom — callers passing 6 args get nil fields, not errors"

requirements-completed:
  - NET-03

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 02 Plan 01: Database Protocol Summary

**OW.SaveMyEntry extended to 8 parameters storing primaryActivity and exactActivity in OnlineWhenDB.myEntry with pass-through (no validation)**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-24T22:43:00Z
- **Completed:** 2026-03-24T22:43:34Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Extended `OW.SaveMyEntry` signature from 6 to 8 parameters
- Added `primaryActivity` and `exactActivity` fields to the `OnlineWhenDB.myEntry` struct assignment
- Existing callers passing 6 arguments continue to work — new params default to nil
- No activity validation added per D-05 (pass-through design)

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend OW.SaveMyEntry signature and struct assignment** - `f196c81` (feat)

## Files Created/Modified

- `Core/Database.lua` - Extended SaveMyEntry to 8-param signature; added primaryActivity and exactActivity fields to myEntry

## Decisions Made

None — followed plan exactly as specified. D-05 (no validation) already documented.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `OnlineWhenDB.myEntry` now stores activity fields ready for Plan 02-02 (network serializer)
- `BroadcastSelf()` block unchanged — will automatically include activity fields once SerializeANN is extended in 02-02
- No blockers for Plan 02-02 or 02-03

---
*Phase: 02-database-protocol*
*Completed: 2026-03-24*
