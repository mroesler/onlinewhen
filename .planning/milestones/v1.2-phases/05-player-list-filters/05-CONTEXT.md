# Phase 5: Player List Filters - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a second filter row below the existing Status/Level/Class/Spec row in the player list.
The second row contains a primary activity dropdown and a cascading exact activity dropdown.
The exact dropdown is disabled until a primary activity with sub-types is selected —
mirrors the class→spec cascade exactly. "Reset Filters" (row 1, right-aligned) clears all
6 filters. No changes to network, data, schedule tab, or column rendering layers.

</domain>

<decisions>
## Implementation Decisions

### Reset Filters Placement
- **D-01:** The existing "Reset Filters" button **stays on row 1, right-aligned**. One button
  resets all 6 filters (row 1: status, level, class, spec; row 2: primary activity, exact
  activity). Consistent with current layout — no second button added.

### Exact Activity Filter Label
- **D-02:** Disabled state placeholder: **"Any Exact Activity"**. Follows the "Any X" naming
  pattern but spells out the full dimension name. Active state (after a primary with sub-types
  is selected) shows the same default until a sub-type is chosen.

### Row 2 Dropdown Widths
- **D-03:** Primary activity dropdown: **180px**. Exact activity dropdown: **220px**. Wider
  than row 1 (130px) to accommodate long activity names ("Normal Dungeon", "Heroic Dungeon")
  and sub-type labels ("Serpentshrine Cavern", "Black Temple"). Both anchored at TOPLEFT of
  the second filter row.

### Filter State Variables
- **D-04:** Two new module-level locals: `filterPrimaryActivity` (string label or nil) and
  `filterExactActivity` (string label or nil). Nil = no filter applied. Consistent with
  `filterClass`, `filterSpec` pattern.

### applyFilters() Logic
- **D-05:** AND logic — both activity filters stack with existing filters. Primary activity
  filter matches on `entry.primaryActivity`; exact activity filter matches on
  `entry.exactActivity`. Both nil-safe (no filter = show all).

### Cascade Behavior (mirrors class→spec exactly)
- **D-06:** Primary activity onChange:
  - If selected activity has sub-types (`OW.ACTIVITY_SUBS[label]` is non-empty): enable exact
    dropdown, call `.setChoices()` with sub-type strings + "Any Exact Activity", call
    `.setActive(true)`.
  - If Quest/Farm/Chill (empty sub-type list): clear exact filter, call
    `.setChoices({ "Any Exact Activity" })`, call `.setActive(false)`.
  - Changing primary always clears `filterExactActivity = nil` before Refresh.
- **D-07:** Reset Filters additionally calls `exactActivityFilterBtn.setChoices(...)` reset
  and `exactActivityFilterBtn.setActive(false)` — same as specFilterBtn reset in existing code.

### Vertical Layout
- **D-08:** Second filter row sits immediately below row 1. Layout constants must expand to
  account for a second row of height FILTER_H (28px) plus a gap between the two rows.
  `columnHeaderY`, `contentFrame`, and `divider` anchors all shift down by the additional
  row height + gap. Claude chooses the gap size consistent with existing FILTER_TOP_PAD /
  FILTER_BOT_PAD values.

### Claude's Discretion
- Exact gap between filter row 1 and row 2 (derive from existing FILTER_TOP_PAD / FILTER_BOT_PAD)
- X-offset of primary activity dropdown on row 2 (start at 0, same as statusFilterBtn)
- Whether to introduce a `FILTER_H2` constant or reuse `FILTER_H` for the second row

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files being modified
- `UI/TabPlayers.lua` — all filter state variables, `applyFilters()`, `TL.Build()` (filter
  bar construction, `columnHeaderY`, `contentFrame`, `divider` anchors), and Reset Filters
  `OnClick` handler.

### Read-only references
- `Data/Activities.lua` — `OW.ACTIVITY_LIST` (ordered array of `{ id, label }`) and
  `OW.ACTIVITY_SUBS` (keyed by label → array of sub-type strings or `{}`). Primary source
  of truth for dropdown choices and cascade logic.
- `Core/Database.lua` — `entry.primaryActivity` and `entry.exactActivity` field names used
  in `applyFilters()` comparisons.

### Planning and conventions
- `.planning/ROADMAP.md` §Phase 5 — success criteria SC1–SC5 and the three plan outlines
- `.planning/phases/04-player-list-column/04-CONTEXT.md` — confirmed `CONTENT_W = 938`,
  `WINDOW_W = 950`; filter bar anchors at `parent` width which is now 938px
- `.planning/phases/01-data-foundation/01-CONTEXT.md` — `OW.ACTIVITY_SUBS` empty-table
  guarantee for Quest/Farm/Chill; plain string values (not `{ id, label }` pairs)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `makeDropdown(parent, width, defaultText, choices, onChange)` (line 300) — closure-based
  factory already in TabPlayers. Returns a button with `.setChoices(newChoices, newLabel)`
  and `.setActive(bool)`. Use verbatim for both row 2 dropdowns.
- `setActive(false)` visual: dims background to `(0.08, 0.08, 0.10)` and text to
  `(0.35, 0.35, 0.4)` — already handles the greyed-out inactive appearance.
- Class onChange handler (lines 566–587) — the exact cascade template: sets `filterSpec = nil`,
  calls `specFilterBtn.setChoices(...)` and `specFilterBtn.setActive(false/true)`. Activity
  cascade replicates this pattern with `filterExactActivity`.

### Established Patterns
- Filter state locals: `filterStatus`, `filterLevel`, `filterClass`, `filterSpec` — all nil
  by default, checked in `applyFilters()` AND logic (line 454+).
- `filterBarY` is derived: `-(FILTER_TOP_PAD + math.floor((FILTER_H - 22) / 2))` = -11.
- `columnHeaderY = -(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD)` = -44. Adding a second
  row pushes this further negative.
- Row 1 x-offsets: Status(0), Level(130), Class(288), Spec(428), Reset(TOPRIGHT).

### Integration Points
- `applyFilters()` — add `filterPrimaryActivity` and `filterExactActivity` checks after
  existing spec check, same nil-guard pattern.
- `TL.Build()` filter bar section (line 524+) — add row 2 dropdown construction after
  specFilterBtn and before/after resetBtn (Reset stays on row 1).
- Reset Filters `OnClick` (line 617+) — add `filterPrimaryActivity = nil`,
  `filterExactActivity = nil`, reset exact dropdown choices and call `.setActive(false)`.
- Forward refs: declare `primaryActivityFilterBtn` and `exactActivityFilterBtn` as module-
  level locals (same as `specFilterBtn`) so the Reset handler can reference them.

</code_context>

<specifics>
## Specific Ideas

- Row 2 layout: `[Primary Activity 180px] [Exact Activity 220px]` left-aligned; Reset Filters
  stays right-aligned on row 1 only.
- "Any Exact Activity" is the exact placeholder string for the exact activity dropdown in
  both enabled and disabled states (before a sub-type is chosen).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-player-list-filters*
*Context gathered: 2026-03-25*
