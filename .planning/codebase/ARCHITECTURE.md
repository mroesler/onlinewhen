# Architecture

**Analysis Date:** 2026-03-24

## Pattern Overview

**Overall:** Event-driven addon with a shared namespace (`OW`), split across layered modules loaded in sequence by the WoW client.

**Key Characteristics:**
- Single global namespace (`OnlineWhen` / `OW`) populated progressively as files load
- No classes or metatables for module instances — modules are plain tables on `OW`
- All persistent state lives in a single `SavedVariables` table (`OnlineWhenDB`)
- Session-only state (online presence) lives in an in-memory table, never persisted
- Network transport is plain channel chat messages (not `SendAddonMessage`, which is unavailable in TBC Classic)

## Layers

**Data / Static Definitions:**
- Purpose: Immutable lookup tables for enums, timezones, locales
- Location: `Locales/enUS.lua`, `Data/Timezones.lua`, `Core/Classes.lua`, `Core/Specs.lua`
- Contains: `OW.L`, `OW.Timezones`, `OW.CLASS`, `OW.SPEC`, `OW.CLASS_SPECS`, `OW.CLASS_COLOR`, `OW.SPEC_ID`, `OW.SPEC_NAME`, `OW.CLASS_TOKEN_NAME`, `OW.CLASS_NAME`
- Depends on: Nothing (loaded first)
- Used by: All other layers

**Core / State:**
- Purpose: Manages all persistent and session state; provides the canonical API for reading and writing player data
- Location: `Core/Status.lua`, `Core/Database.lua`
- Contains: `OW.STATUS`, `OW.playerStatus`, `OW.EnsureDefaults`, `OW.GetMyEntry`, `OW.SaveMyEntry`, `OW.UpsertPeer`, `OW.GetAllEntries`, `OW.PurgeStalePeers`, `OW.PurgeExpiredPeers`, `OW.GetStatusForEntry`
- Depends on: Data layer
- Used by: Network, UI layers

**Network:**
- Purpose: Peer-to-peer sync engine; serializes/deserializes wire messages; manages the sync channel lifecycle
- Location: `Network/Protocol.lua`
- Contains: `OW.Protocol` — `BroadcastSelf`, `RequestPeers`, `BroadcastBye`, `HandleANN`, `HandleREQ`, `HandleBYE`, `JoinSyncChannel`, `OnChannelNotice`, `OnChannelUpdate`, `OnChannelMessage`
- Depends on: Core/State, Data layer
- Used by: Core/Init (event dispatch), UI (Sync button)

**UI:**
- Purpose: Renders the main window, tab chrome, Schedule form, and Players table
- Location: `UI/Window.lua`, `UI/TabSchedule.lua`, `UI/TabPlayers.lua`
- Contains: `OW.UI` (window + tab management), `OW.TabSchedule` (schedule form), `OW.TabPlayers` (player list)
- Depends on: Core/State, Data layer, Network (Sync button calls `Protocol.RequestPeers`)
- Used by: Core/Init (creates window on login)

**Core / Lifecycle:**
- Purpose: Addon entry point; registers WoW events; orchestrates login/logout sequence
- Location: `Core/Commands.lua`, `Core/Init.lua`
- Contains: Slash command handlers, `OW.OnLogin`, `OW.OnLogout`, event frame
- Depends on: All other layers (loaded last)
- Used by: WoW client event system

## Data Flow

**Player saves a schedule:**
1. User fills the Schedule form in `UI/TabSchedule.lua` and clicks Save
2. `onSave()` calls `OW.BuildUTCTimestamp()` (from `Data/Timezones.lua`) to convert local time → UTC
3. `OnlineWhen.SaveMyEntry(name, spec, class, level, utcTs, tzId)` writes `OnlineWhenDB.myEntry`
4. `SaveMyEntry` immediately calls `OW.Protocol.BroadcastSelf()` → sends `OW:1;ANN;...` on the sync channel
5. UI auto-navigates to the Players tab

**Receiving a peer's announcement:**
1. WoW fires `CHAT_MSG_CHANNEL`; `Core/Init.lua` dispatches to `OW.Protocol.OnChannelMessage()`
2. `Protocol.OnChannelMessage` filters by channel number and `OW:` prefix, then routes to `HandleANN`
3. `HandleANN` validates all fields, filters to local realm, marks player online in `OW.playerStatus`
4. `OW.UpsertPeer(key, entry)` writes to `OnlineWhenDB.peers` (skips if not newer)
5. If the Players tab is visible, `OW.TabPlayers.Refresh()` is called immediately

**Peer goes offline:**
1. Departing peer sends `BYE` on logout (from `OW.OnLogout` → `Protocol.BroadcastBye`)
2. `HandleBYE` sets `OW.playerStatus[name] = OW.STATUS.OFFLINE`
3. Players tab refreshes if visible

**Channel join sequence:**
1. `PLAYER_ENTERING_WORLD` triggers `Protocol.JoinSyncChannel()`, which hooks `WorldFrame:OnMouseDown`
2. On first real hardware click, `JoinChannelByName(channelName)` is called (TBC hardware-event restriction)
3. `CHAT_MSG_CHANNEL_NOTICE` (YOU_JOINED_CHANNEL) fires → `channelNum` is stored, `BroadcastSelf` + `RequestPeers` (delayed 1s) are sent automatically
4. Other peers respond to `REQ` with a staggered `BroadcastSelf` (0–5 second random delay to prevent broadcast storm)

**State Management:**
- Persistent state: `OnlineWhenDB.myEntry` (own schedule), `OnlineWhenDB.peers` (keyed `"name-realm"`), `OnlineWhenDB.settings` (realm, window position)
- Session state: `OW.playerStatus` table — populated by ANN/BYE network messages, never saved; resets on every reload/relog
- Stale entries are purged on login (>14 days old) and on explicit "Clear Past" action (>30 min past and not online)

## Key Abstractions

**OW Namespace:**
- Purpose: Single shared table passed as the second vararg (`...`) to every file, used as the module registry
- Pattern: `local addonName, OW = ...` at top of every file; `Core/Init.lua` exposes it as `OnlineWhen = OW` globally

**Entry Record:**
- Purpose: Uniform data shape for both own and peer schedule data
- Fields: `name`, `realm`, `spec`, `class`, `level`, `onlineAt` (UTC unix), `timezone` (tz id string), `updated` (UTC unix)
- Stored in: `OnlineWhenDB.myEntry`, `OnlineWhenDB.peers["name-realm"]`
- Transmitted as: `ANN` wire message

**Read-only Enums:**
- Purpose: Guard against typos; raise errors on unknown keys or mutation
- Examples: `OW.STATUS`, `OW.CLASS`, `OW.SPEC` — all use `__index`/`__newindex` metamethods to error on bad access
- Location: `Core/Status.lua`, `Core/Classes.lua`, `Core/Specs.lua`

**Protocol Message Types:**
- `ANN` — full schedule announcement (10 semicolon-delimited fields); triggers peer upsert + status ONLINE
- `REQ` — request for peers to announce themselves (4 fields); triggers staggered `BroadcastSelf` responses
- `BYE` — offline notification (4 fields); sets status OFFLINE

## Entry Points

**WoW Addon Load:**
- Location: `OnlineWhen.toc`
- Triggers: WoW client loads files in `.toc` order before any events fire
- Responsibilities: Establishes `OW` namespace, populates all static definitions, registers UI/network modules

**PLAYER_LOGIN:**
- Location: `Core/Init.lua` → `OW.OnLogin()`
- Triggers: Fires once per session after the character enters the world for the first time
- Responsibilities: `EnsureDefaults`, store realm, purge stale peers, mark self online, create main window

**PLAYER_ENTERING_WORLD:**
- Location: `Core/Init.lua` → `Protocol.JoinSyncChannel()`
- Triggers: Fires on login and on zone transitions
- Responsibilities: Hooks `WorldFrame:OnMouseDown` to join the realm-specific sync channel on first click

**Slash Commands `/ow` / `/onlinewhen`:**
- Location: `Core/Commands.lua`
- Responsibilities: Toggle window, print help/debug info, reset DB, print channel info

## Error Handling

**Strategy:** Silent guard checks (`if OW.Protocol then ... end`) throughout Init; errors in enums are intentional hard-errors via `error()` to catch developer mistakes. No pcall wrappers on network paths.

**Patterns:**
- Enum misuse raises Lua errors at the call site (metamethod-enforced)
- Network messages fail silently if validation fails (`validateANN` returns false → `HandleANN` returns)
- UI nil-guards protect against calling tab methods before the window is built (`if OW.TabPlayers and OW.UI ...`)

## Cross-Cutting Concerns

**Localization:** All user-facing strings accessed via `OW.L.*`; defined in `Locales/enUS.lua`; UI files fall back to hardcoded English strings when a key is absent (`OW.L.FOO or "Foo"`)
**Timezone conversion:** All stored/transmitted timestamps are UTC; display conversion done in `Data/Timezones.lua` helpers (`BuildUTCTimestamp`, `UTCToLocal`, `FormatTimeOnly`)
**Chat filter:** `ChatFrame_AddMessageEventFilter` suppresses `OW:`-prefixed messages from appearing in the chat window; installed in `Network/Protocol.lua`
**Realm isolation:** All peer lookups check `entry.realm == OnlineWhenDB.settings.realm`; the sync channel name is realm-derived (`"ow" .. safeRealmName`)

---

*Architecture analysis: 2026-03-24*
