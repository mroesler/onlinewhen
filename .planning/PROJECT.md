# OnlineWhen — WoW TBC Classic Addon

## What This Is

OnlineWhen is a TBC Classic Anniversary WoW addon that lets guild/group players coordinate online schedules. Players save when they plan to be online along with their class, spec, and activity (what they plan to do). A shared player list shows all scheduled players with their status, class, spec, activity, and time — synced peer-to-peer over a shared channel. Players can filter the list by class, spec, status, level, and activity type.

## Core Value

Players can immediately see not just *when* someone is online but *what they plan to do* — enabling at-a-glance group formation.

## Current State

**Shipped:** v1.2 Activity System (2026-03-25)

- Window: 950×680px
- 5 sortable columns: Status, Name, Level, Spec, Activity
- 6 filter dropdowns across 2 rows (status, level, class, spec; primary activity, exact activity)
- 12-field ANN wire protocol; backward-compatible with pre-v1.2 peers
- Activity data: 7 primary activities, 45 sub-types (16 Normal Dungeons, 16 Heroic Dungeons, 9 Raids, 4 BGs)

## Requirements

### Validated

**Pre-v1.2 (existing features):**
- ✓ Players can save a schedule entry with name, level, class, spec, and online time
- ✓ Entries are synced peer-to-peer over a shared channel (ANN/REQ/BYE protocol)
- ✓ Player list table shows all peers with status, name, level, class, spec, time
- ✓ Filters for status, level, class, and spec in the player list
- ✓ Spec filter cascades from class selection (disabled until class chosen, clears on class change)
- ✓ Online/offline grace period (30 min) with faded past entries
- ✓ Pagination (12 rows/page), sortable columns, invite button for online players

**v1.2 Activity System:**
- ✓ Activity data file with TBC Classic Anniversary content: 7 primary activities, dungeon/raid/BG sub-types — Phase 1
- ✓ Activity fields (primaryActivity, exactActivity) stored in entries and transmitted via 12-field ANN; backward-compatible with old clients — Phase 2
- ✓ Activity selection in Schedule tab with primary dropdown, conditional exact-activity dropdown, required validation, and save/reset/populate lifecycle — Phase 3
- ✓ Activity column in player list after Spec column (primary + exact on two lines), sortable by exact activity — Phase 4
- ✓ Second filter row with cascading primary/exact activity filters and Reset Filters integration — Phase 5

### Active

(planning next milestone)

### Out of Scope

- Custom activity labels — predefined list only; free-text creates sync/filter complexity
- Activity icons or color coding — text-only to stay consistent with existing UI style
- Multiple simultaneous activities per entry — one activity per entry keeps the data model simple
- Activity history or logging — only current scheduled activity

## Context

- **Codebase:** ~2,200 LOC Lua. Clear layer separation: Data enums → Core state → Network → UI.
- **Two dropdown patterns:** `makeDropdown` (closure-based, TabPlayers) vs. `OW_Dropdown` wrapper (TabSchedule). Both are established — new features use whichever tab they live in.
- **Backward compatibility confirmed:** 10-field ANNs (old clients) accepted without error; new client shows blank activity for those peers.
- **Window sizing settled:** 950×680. Layout constants (`WINDOW_W`, `WINDOW_H`, `COL_X`, `COL_W`) are the single source of truth — changing them cascades correctly.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| New `Data/Activities.lua` for TBC content | Follows existing pattern (Timezones.lua, Specs.lua) — data separate from UI | ✓ Good — Phase 1 |
| Append activity fields to ANN wire format | Backward-compatible; old clients parse first 10 fields without error | ✓ Good — Phase 2 |
| Hide exact-activity dropdown for Quest/Farm/Chill | Cleaner UX — no "N/A" placeholder when nothing to select | ✓ Good — Phase 3 |
| Show blank (not "Unknown") for missing activity in old peer entries | Avoids false signal; graceful degradation | ✓ Good — Phase 4 |
| `value = act.label` (not `act.id`) for activity filter choices | Filter compares against entry.primaryActivity which is a label string | ✓ Good — Phase 5 |
| Worktree isolation for parallel executor agents | Prevents git conflicts during multi-agent execution | ✓ Good — GSD workflow |

## Constraints

- **Tech stack:** Pure Lua 5.1, WoW TBC Classic Anniversary API only — no external libraries
- **No SendAddonMessage:** Not available in TBC Classic; sync uses `SendChatMessage`
- **Backward compatibility:** Protocol degrades gracefully — old peers omit activity fields; new client shows blank
- **WoW API:** `UIDropDownMenuTemplate` for dropdowns, standard Frame/FontString/Texture for all UI elements
- **No external assets:** Cannot load textures or sound files — text/color only

## Evolution

**After each phase transition:**
1. Requirements validated? → Move to Validated with phase reference
2. New requirements emerged? → Add to Active
3. Decisions to log? → Add to Key Decisions

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current codebase state

---
*Last updated: 2026-03-25 after v1.2 Activity System milestone complete*
