# Phase 4: Player List Column - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an "Activity" column to the player list table after the Spec column. The column shows
primary activity on the top line and exact activity on the bottom line within the same cell
(both pre-created FontStrings per row). The column is sortable (exact activity label, fallback
to primary; nil entries sort last). Widen `WINDOW_W` and update all `COL_X`/`COL_W` constants
and `CONTENT_W` to accommodate the new column without layout overflow. No changes to network,
data, or schedule tab layers.

</domain>

<decisions>
## Implementation Decisions

### Window & Column Layout
- **D-01:** `WINDOW_W` increases from **800 → 950**. `CONTENT_W` updates from 788 → 938
  (WINDOW_W − INSET×2 = 950 − 12).
- **D-02:** Activity column is **150px wide**, inserted after Spec. Exact layout:
  - `COL_X.activity = 420`, `COL_W.activity = 150` (Spec ends at 414; 6px gap)
  - `COL_X.time = 576` (shifted right; width stays at 246)
  - `COL_X.actions = 828` (shifted right; width stays at 90)
  - All other columns (`status`, `name`, `level`, `class`, `spec`) remain unchanged.

### Cell Rendering (Row Pool)
- **D-03:** Each row in the pool always creates **two FontStrings** for the Activity cell:
  `activityPrimary` and `activityExact`. This mirrors the `timePrimary`/`timeSecondary`
  pattern — no conditional creation, simpler pooling.
- **D-04:** `activityPrimary` is **always top-anchored** at `TOPLEFT, rowFrame, TOPLEFT,
  COL_X.activity, -4`. When no exact activity exists, the primary sits near the top of the
  cell (leaving empty space below). Behavior is uniform regardless of data — no anchor
  switching per row.
- **D-05:** `activityExact` is anchored at `BOTTOMLEFT, rowFrame, BOTTOMLEFT,
  COL_X.activity, 4` — same position pattern as `timeSecondary`. Color: **DIM**
  (`{ 0.5, 0.5, 0.55, 1.0 }`, same constant used for secondary time text).
- **D-06:** The `activityExact` FontString's alpha tracks the row's `isPast` fade (same
  `alpha` applied to all other text in the row). When `exactActivity` is nil or empty,
  set text to `""` (no `"—"` placeholder — matches the "blank for nil" requirement).

### Sorting
- **D-07:** Sort key for `"activity"` column: `exactActivity` label if set, else
  `primaryActivity` label if set, else `""`. Nil-activity entries use `""` but are
  **explicitly pushed to the bottom** — sort comparator returns `false` for nil-vs-non-nil
  (ASC) or `true` (DESC) so blank entries always land last regardless of sort direction.
- **D-08:** Default sort direction on first click: ASC (alphabetical). Consistent with
  existing column behavior.

### Claude's Discretion
- Exact pixel offsets for `activityPrimary` and `activityExact` anchors — use the same
  values as `timePrimary` (`-4`) and `timeSecondary` (`+4`)
- `COL_W.activity` FontString `SetWidth` value (use `COL_W.activity - 4` or `COL_W.activity`
  based on what avoids clipping, matching the name column's `COL_W.name - 6` pattern)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files being modified
- `UI/TabPlayers.lua` — `COL_X`/`COL_W` constants, `CONTENT_W`, row pool loop, `updateRows()`,
  `sortEntries()`, column header creation block, and `TL.Build()` (filter bar anchor at `TOPRIGHT`
  and Reset Filters button use `parent` anchors — verify no side effects from width change).
- `UI/Window.lua` — `WINDOW_W` constant (currently 800) must increase to 950.

### Read-only references
- `Data/Activities.lua` — `OW.ACTIVITY_LIST` and `OW.ACTIVITY_SUBS` for understanding the
  domain values that appear in the Activity column.
- `Core/Database.lua` — `OW.UpsertPeer` stores `primaryActivity` and `exactActivity` in peer
  entry records; these are the field names to read in `updateRows()`.

### Planning and conventions
- `.planning/ROADMAP.md` §Phase 4 — success criteria SC1–SC4 and the three plan outlines
- `.planning/phases/02-database-protocol/02-CONTEXT.md` — confirms `entry.primaryActivity`
  and `entry.exactActivity` field names on peer entries (from `OW.UpsertPeer`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `timePrimary`/`timeSecondary` two-line pattern (lines 716–727) — Activity cell uses the
  identical anchor approach: `TOPLEFT -4` for primary, `BOTTOMLEFT +4` for secondary/exact.
- `DIM` color constant (`{ 0.5, 0.5, 0.55, 1.0 }`) — already defined at module scope;
  use directly for `activityExact:SetTextColor()`.
- `makeHeader(col, label, px, pw)` helper (line 616) — reuse verbatim for the "Activity"
  column header button.
- `setSort(col)` (line 95) and `sortEntries()` (line 66) — add `"activity"` case to
  `sortEntries()`; wire `makeHeader("activity", ...)` with `OnClick → setSort("activity")`.
- `arrowFor(col)` (line 106) — already generic; no changes needed; `headerBtns["activity"]`
  must be set so `Refresh()` updates the arrow.

### Established Patterns
- Row pool: `rowPool[i] = { frame=..., statusDot=..., ..., inviteBtn=... }` — extend the
  table with `activityPrimary` and `activityExact` keys.
- `updateRows()` `isPast` alpha pattern (line 173): `local alpha = isPast and 0.38 or 1.0` —
  apply same `alpha` to `activityPrimary:SetTextColor(1,1,1,alpha)` and
  `activityExact:SetAlpha(alpha)`.
- `Refresh()` header update block (lines 476–493) — add `headerBtns.activity` update here.
- `CONTENT_W` is used in `contentFrame:SetSize()` (line 674) and `rowFrame:SetSize()` (line 680)
  — both must reflect the new value (938).

### Integration Points
- `UI/Window.lua:7` — `local WINDOW_W = 800` → change to `950`.
- `UI/TabPlayers.lua:17` — `local CONTENT_W = 788` → change to `938`.
- `UI/TabPlayers.lua:26–27` — `COL_X` and `COL_W` tables need `activity` key added and
  `time`/`actions` x-values updated.
- `updateRows()` (line 165): add `row.activityPrimary:SetText(...)` and
  `row.activityExact:SetText(...)` blocks after the existing spec/time fields.
- `sortEntries()` (line 66): add `elseif sortColumn == "activity" then` case with nil-last logic.

</code_context>

<specifics>
## Specific Ideas

- The Activity column header label is **"Activity"** — matches the column name in the
  ROADMAP success criteria ("An 'Activity' column header appears after 'Spec'").
- Nil-last sort logic: when `sortValA` is `""` (nil entry) and `sortValB` is non-empty,
  return `false` for ASC (nil goes after non-nil) and `true` for DESC (same effect — nil
  always last). Exact implementation: check `(a.primaryActivity == nil) ~=
  (b.primaryActivity == nil)` to handle the nil-last case before normal string comparison.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-player-list-column*
*Context gathered: 2026-03-25*
