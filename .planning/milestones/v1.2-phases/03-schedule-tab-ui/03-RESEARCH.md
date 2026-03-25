# Phase 3: Schedule Tab UI - Research

**Researched:** 2026-03-25
**Domain:** WoW Classic addon UI — Lua / UIDropDownMenu widget extension in TabSchedule.lua
**Confidence:** HIGH

## Summary

Phase 3 adds a third group box ("Activity") to the Schedule tab, below Date & Time. The group
contains a primary activity dropdown (always visible, required) and a conditional exact-activity
dropdown (shown only when Normal Dungeon, Heroic Dungeon, Raid, or PVP is selected; hidden for
Quest, Farm, Chill). All infrastructure is in place from Phases 1 and 2: activity data lives in
`OW.ACTIVITY_LIST` / `OW.ACTIVITY_SUBS`, the database layer already accepts `primaryActivity` and
`exactActivity`, and the UI layer's factory functions (`makeGroupBox`, `makeDropdown`, `lbl`) are
exactly what the new group needs.

The work is entirely within `UI/TabSchedule.lua` (add the third group, extend `onSave()`,
`TI.Reset()`, `TI.Populate()`) and `UI/Window.lua` (increase `WINDOW_H`). No new dependencies,
no network changes, no data layer changes.

**Primary recommendation:** Follow the established vertical-rhythm pattern exactly, derive all
heights arithmetically from the existing constants, and store the exact-activity label and dropdown
as upvalue widget refs so they can be shown/hidden with `:Show()` / `:Hide()`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Activity group box uses fixed height — always allocates room for both rows. No dynamic
  resizing; when exact dropdown is hidden the bottom simply has extra padding.
- **D-02:** Two labels: "Activity" above primary dropdown row, "Specific Activity" above
  exact-activity row. Mirrors the Date & Time group's per-row label style.
- **D-03:** Exact-activity dropdown is hidden (not disabled, not invisible-in-place) when Quest,
  Farm, or Chill is selected. The row (label + dropdown) is not shown at all. It appears only for
  Normal Dungeon, Heroic Dungeon, Raid, or PVP.
- **D-04:** Missing primary activity error text: "Select an activity." — flashes on Save button
  for 2.5 s then reverts.
- **D-05:** Primary activity is the only required activity field. Exact activity is optional.
- **D-06:** Primary dropdown items built from `OW.ACTIVITY_LIST` directly — do not hardcode order.
  Order: Normal Dungeon → Heroic Dungeon → Raid → PVP → Quest → Farm → Chill.
- **D-07:** `TI.Reset()` calls `:ClearValue()` on both activity dropdowns and hides the
  exact-activity row. Follows `ddSpec:ClearValue()` pattern.
- **D-08:** `TI.Populate()` restores `primaryActivity` and `exactActivity` from `myEntry`, then
  triggers the same show/hide logic as the primary dropdown's `onChange` handler.
- **D-09:** `OnlineWhen.SaveMyEntry(...)` call gains two trailing args: `primaryActivity,
  exactActivity`. `exactActivity` may be nil.

### Claude's Discretion

- Exact pixel heights for the Activity group box and resulting `WINDOW_H` delta — derive from the
  established vertical rhythm (CONTENT_Y, label 20px, dropdown 36px, INNER_PAD 12px).
- Unique frame names for the two new dropdowns (e.g. "OWDdActivity", "OWDdExactActivity").
- Whether the "Specific Activity" label and dropdown are stored as upvalue widget refs (same
  pattern as other dropdowns) or as a sub-frame toggled via :Show()/:Hide().
- Placeholder text for both dropdowns ("— Select —" is the established pattern).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHED-01 | Activity section appears at the bottom of the Schedule tab, inside a labeled group box | `makeGroupBox` factory is directly reusable; third group anchored below `dateTimeGroupY - dateTimeGroupHeight - 8` |
| SCHED-02 | Primary activity dropdown shows all 7 activities | Build items by iterating `OW.ACTIVITY_LIST`; value = label string (plain-string sub-type keying) |
| SCHED-03 | Selecting Normal Dungeon, Heroic Dungeon, Raid, or PVP reveals a second dropdown with relevant sub-options | `onChange` handler: `#OW.ACTIVITY_SUBS[v] > 0` → call `:SetItems()` + `:Show()` on exact-activity row |
| SCHED-04 | Selecting Quest, Farm, or Chill hides the exact activity dropdown entirely | `onChange` handler: `#OW.ACTIVITY_SUBS[v] == 0` → `:Hide()` exact-activity row; `:ClearValue()` on exact dd |
| SCHED-05 | Activity is required — Save blocked and error shown if no primary activity selected | Guard `if not selectedActivity then showError("Select an activity.") return end` in `onSave()` |
| SCHED-06 | Activity fields cleared/reset when form is reset (TI.Reset()) | `ddActivity:ClearValue()`, `ddExactActivity:ClearValue()`, hide exact row refs |
| SCHED-07 | Activity fields restored when form populated from existing entry (TI.Populate()) | Read `my.primaryActivity` / `my.exactActivity` from `OW.GetMyEntry()`, call show/hide logic |
| SCHED-08 | Main window height increased to accommodate new activity section | `WINDOW_H = 680` in `UI/Window.lua`; `contentAreaHeight` constant in `TI.Build()` updated to 632 |
</phase_requirements>

---

## Standard Stack

No third-party dependencies. This is a pure WoW Classic Lua UI phase.

### Core APIs in Use

| API / Function | Purpose | How Used |
|---------------|---------|----------|
| `UIDropDownMenu_*` WoW frame template | Dropdown widget | Via existing `makeDropdown` factory — no direct API calls needed |
| `makeGroupBox(parent, title, x, y, w, h)` | Styled group container | Call verbatim for the Activity group; returns parent frame |
| `makeDropdown(parent, name, items, default, x, y, w, onChange, placeholder)` | Dropdown with GetValue/SetValue/ClearValue/SetItems | Call for both activity dropdowns; onChange wires show/hide |
| `lbl(box, text, x, y)` | White FontString label | Call for "Activity" and "Specific Activity" labels |
| `showError(msg)` | Flash error on Save button 2.5 s | Call with "Select an activity." |
| `OW.ACTIVITY_LIST` | Ordered `{ id, label }` array | Iterate to build primary dropdown items |
| `OW.ACTIVITY_SUBS` | Label-keyed sub-type string arrays | Index by primary label to get exact items; `{}` for Quest/Farm/Chill |
| `OW.SaveMyEntry(name, spec, class, level, utcTs, tzId, primaryActivity, exactActivity)` | 8-param database write | Pass local upvalues for the last two args |

### No New Libraries Needed

The project has no package manager, no npm, no external Lua libraries. All tools are WoW Classic
game API or local addon factories already implemented. [HIGH confidence — verified by reading all
source files]

## Architecture Patterns

### Recommended Project Structure

No new files. Changes are limited to two existing files:

```
UI/
├── TabSchedule.lua   ← primary changes: TI.Build(), onSave(), TI.Reset(), TI.Populate()
└── Window.lua        ← single change: WINDOW_H constant
```

### Pattern 1: Third Group Box (mirrors Group 2 pattern)

**What:** Add Group 3 with its own `curY` counter, placed immediately below Group 2.
**When to use:** Any time a new visual group is added to the tab.

```lua
-- After Group 2 is built:
local activityGroupHeight = 152   -- derived below
local activityGroupY = dateTimeGroupY - dateTimeGroupHeight - 8  -- 8px gap

local activityGroup = makeGroupBox(parent, "Activity", groupMargin, activityGroupY, groupWidth, activityGroupHeight)

curY = CONTENT_Y   -- reset counter for this group

lbl(activityGroup, "Activity", contentLeft, curY)
curY = curY - 20

ddActivity = makeDropdown(activityGroup, "OWDdActivity", activityItems(), nil,
    contentLeft, curY, 200,
    function(v)
        selectedActivity = v
        local subs = OW.ACTIVITY_SUBS and OW.ACTIVITY_SUBS[v] or {}
        if #subs > 0 then
            ddExactActivity:SetItems(exactItemsForActivity(v))
            ddExactActivity:ClearValue()
            lblExactActivity:Show()
            ddExactActivity:Show()
        else
            ddExactActivity:ClearValue()
            lblExactActivity:Hide()
            ddExactActivity:Hide()
        end
    end,
    "— Select —")
curY = curY - 36

lblExactActivity = lbl(activityGroup, "Specific Activity", contentLeft, curY)
curY = curY - 20

ddExactActivity = makeDropdown(activityGroup, "OWDdExactActivity", {}, nil,
    contentLeft, curY, 200, nil, "— Select —")

lblExactActivity:Hide()
ddExactActivity:Hide()
```

### Pattern 2: Activity Item Builders

**What:** Two local builder functions following the same pattern as `specItemsForClass`,
`monthItems`, etc.

```lua
local function activityItems()
    local items = {}
    for _, act in ipairs(OW.ACTIVITY_LIST) do
        items[#items+1] = { value = act.label, label = act.label }
    end
    return items
end

local function exactItemsForActivity(activityLabel)
    local subs = OW.ACTIVITY_SUBS and OW.ACTIVITY_SUBS[activityLabel] or {}
    local items = {}
    for _, sub in ipairs(subs) do
        items[#items+1] = { value = sub, label = sub }
    end
    return items
end
```

Note: `value = act.label` (not `act.id`) because `OW.ACTIVITY_SUBS` is keyed by label string,
and `OW.SaveMyEntry` stores `primaryActivity` as the label string. Using the label as the value
avoids a second lookup.

### Pattern 3: Form Upvalue Storage

**What:** The exact-activity label and dropdown are stored as upvalues at module scope (alongside
`ddSpec`, `ddDay`, etc.) so `TI.Reset()` and `TI.Populate()` can access them without closures.

```lua
-- At module scope, add to the existing widget references block:
local ddActivity, ddExactActivity
local lblExactActivity
local selectedActivity = nil
```

### Pattern 4: onSave() Extension

**What:** Add activity guard immediately after the spec guard, following the existing
`if not field then showError(...) return end` pattern.

```lua
-- After selectedSpec guard, before date/time guards:
selectedActivity = ddActivity and ddActivity:GetValue()
if not selectedActivity then showError("Select an activity.") return end
local exactActivity = ddExactActivity and ddExactActivity:GetValue()

-- ... existing date/time guards ...

-- Change the SaveMyEntry call from 6 args to 8:
OnlineWhen.SaveMyEntry(name, selectedSpec, myClass, level, utcTs, selectedTzId,
    selectedActivity, exactActivity)
```

### Pattern 5: TI.Reset() Extension

**What:** Clear both activity dropdowns and hide the exact-activity row. Add at the end of the
existing `TI.Reset()` body.

```lua
if ddActivity      then ddActivity:ClearValue()      end
if ddExactActivity then ddExactActivity:ClearValue()  end
if lblExactActivity then lblExactActivity:Hide()      end
if ddExactActivity  then ddExactActivity:Hide()       end
selectedActivity = nil
```

### Pattern 6: TI.Populate() Extension

**What:** Restore activity fields and fire the same show/hide logic as the onChange handler.
Add at the end of the existing `TI.Populate()` body.

```lua
if ddActivity and my.primaryActivity then
    ddActivity:SetValue(my.primaryActivity)
    selectedActivity = my.primaryActivity
    local subs = OW.ACTIVITY_SUBS and OW.ACTIVITY_SUBS[my.primaryActivity] or {}
    if #subs > 0 then
        ddExactActivity:SetItems(exactItemsForActivity(my.primaryActivity))
        if my.exactActivity then ddExactActivity:SetValue(my.exactActivity) end
        if lblExactActivity then lblExactActivity:Show() end
        ddExactActivity:Show()
    else
        if lblExactActivity then lblExactActivity:Hide() end
        ddExactActivity:Hide()
    end
end
```

### Anti-Patterns to Avoid

- **Hardcoding activity order or sub-type lists:** Always read from `OW.ACTIVITY_LIST` and
  `OW.ACTIVITY_SUBS`. These tables are the single source of truth defined in Phase 1.
- **Using activity id (integer) as dropdown value:** The sub-type tables and database layer both
  use label strings. Use `act.label` as both value and label in dropdown items.
- **Dynamic group box resizing:** D-01 locks this as fixed height. Do not attempt to resize the
  group box when the exact row is shown/hidden.
- **Nil-check on ACTIVITY_SUBS[v]:** `OW.ACTIVITY_SUBS` guarantees `{}` (not nil) for
  Quest/Farm/Chill (Phase 1, D-05). A `#subs > 0` check is sufficient; no nil guard needed for
  valid activity labels.
- **Forgetting to hide exact row on first open:** After creating `ddExactActivity`, immediately
  call `lblExactActivity:Hide()` and `ddExactActivity:Hide()` — the group opens in collapsed state.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dropdown widget | Custom Frame with click handlers | `makeDropdown` factory (already in file) | Factory handles UIDropDownMenu internal 16px offset, placeholder, ClearValue, SetItems |
| Group box container | Raw Frame with manual borders/bg | `makeGroupBox` factory (already in file) | Factory handles accent bar, borders, title label, background texture |
| Show/hide pair logic | Sub-frame wrapper | Separate widget refs + `:Show()`/`:Hide()` calls | No wrapper frame needed; two direct calls is simpler and matches project style |
| Activity item list | Hardcoded `{ value, label }` array | `activityItems()` builder reading `OW.ACTIVITY_LIST` | Guarantees correct ordering (D-06) and stays in sync if list ever changes |

**Key insight:** Every UI primitive needed for this phase already exists as a factory or helper
in `TabSchedule.lua`. The implementation is assembly work, not invention.

## Pixel Arithmetic (Claude's Discretion — derived from established constants)

### Activity Group Height Derivation

Using the vertical rhythm documented in `TI.Build()` comments:
- Title area consumed by group header: `INNER_PAD to CONTENT_Y` = 28px
- "Activity" label row: 20px (`y -= 20`)
- Primary dropdown row: 36px (`y -= 36`)
- "Specific Activity" label row: 20px (`y -= 20`)
- Exact-activity dropdown row: 36px (`y -= 36`)
- Bottom padding: `INNER_PAD = 12px`

**`activityGroupHeight = 28 + 20 + 36 + 20 + 36 + 12 = 152`**

This height is fixed regardless of whether the exact row is shown or hidden (D-01).

### WINDOW_H and contentAreaHeight Derivation

Current values: `WINDOW_H = 520`, `contentAreaHeight = 472`.

The Activity group plus its gap between Group 2 and Group 3:
- `activityGroupHeight = 152`
- Gap between G2 and G3: 8px (same as gap between G1 and G2)
- Delta = `152 + 8 = 160`

**`WINDOW_H = 520 + 160 = 680`**
**`contentAreaHeight = 472 + 160 = 632`** (updated constant in `TI.Build()`)

The `dateTimeGroupHeight` formula re-derives as:
- `dateTimeGroupTopAbs = 6 + 90 + 8 = 104` (unchanged)
- New bottom space = `activityGroupHeight(152) + gap(8) + saveButtonPadding(14) + saveButtonHeight(28) + saveButtonPadding(14) = 216`
- `dateTimeGroupHeight = 632 - 104 - 216 = 312`

The Date & Time group height stays at **312** — no change needed. The Activity group slots in
below it in the newly expanded content area.

### Activity Group Y Position

```lua
local activityGroupY = dateTimeGroupY - dateTimeGroupHeight - 8
-- = (-6 - 90 - 8) - 312 - 8
-- = -104 - 312 - 8
-- = -424
```

## Common Pitfalls

### Pitfall 1: Exact dropdown items not reset on primary change

**What goes wrong:** Player selects "Raid" (shows exact dropdown), then changes to "Heroic
Dungeon". The exact dropdown still shows Raid sub-types.
**Why it happens:** `onChange` calls `:SetItems()` but `SetItems` has a "clamp to last item"
fallback (TabSchedule.lua line 164-169) — it will auto-select the last item of the new list if
currentValue is not found.
**How to avoid:** Call `ddExactActivity:ClearValue()` before `:SetItems()` when switching between
activities that both have sub-types. This resets `currentValue` to nil so SetItems won't
auto-clamp.
**Warning signs:** Exact dropdown shows a value from a different activity's list.

### Pitfall 2: Forgetting to update the `contentAreaHeight` constant

**What goes wrong:** `WINDOW_H` is updated in `Window.lua` but `contentAreaHeight` in
`TI.Build()` is not. The `dateTimeGroupHeight` derivation produces the wrong height, leaving
Date & Time group either too tall (overlapping Activity group) or too short (gap visible).
**Why it happens:** `contentAreaHeight` is a hardcoded derived constant (line 359), not computed
at runtime from `WINDOW_H`.
**How to avoid:** Update both `WINDOW_H` in `Window.lua` AND `contentAreaHeight` in
`TI.Build()` in the same change. Document the formula in a comment.

### Pitfall 3: Exact row visible on first open

**What goes wrong:** The exact-activity row appears on first open before any activity is selected.
**Why it happens:** Widgets are created visible by default in WoW; `:Hide()` must be called
explicitly.
**How to avoid:** Immediately after creating `lblExactActivity` and `ddExactActivity`, call
`:Hide()` on both before `TI.Build()` returns.

### Pitfall 4: TI.Populate() doesn't trigger show/hide for exact row

**What goes wrong:** Re-opening the Schedule tab with a saved "Raid" entry shows the Activity
field restored but the exact dropdown row remains hidden.
**Why it happens:** `TI.Populate()` restores values but doesn't replicate the onChange side-effect.
**How to avoid:** After calling `ddActivity:SetValue()`, run the same show/hide conditional
block that the onChange handler uses. This is explicitly required by D-08.

### Pitfall 5: selectedActivity upvalue not cleared in Reset

**What goes wrong:** Player resets the form; activity dropdown is visually cleared but
`selectedActivity` upvalue still holds the old value. On next Save the guard passes silently.
**Why it happens:** `ddActivity:ClearValue()` clears the widget's internal `currentValue` but
does not affect the upvalue `selectedActivity`.
**How to avoid:** Always set `selectedActivity = nil` in `TI.Reset()`, alongside
`ddActivity:ClearValue()`. Mirror the existing `selectedSpec = nil` pattern.

### Pitfall 6: Frame name collision for dropdowns

**What goes wrong:** Two addons (or two instances of OnlineWhen across sessions) create frames
with the same name, causing a Lua error.
**Why it happens:** `UIDropDownMenu` template requires a unique global frame name.
**How to avoid:** Use the "OWDd" prefix established by existing dropdowns: `"OWDdActivity"` and
`"OWDdExactActivity"`. These names are unique within the addon.

## Code Examples

Verified patterns from existing `UI/TabSchedule.lua`:

### Existing makeDropdown signature (verified, line 109)
```lua
-- Source: UI/TabSchedule.lua line 109
local function makeDropdown(parent, uniqueName, items, defaultValue, x, y, menuWidth, onChange, placeholder)
```

### Existing onSave() guard pattern (verified, line 237)
```lua
-- Source: UI/TabSchedule.lua line 237
selectedSpec = ddSpec and ddSpec:GetValue()
if not selectedSpec then showError(OW.L.ERR_NO_SPEC or "Select a spec.") return end
```

### Existing ClearValue pattern in TI.Reset() (verified, line 270)
```lua
-- Source: UI/TabSchedule.lua line 270
if ddSpec   then ddSpec:ClearValue() end
selectedSpec = nil
```

### Existing SetValue restore in TI.Populate() (verified, line 485)
```lua
-- Source: UI/TabSchedule.lua line 485
if ddSpec and my.spec then ddSpec:SetValue(my.spec); selectedSpec = my.spec end
```

### OW.SaveMyEntry 8-param signature (verified, Database.lua line 20)
```lua
-- Source: Core/Database.lua line 20
function OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId, primaryActivity, exactActivity)
```

### OW.ACTIVITY_SUBS empty-table guarantee (verified, Data/Activities.lua lines 113-115)
```lua
-- Source: Data/Activities.lua lines 113-115
["Quest"] = {},
["Farm"]  = {},
["Chill"] = {},
```

### Existing curY reset between groups (verified, TI.Build() line 413)
```lua
-- Source: UI/TabSchedule.lua line 413
curY = CONTENT_Y  -- reset counter when starting a new group
```

## State of the Art

No changes to libraries or WoW API usage. Phase 3 is a pure UI assembly task on top of
infrastructure already built in Phases 1 and 2.

| Old State | New State | Changed In | Impact |
|-----------|-----------|------------|--------|
| `onSave()` calls `SaveMyEntry` with 6 args | Calls with 8 args | Phase 3 | activity fields written to DB on save |
| Schedule tab has 2 groups + Save button | 3 groups + Save button | Phase 3 | window height increases by 160px |
| `TI.Reset()` clears spec + date/time | Also clears activity fields | Phase 3 | form fully resets |
| `TI.Populate()` restores spec + date/time | Also restores activity fields | Phase 3 | re-open restores all fields |

## Open Questions

None. All decisions were locked in CONTEXT.md, source files verified, and pixel arithmetic
fully derived. No unresolved ambiguity.

## Environment Availability

Step 2.6: SKIPPED — this phase is purely code/config changes within two existing Lua files.
No external tools, services, runtimes, CLIs, databases, or package managers are required.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — WoW addon; no automated test runner found in project |
| Config file | None |
| Quick run command | Manual in-client smoke test |
| Full suite command | Manual in-client smoke test |

No automated test files (`*.test.*`, `*.spec.*`, `tests/`, etc.) exist anywhere in the project.
WoW addon Lua cannot be unit-tested outside the game client without a test harness (e.g., busted
with WoW API stubs), and none is configured. All validation for this phase is manual in-client.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| SCHED-01 | Activity group box visible in Schedule tab | manual | — | Open Schedule tab, confirm group visible |
| SCHED-02 | Primary dropdown shows 7 activities | manual | — | Click dropdown, count items |
| SCHED-03 | Selecting dungeon/raid/pvp shows exact dropdown | manual | — | Select each activity with sub-types |
| SCHED-04 | Selecting quest/farm/chill hides exact dropdown | manual | — | Select each activity without sub-types |
| SCHED-05 | Save blocked with no activity, error shown | manual | — | Click Save with no activity selected |
| SCHED-06 | Reset clears both activity fields | manual | — | Save, confirm reset clears activity row |
| SCHED-07 | Re-open restores activity fields | manual | — | Save, re-open tab, confirm fields populated |
| SCHED-08 | Window tall enough, no clipping | manual | — | Open window, verify Activity group fully visible |

### Sampling Rate

- **Per task commit:** Visual inspection in-client (reload UI, open Schedule tab)
- **Per wave merge:** Full manual smoke test of all 8 SCHED requirements
- **Phase gate:** All 8 manual checks pass before `/gsd:verify-work`

### Wave 0 Gaps

None — no automated test infrastructure exists or is needed for this phase. The project has no
test runner and WoW Classic addon testing is inherently manual.

## Sources

### Primary (HIGH confidence)

- `UI/TabSchedule.lua` — full source read; all factory functions, constants, patterns, and
  integration points verified directly
- `UI/Window.lua` — full source read; `WINDOW_H = 520`, `WINDOW_W = 800`, `INSET = 6`,
  `TAB_H = 32` verified
- `Data/Activities.lua` — full source read; `OW.ACTIVITY_LIST` order, `OW.ACTIVITY_SUBS`
  structure, empty-table guarantee for Quest/Farm/Chill verified
- `Core/Database.lua` — full source read; 8-param `OW.SaveMyEntry` signature verified
- `.planning/phases/03-schedule-tab-ui/03-CONTEXT.md` — all locked decisions read and copied

### Secondary (MEDIUM confidence)

None required — all decisions were resolved by reading source directly.

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external libraries; all APIs verified by source read
- Architecture: HIGH — all patterns derived directly from existing code in the same file
- Pitfalls: HIGH — derived from code inspection (SetItems clamp behavior, upvalue/widget split)
- Pixel arithmetic: HIGH — derived arithmetically from constants verified in source

**Research date:** 2026-03-25
**Valid until:** Stable — pure in-repo Lua; valid until TabSchedule.lua or Window.lua is refactored
