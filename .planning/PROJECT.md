# OnlineWhen — Activity Scheduling Feature

## What This Is

OnlineWhen is a TBC Classic Anniversary WoW addon that lets guild/group players coordinate online schedules. Players save when they plan to be online along with their spec, and a shared player list shows all scheduled players with their class, spec, and time — synced peer-to-peer over a shared channel.

This milestone adds an **activity system**: players pick what they plan to do (Quest, PVP, Dungeon, Raid, Farm, Chill) with a dependent sub-type selector for content-specific choices (which dungeon, raid, battleground). This information is displayed in the player list and is filterable.

## Core Value

Players can immediately see not just *when* someone is online but *what they plan to do* — enabling at-a-glance group formation.

## Requirements

### Validated

- ✓ Players can save a schedule entry with name, level, class, spec, and online time — existing
- ✓ Entries are synced peer-to-peer over a shared channel (ANN/REQ/BYE protocol) — existing
- ✓ Player list table shows all peers with status, name, level, class, spec, time — existing
- ✓ Filters for status, level, class, and spec in the player list — existing
- ✓ Spec filter cascades from class selection (disabled until class chosen, clears on class change) — existing
- ✓ Online/offline grace period (30 min) with faded past entries — existing
- ✓ Pagination (12 rows/page), sortable columns, invite button for online players — existing

### Validated

- ✓ Activity data file with TBC Classic Anniversary content: 7 primary activities, dungeon/raid/BG sub-types — Validated in Phase 1: Data Foundation
- ✓ Activity fields (primaryActivity, exactActivity) stored in entry records and transmitted via 12-field ANN wire message; backward-compatible with old clients — Validated in Phase 2: Database + Protocol
- ✓ Activity selection section in Schedule tab with primary dropdown (7 activities), conditional exact-activity dropdown, required validation, and save/reset/populate lifecycle — Validated in Phase 3: Schedule Tab UI

### Validated

- ✓ "Activity" column added to player list after Spec column (primary + exact on two lines) — Validated in Phase 4: Player List Column
- ✓ Activity column sortable by exact activity (falls back to primary if no exact) — Validated in Phase 4: Player List Column
- ✓ Main window wider to accommodate new column — Validated in Phase 4: Player List Column
- ✓ Entries without activity (old protocol peers) show blank in Activity column — Validated in Phase 4: Player List Column
- ✓ Second filter row in player list: primary activity filter + exact activity filter — Validated in Phase 5: Player List Filters
- ✓ Exact activity filter cascades from primary selection (same pattern as spec/class) — Validated in Phase 5: Player List Filters
- ✓ Activity filters reset when "Reset Filters" is clicked — Validated in Phase 5: Player List Filters

### Active

(all milestone requirements validated)

### Out of Scope

- Custom activity labels — predefined list only, no free-text entry
- Activity icons or color coding — text-only for simplicity
- Multiple simultaneous activities per entry — one primary + one exact per entry
- Activity history or logging — only current/next scheduled activity

## Context

- **Existing codebase:** Brownfield addon at v1.1.0. Well-structured with clear layer separation: Data enums → Core state → Network → UI.
- **Spec/class pattern:** The class→spec cascade (filter disabled until class selected, clears on class change) is the established UX pattern for dependent dropdowns. Activity→exact-activity must follow exactly this pattern.
- **Network protocol:** Current wire format uses 10 semicolon-delimited fields. Adding activity requires appending fields (backward-compatible: old peers omit, new client treats missing as blank).
- **No existing TBC content data:** Dungeons, raids, and battleground lists must be authored fresh in a new `Data/Activities.lua` file.
- **Window sizing:** Current window is 800×520. The new Activity column and schedule section require both width (new table column) and height (new form section) expansion. All layout values are local constants — changing `WINDOW_W`/`WINDOW_H` and column widths cascades correctly.
- **Dropdown pattern:** Two distinct dropdown implementations exist — `makeDropdown` in TabSchedule (returns object with `:GetValue()`/`:SetValue()`) vs. a simpler closure-based dropdown in TabPlayers. Activity dropdowns in each tab use the appropriate existing pattern.

## Constraints

- **Tech stack:** Pure Lua 5.1, WoW TBC Classic Anniversary API only — no external libraries
- **No SendAddonMessage:** Not available in TBC Classic; sync uses channel chat messages (`SendChatMessage`)
- **Backward compatibility:** Protocol must degrade gracefully — peers running old versions omit activity fields; new client shows blank for those entries
- **WoW API:** `UIDropDownMenuTemplate` for dropdowns, standard Frame/FontString/Texture for all UI elements
- **No external assets:** Cannot load new textures or sound files — text/color only

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Hide exact-activity dropdown for Quest/Farm/Chill | Cleaner UX — no "N/A" placeholder needed when there's nothing to select | — Pending |
| Show blank (not "Unknown") for missing activity in old peer entries | Graceful degradation; avoids false signal that activity is set but unknown | — Pending |
| Append activity fields to protocol wire format | Backward-compatible; old clients can still parse the first 10 fields | — Pending |
| New `Data/Activities.lua` file for TBC content | Follows existing pattern (Timezones.lua, Specs.lua) — data separate from UI | ✓ Done — Phase 1 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 after Phase 5: Player List Filters complete — all milestone requirements validated*
