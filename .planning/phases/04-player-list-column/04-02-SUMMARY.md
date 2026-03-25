---
phase: 04-player-list-column
plan: 02
subsystem: ui
tags: [lua, wow-addon, fontstring, player-list, activity-column]

# Dependency graph
requires:
  - phase: 04-01
    provides: "COL_X.activity and COL_W.activity layout constants in TabPlayers.lua"
  - phase: 02-01
    provides: "entry.primaryActivity and entry.exactActivity fields in peer records"
provides:
  - "activityPrimary and activityExact FontStrings created in row pool for every row"
  - "updateRows() wires activity FontStrings from entry.primaryActivity and entry.exactActivity"
  - "Blank activity cells for old-protocol peers with nil activity fields"
affects:
  - 04-03-filters

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-line cell pattern: TOPLEFT anchor at -4 (primary) + BOTTOMLEFT anchor at +4 (secondary/exact) matching timePrimary/timeSecondary"
    - "Nil-safe text: SetText(entry.field or '') produces blank cell, not error"
    - "isPast fade for exact line: SetTextColor(DIM) + SetAlpha(alpha) separate calls"

key-files:
  created: []
  modified:
    - UI/TabPlayers.lua

key-decisions:
  - "activityExact SetAlpha(alpha) mirrors timeSecondary fade pattern — separate from SetTextColor to allow DIM base color + alpha override"
  - "COL_W.activity - 4 width for both FontStrings avoids right-edge clipping (consistent with COL_W.name - 6 pattern)"

patterns-established:
  - "Two-line cell: TOPLEFT -4 / BOTTOMLEFT +4 anchor pair for dual-line cells"

requirements-completed: [LIST-01, LIST-03]

# Metrics
duration: 1min
completed: 2026-03-25
---

# Phase 4 Plan 2: Activity Column FontStrings Summary

**Two FontStrings per row for Activity cell wired to entry.primaryActivity and entry.exactActivity with blank fallback for old-protocol peers**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-25T01:22:00Z
- **Completed:** 2026-03-25T01:23:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Row pool creates activityPrimary (TOPLEFT, GameFontHighlightSmall, WHITE) and activityExact (BOTTOMLEFT, GameFontDisableSmall, DIM) FontStrings for every row, anchored using the same -4/-4 pattern as timePrimary/timeSecondary
- updateRows() sets activityPrimary from entry.primaryActivity and activityExact from entry.exactActivity, using "" fallback so nil fields produce a blank cell with no error (LIST-03 satisfied)
- activityExact fades with isPast alpha via SetAlpha(alpha) while keeping DIM base color, identical to timeSecondary pattern

## Task Commits

Each task was committed atomically:

1. **Task 1: Add activityPrimary and activityExact FontStrings to the row pool** - `f052122` (feat)
2. **Task 2: Wire activityPrimary and activityExact in updateRows()** - `850c68b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `UI/TabPlayers.lua` - Row pool extended with activityPrimary/activityExact FontStrings; updateRows() wired to entry activity fields

## Decisions Made

- activityExact uses SetTextColor(DIM[1..4]) + SetAlpha(alpha) separate calls — mirrors timeSecondary pattern, keeps DIM as the base color while applying isPast alpha fade independently
- Width is COL_W.activity - 4 (not COL_W.activity) to avoid right-edge clipping, consistent with the name column's COL_W.name - 6 approach

## Deviations from Plan

None — plan executed exactly as written.

Note: The worktree branch was missing 04-01 commits (cherry-picked from worktree-agent-a41e52a2), resolving a conflict in UI/Window.lua by keeping WINDOW_W=950 from 04-01 and WINDOW_H=536 from main (compact layout value from later fix). This is expected parallel-execution setup work, not a plan deviation.

## Issues Encountered

Worktree branch `worktree-agent-af275ae8` did not have the 04-01 layout constant commits (those were on `worktree-agent-a41e52a2`). Cherry-picked `8efb819` and `02beeb1` onto this branch. One conflict in `UI/Window.lua` (WINDOW_H): 04-01 had 520, main had 536 (from compact layout commit `a9ed169`). Resolved to keep 536, which is the correct current value after the schedule tab was made compact post-03-01.

## Next Phase Readiness

- Activity column FontStrings are in place and populated — ready for 04-03 to add Activity column header and activity filters
- Both LIST-01 (activity column display) and LIST-03 (blank for old-protocol peers) requirements satisfied

---
*Phase: 04-player-list-column*
*Completed: 2026-03-25*
