# Milestones

## v1.2 Activity System (Shipped: 2026-03-25)

**Phases completed:** 5 phases, 13 plans, 16 tasks

**Key accomplishments:**

- OW.ACTIVITY enum + OW.ACTIVITY_LIST + OW.ACTIVITY_SUBS for all TBC Classic Anniversary content (7 activities, 16+16+9+4 sub-types) in a single pure-Lua data file
- Data/Activities.lua registered in OnlineWhen.toc at load-order position between Data/Timezones.lua and Core/Status.lua, enabling OW.ACTIVITY globals at runtime
- OW.SaveMyEntry extended to 8 parameters storing primaryActivity and exactActivity in OnlineWhenDB.myEntry with pass-through (no validation)
- Extended ANN wire format to 12 fields with activity data, fixed empty-token split, and added backward-compatible 10/12-field validation.
- End-to-end activity field round-trip verified by code trace and in-client smoke test; all Phase 2 success criteria confirmed with no code changes needed.
- One-liner:
- One-liner:
- Window widened to 950px and Activity column slot added to TabPlayers layout constants (COL_X.activity=420, COL_W.activity=150), shifting time and actions columns right by 150px
- Clickable Activity column header with exact/primary-fallback sort and nil-last behavior wired into sortEntries() and Refresh()
- ACTIVITY_SUBS cascade wiring for primary->exact activity dropdown and Reset Filters extended to clear all 6 filter variables including both activity filters

---
