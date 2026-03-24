# Codebase Structure

**Analysis Date:** 2026-03-24

## Directory Layout

```
OnlineWhen/
├── OnlineWhen.toc          # Addon manifest: interface version, metadata, load order
├── Locales/
│   └── enUS.lua            # All user-facing strings (OW.L)
├── Data/
│   └── Timezones.lua       # Timezone table, UTC conversion and formatting utilities
├── Core/
│   ├── Status.lua          # OW.STATUS enum + OW.playerStatus session table
│   ├── Classes.lua         # OW.CLASS enum, color table, token→name lookups
│   ├── Specs.lua           # OW.SPEC enum, OW.CLASS_SPECS, OW.SPEC_ID, OW.SPEC_NAME
│   ├── Database.lua        # All SavedVariables read/write — single source of truth
│   ├── Commands.lua        # /ow and /onlinewhen slash commands, debug output
│   └── Init.lua            # Addon lifecycle: event frame, OnLogin, OnLogout
├── Network/
│   └── Protocol.lua        # Peer-to-peer sync engine (channel management, serialization, handlers)
├── UI/
│   ├── Window.lua          # Main window frame, tab chrome, position persistence
│   ├── TabSchedule.lua     # Schedule form tab (date/time/spec dropdowns, save logic)
│   └── TabPlayers.lua      # Player list tab (sortable table, filters, pagination, invite)
├── Deployment/
│   ├── changelog.md        # User-facing release notes
│   ├── release.ps1         # PowerShell: packages addon zip for CurseForge upload
│   └── sync.ps1            # PowerShell: syncs source to local WoW AddOns directory
└── .planning/
    └── codebase/           # GSD codebase analysis documents
```

## Load Order

Defined in `OnlineWhen.toc`. Files execute in this exact sequence:

| Order | File | Establishes |
|-------|------|-------------|
| 1 | `Locales/enUS.lua` | `OW.L` |
| 2 | `Data/Timezones.lua` | `OW.Timezones`, `OW.DEFAULT_TIMEZONE`, conversion functions |
| 3 | `Core/Status.lua` | `OW.STATUS`, `OW.playerStatus`, `OW.GetStatusForEntry` |
| 4 | `Core/Classes.lua` | `OW.CLASS`, `OW.CLASS_ID`, `OW.CLASS_TOKEN_NAME`, `OW.CLASS_NAME`, `OW.CLASS_COLOR` |
| 5 | `Core/Specs.lua` | `OW.SPEC`, `OW.CLASS_SPECS`, `OW.SPEC_ID`, `OW.SPEC_NAME` |
| 6 | `Core/Database.lua` | `OW.EnsureDefaults`, `OW.GetMyEntry`, `OW.SaveMyEntry`, `OW.UpsertPeer`, `OW.GetAllEntries`, `OW.PurgeStalePeers`, `OW.PurgeExpiredPeers` |
| 7 | `Network/Protocol.lua` | `OW.Protocol` (requires `OW.CLASS_SPECS` from step 5) |
| 8 | `UI/Window.lua` | `OW.UI` |
| 9 | `UI/TabSchedule.lua` | `OW.TabSchedule` |
| 10 | `UI/TabPlayers.lua` | `OW.TabPlayers` |
| 11 | `Core/Commands.lua` | Slash command registration |
| 12 | `Core/Init.lua` | Event frame, `OW.OnLogin`, `OW.OnLogout`; exposes `OnlineWhen = OW` globally |

**Rule:** Anything referenced by a file must be established in an earlier load-order slot. `Core/Init.lua` loads last because it depends on everything.

## Key File Locations

**Addon Manifest:**
- `OnlineWhen.toc`: Interface version (20504 = TBC Classic 2.5.4), `SavedVariables: OnlineWhenDB`, load order

**Entry Point / Lifecycle:**
- `Core/Init.lua`: Registers WoW events, contains `OW.OnLogin` and `OW.OnLogout`, exposes `OnlineWhen` global

**Persistent Data:**
- `Core/Database.lua`: All `OnlineWhenDB` reads and writes; the only file that should touch `OnlineWhenDB` directly

**Network:**
- `Network/Protocol.lua`: Wire protocol, channel join/management, all send/receive/validate logic

**UI Shell:**
- `UI/Window.lua`: Creates `OnlineWhenMainFrame`, tab button strip, content frames; delegates to tab modules for content

**Schedule Tab:**
- `UI/TabSchedule.lua`: Form with class/spec/date/time/timezone dropdowns; calls `OW.SaveMyEntry` on submit

**Player List Tab:**
- `UI/TabPlayers.lua`: Sortable, filterable, paginated table (12 rows/page); columns: status, name, level, class, spec, time, actions (invite button)

**Static Data:**
- `Data/Timezones.lua`: Timezone list + UTC conversion and formatting functions (`BuildUTCTimestamp`, `UTCToLocal`, `FormatTimeOnly`)
- `Core/Classes.lua`: Class enum, colors, token→name map
- `Core/Specs.lua`: Spec enum and per-class spec lists

**Localization:**
- `Locales/enUS.lua`: `OW.L` table with all UI strings; add keys here for new text

## Directory Purposes

**`Core/`:**
- Purpose: Addon backbone — state management, data definitions, lifecycle, commands
- Contains: Enums, SavedVariables API, event handling, slash commands
- Key constraint: No WoW frame creation here; UI lives exclusively in `UI/`

**`Data/`:**
- Purpose: Static data tables and pure-Lua utilities that have no WoW API dependencies
- Contains: Timezone definitions and timestamp math

**`Locales/`:**
- Purpose: All user-visible strings, keyed by constant name
- Contains: One file per locale; currently only `enUS.lua`

**`Network/`:**
- Purpose: All addon communication; isolated from UI concerns
- Contains: Channel lifecycle, message serialization/validation, send/receive handlers

**`UI/`:**
- Purpose: All WoW frame creation and rendering
- Contains: Main window shell plus one file per tab

**`Deployment/`:**
- Purpose: Developer tooling; not loaded by the WoW client
- Contains: Release packaging script (`release.ps1`), local sync script (`sync.ps1`), changelog

## Naming Conventions

**Files:**
- PascalCase: `TabPlayers.lua`, `Protocol.lua`, `Database.lua`
- One module per file; filename matches the module it creates on `OW`

**Directories:**
- PascalCase single-word: `Core/`, `Data/`, `Network/`, `UI/`, `Locales/`

**Lua identifiers:**
- Module tables: PascalCase (`OW.TabPlayers`, `OW.Protocol`, `OW.UI`)
- Enum keys: UPPER_SNAKE_CASE (`OW.STATUS.ONLINE`, `OW.SPEC.DRUID_FERAL`)
- Local functions and variables: camelCase (`sortEntries`, `refreshChannelNum`, `currentPage`)
- Constants local to a file: UPPER_SNAKE_CASE (`ROW_HEIGHT`, `PAGE_SIZE`, `MSG_PREFIX`)
- Localization keys: UPPER_SNAKE_CASE (`OW.L.BTN_SAVE`, `OW.L.COL_NAME`)

## Where to Add New Code

**New user-facing string:**
- Add key to `Locales/enUS.lua` in the appropriate comment section
- Access via `OW.L.KEY_NAME` with a fallback: `OW.L.KEY_NAME or "Default"`

**New static data table or enum:**
- Add to an appropriate file in `Core/` (for game data) or `Data/` (for non-WoW data like timezones)
- If it is a new enum, follow the read-only metatable pattern from `Core/Status.lua`

**New database field on an entry:**
- Add to the entry table in `Core/Database.lua` (`SaveMyEntry`, `UpsertPeer`)
- Add to the ANN wire format in `Network/Protocol.lua` (`SerializeANN`, `Deserialize`, `validateANN`, `HandleANN`)
- Bump protocol awareness if needed (wire format version is `MSG_VERSION = "1"`)

**New UI tab:**
- Create `UI/TabNewTab.lua` following the `OW.TabSchedule` / `OW.TabPlayers` pattern (module table, `Build(parent)`, optional `Refresh()`)
- Add file to `OnlineWhen.toc` before `Core/Commands.lua`
- Register `tabFrames[N]` and call `Build` from `UI/Window.lua` `CreateMainWindow()`
- Increment `TAB_COUNT` in `UI/Window.lua`

**New slash command:**
- Add a branch to `SlashCmdList["ONLINEWHEN"]` in `Core/Commands.lua`
- Document it in `OW.PrintHelp()`

**New network message type:**
- Add `Serialize*`, `Handle*`, and a branch in `OnChannelMessage` inside `Network/Protocol.lua`

## Special Directories

**`.planning/`:**
- Purpose: GSD planning documents (phases, codebase analysis)
- Generated: No
- Committed: Yes (planning artifacts are version-controlled)

**`Deployment/`:**
- Purpose: Developer scripts for packaging and local deployment
- Generated: No
- Committed: Yes; scripts are source-controlled but never loaded by WoW

---

*Structure analysis: 2026-03-24*
