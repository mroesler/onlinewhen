# Phase 1: Data Foundation - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Author `Data/Activities.lua` — a new static data module that defines the 7 primary activities,
their ordered list, and per-activity sub-type lists for all TBC Classic Anniversary instances.
This file is the single source of truth that every subsequent phase (UI, network, filters) reads.
No WoW API or UI code belongs here.

</domain>

<decisions>
## Implementation Decisions

### Activity Ordering
- **D-01:** Activity display order (baked into `OW.ACTIVITY_LIST`): Normal Dungeon → Heroic Dungeon → Raid → PVP → Quest → Farm → Chill.
  Content-first ordering — heavy group content at the top, casual solo activities at the bottom.

### Dungeon Sub-type Lists
- **D-02:** Normal Dungeon and Heroic Dungeon use **separate** sub-type lists.
  `OW.ACTIVITY_SUBS["Normal Dungeon"]` lists instances available in normal mode;
  `OW.ACTIVITY_SUBS["Heroic Dungeon"]` lists instances available in heroic mode.
  Some instances appear in both; mode-only instances (e.g. normal-only) appear only in their list.

### TBC Content Completeness
- **D-03:** Include **all** TBC Classic Anniversary instances — dungeons (all modes), all raid tiers, all battlegrounds.
  This includes Caverns of Time instances (Escape from Durnholde, Opening of the Dark Portal), Magisters' Terrace, and all phases of raid content.
  Completeness is preferred over a curated short list.

### Claude's Discretion
- Exact enum integer IDs for `OW.ACTIVITY` (follow the OW.SPEC pattern: sequential integers starting at 1)
- Exact enum key names (e.g. `NORMAL_DUNGEON` vs `DUNGEON_NORMAL` — follow OW.SPEC naming style)
- Whether sub-type entries are plain strings or `{ id, label }` pairs (the ROADMAP success criteria uses string indexing, plain strings are sufficient)
- Exact dungeon/raid/BG names as they appear in-game (researcher will identify canonical TBC Classic Anniversary names)
- TOC load-order position: between `Data/Timezones.lua` and `Core/Status.lua` (locked by ROADMAP)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Data File Pattern
- `Core/Specs.lua` — The OW.SPEC enum + OW.CLASS_SPECS pattern. `OW.ACTIVITY` enum and `OW.ACTIVITY_LIST` must mirror this structure exactly (setmetatable read-only guard, `{ id, label }` pairs in list).
- `Data/Timezones.lua` — The Data/ file header convention and `local addonName, OW = ...` namespace pattern.

### Addon Manifest
- `OnlineWhen.toc` — Load order file. `Data/Activities.lua` must be inserted between `Data/Timezones.lua` and `Core/Status.lua`.

### Codebase Conventions
- `.planning/codebase/CONVENTIONS.md` — Enum pattern, naming conventions (SCREAMING_SNAKE_CASE keys, camelCase locals), file header style.
- `.planning/codebase/STRUCTURE.md` — Directory purposes and load-order rules.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `setmetatable` read-only guard pattern (from `Core/Specs.lua` and `Core/Classes.lua`): copy verbatim for `OW.ACTIVITY`
- `{ id, label }` list pattern (from `OW.CLASS_SPECS`): use for `OW.ACTIVITY_LIST`

### Established Patterns
- Every data file starts with `local addonName, OW = ...` (no `OW = OW or {}` — that's only in `Data/Timezones.lua` as an older pattern)
- File header: single-line comment `-- Data/Activities.lua — [purpose]`
- Section dividers: 75-dash `-- -----...-----` lines between logical sections
- No WoW API calls in `Data/` files — pure Lua tables and math only

### Integration Points
- `Core/Database.lua` will reference `OW.ACTIVITY_LIST` and `OW.ACTIVITY_SUBS` in Phase 2
- `UI/TabSchedule.lua` will reference `OW.ACTIVITY_LIST` and `OW.ACTIVITY_SUBS` in Phase 3
- `UI/TabPlayers.lua` will reference `OW.ACTIVITY_LIST` and `OW.ACTIVITY_SUBS` in Phases 4-5

</code_context>

<specifics>
## Specific Ideas

- The ROADMAP success criteria confirms: `OW.ACTIVITY_SUBS["Quest"]`, `["Farm"]`, and `["Chill"]` each return an **empty table** `{}` — not nil, to avoid nil-check boilerplate in consumers.
- `OW.ACTIVITY` must raise a Lua error on unknown key access (same read-only metatable as `OW.SPEC`) — this is explicitly required by the success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-data-foundation*
*Context gathered: 2026-03-24*
