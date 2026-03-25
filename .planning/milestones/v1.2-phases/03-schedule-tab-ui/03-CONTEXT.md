# Phase 3: Schedule Tab UI - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an "Activity" group box to the Schedule tab — a third group below Date & Time containing
a primary activity dropdown and a conditional exact-activity dropdown. Wire into `onSave()`
(validation), `TI.Reset()` (clear), and `TI.Populate()` (restore). Increase `WINDOW_H` in
`UI/Window.lua` to accommodate the new group. No changes to network or data layers.

</domain>

<decisions>
## Implementation Decisions

### Activity Group Layout
- **D-01:** The Activity group box uses **fixed height** — always allocates room for both the
  primary row and the exact-activity row. When the exact dropdown is hidden (Quest/Farm/Chill),
  the group box height does not change; the bottom simply has extra padding. No dynamic resizing.
- **D-02:** The group box uses **two labels**: "Activity" above the primary dropdown row, and
  "Specific Activity" above the exact-activity dropdown row. Mirrors the Date & Time group's
  per-row label style (e.g. "Date", "Time", "Timezone").
- **D-03:** The exact-activity dropdown is **hidden** (not disabled, not invisible-in-place) when
  Quest, Farm, or Chill is selected — the row (label + dropdown) is not shown at all. It appears
  only for Normal Dungeon, Heroic Dungeon, Raid, or PVP.

### Validation & Error
- **D-04:** Missing primary activity error text: **"Select an activity."** — matches the
  "Select a spec." pattern. Flashes on the Save button for 2.5 s then reverts.
- **D-05:** Primary activity is the only required activity field. Exact activity is optional —
  Save is not blocked if an exact sub-type is not selected (it serializes as empty/nil).

### Activity Ordering (carried from Phase 1, D-01)
- **D-06:** Primary dropdown items follow the Phase 1 ordering:
  Normal Dungeon → Heroic Dungeon → Raid → PVP → Quest → Farm → Chill.
  Built from `OW.ACTIVITY_LIST` directly — do not hardcode order.

### Reset & Populate
- **D-07:** `TI.Reset()` calls `:ClearValue()` on both activity dropdowns and hides the
  exact-activity row (same way it would be hidden on first open). Follows the existing
  `ddSpec:ClearValue()` pattern.
- **D-08:** `TI.Populate()` restores `primaryActivity` and `exactActivity` from `myEntry`,
  then triggers the same show/hide logic as the primary dropdown's `onChange` handler —
  so if the restored activity has sub-types, the exact row is shown and populated.

### onSave() Integration
- **D-09:** `OnlineWhen.SaveMyEntry(...)` call gains two trailing args: `primaryActivity,
  exactActivity`. `exactActivity` may be nil if no sub-type was selected or the activity
  has none (Quest/Farm/Chill).

### Claude's Discretion
- Exact pixel heights for the Activity group box and resulting `WINDOW_H` delta — derive from
  the established vertical rhythm (CONTENT_Y, label 20px, dropdown 36px, INNER_PAD 12px)
- Unique frame names for the two new dropdowns (e.g. "OWDdActivity", "OWDdExactActivity")
- Whether the "Specific Activity" label and dropdown are stored as upvalue widget refs (same
  pattern as other dropdowns) or as a sub-frame toggled via :Show()/:Hide()
- Placeholder text for both dropdowns ("— Select —" is the established pattern)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files being modified
- `UI/TabSchedule.lua` — `TI.Build()`, `onSave()`, `TI.Reset()`, `TI.Populate()` are all
  being extended. Also contains `makeGroupBox` and `makeDropdown` factory functions that the
  Activity group must use verbatim.
- `UI/Window.lua` — `WINDOW_H` constant (currently 520) must increase; `contentAreaHeight`
  and `dateTimeGroupHeight` in `UI/TabSchedule.lua` are derived from it.

### Read-only references
- `Data/Activities.lua` — source of `OW.ACTIVITY_LIST` (ordered `{ id, label }` array) and
  `OW.ACTIVITY_SUBS` (keyed by activity label → array of sub-type strings or `{}`).
- `Core/Database.lua` — `OW.SaveMyEntry` now accepts 8 params ending in `primaryActivity,
  exactActivity` (extended in Phase 2). Phase 3 must pass both when calling it.

### Planning and conventions
- `.planning/ROADMAP.md` §Phase 3 — success criteria SC1–SC8 are the acceptance test
- `.planning/phases/01-data-foundation/01-CONTEXT.md` — activity ordering (D-01), sub-type
  list structure, and `OW.ACTIVITY_SUBS` empty-table guarantee for Quest/Farm/Chill
- `.planning/phases/02-database-protocol/02-CONTEXT.md` — `OW.SaveMyEntry` 8-param
  signature; empty-string-to-nil mapping for activity fields on deserialize

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `makeGroupBox(parent, title, x, y, w, h)` — returns a styled frame with accent top bar,
  borders, and title label. Used for Character and Date & Time groups; Activity group uses it identically.
- `makeDropdown(parent, uniqueName, items, defaultValue, x, y, menuWidth, onChange, placeholder)`
  — returns a dd object with `:GetValue()`, `:SetValue()`, `:ClearValue()`, `:SetItems()`.
  `placeholder` arg shows text when no item is selected (use `"— Select —"`).
- `lbl(box, text, x, y)` — creates a white FontString label at the given position inside a box.
- `showError(msg)` — flashes msg on the Save button for 2.5 s; already defined at module scope.

### Established Patterns
- Vertical rhythm inside a group: `CONTENT_Y = -28`, label row `y -= 20`, dropdown row `y -= 36`,
  bottom padding `INNER_PAD = 12`. Fixed height = sum of all rows + padding.
- `dateTimeGroupHeight` is calculated as a derived constant from `contentAreaHeight` and the
  groups above it — will need re-derivation once the Activity group height is known.
- Save button is anchored to `BOTTOM` of the tab content frame — it stays fixed regardless of
  group heights above it.
- `onSave()` guard pattern: `if not field then showError("...") return end`

### Integration Points
- `onSave()` line 255: `OnlineWhen.SaveMyEntry(name, selectedSpec, myClass, level, utcTs, selectedTzId)`
  → extend to 8 args: `..., selectedTzId, primaryActivity, exactActivity)`
- `TI.Reset()` currently clears spec and date/time fields — add `ddActivity:ClearValue()`,
  `ddExactActivity:ClearValue()`, and hide the exact-activity row.
- `TI.Populate()` currently restores spec and date/time — add activity field restore + show/hide trigger.
- `TI.Build()` currently builds two groups — add a third group with its own `curY` counter.

</code_context>

<specifics>
## Specific Ideas

- "Activity" and "Specific Activity" are the exact label strings for the two dropdown rows.
- Activity group height must be **fixed** — derive from the vertical rhythm constants so the
  calculation is consistent with the existing charGroupHeight/dateTimeGroupHeight derivations.
- The exact-activity row (label + dropdown) should be stored as widget refs so they can be
  shown/hidden together. Hiding both the label and the dropdown when not applicable keeps the
  implementation clean.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-schedule-tab-ui*
*Context gathered: 2026-03-25*
