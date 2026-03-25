---
phase: 02-database-protocol
plan: 02
subsystem: network
tags: [lua, protocol, wire-format, serialization, backward-compat]

# Dependency graph
requires:
  - phase: 01-data-foundation
    provides: Data/Activities.lua with OW.ACTIVITY_LIST and OW.ACTIVITY_SUBS enums
provides:
  - Extended ANN wire format (12 fields) with primaryActivity and exactActivity as fields 11-12
  - Backward-compatible validateANN accepting 10-field (old client) and 12-field (new client) ANNs
  - Fixed split() that preserves empty tokens so empty activity fields round-trip correctly
  - HandleANN maps activity fields into entry table passed to UpsertPeer
affects: [03-schedule-ui, 04-players-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Empty-token-preserving split: append sentinel (str..sep), match ([^sep]*)sep"
    - "Optional trailing fields: validate by accepting two explicit field counts (10 or 12)"
    - "nil coalescing for optional fields: (fields[N] and fields[N] ~= '') and fields[N] or nil"

key-files:
  created: []
  modified:
    - Network/Protocol.lua

key-decisions:
  - "Accept exactly 10 or 12 fields in validateANN — no partial/intermediate counts (D-03)"
  - "No validation of activity field values in validateANN — trust sender, no ACTIVITY_LIST lookup (D-05)"
  - "Empty string activity fields convert to nil in HandleANN — consistent with spec/class pattern"

patterns-established:
  - "Empty-token split: (str..sep):gmatch('([^sep]*)sep') — prerequisite for all multi-field wire parsing"
  - "Backward-compatible field extension: add fields at end, accept old count OR new count in validator"

requirements-completed: [NET-01, NET-02, NET-04]

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 02 Plan 02: Database Protocol — ANN Wire Format Extension Summary

**Extended ANN wire format to 12 fields with activity data, fixed empty-token split, and added backward-compatible 10/12-field validation.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-24T22:42:52Z
- **Completed:** 2026-03-24T22:43:52Z
- **Tasks:** 2 completed
- **Files modified:** 1

## Accomplishments

- Fixed split() to preserve empty tokens using sentinel-append + star-quantifier pattern, preventing field-index corruption when activity fields are empty
- Extended SerializeANN from 10 to 12 fields by appending primaryActivity and exactActivity
- Relaxed validateANN to accept both 10-field (old client) and 12-field (new client) ANNs
- Extended HandleANN to map fields 11-12 to primaryActivity/exactActivity with empty-to-nil conversion, making activity data available to UpsertPeer

## Task Commits

1. **Task 1: Fix split() and extend SerializeANN** - `11ebfbb` (feat)
2. **Task 2: Extend validateANN and HandleANN for activity fields** - `f6e4c7d` (feat)

## Files Created/Modified

- `Network/Protocol.lua` - Fixed split(), extended SerializeANN to 12 fields, relaxed validateANN field count check, added primaryActivity/exactActivity mapping in HandleANN

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - all wired fields flow from SerializeANN through wire to HandleANN to UpsertPeer.

## Self-Check: PASSED
