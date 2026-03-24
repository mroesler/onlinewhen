# Codebase Concerns

**Analysis Date:** 2026-03-24

---

## WoW API Constraints That Shape the Code

**`JoinChannelByName` hardware-event restriction (TBC Classic Anniversary):**
- WoW's TBC Classic Anniversary build silently ignores `JoinChannelByName` when called from timers or event handlers — it only works inside a real hardware event (mouse click, keypress).
- The addon works around this by hooking `WorldFrame:HookScript("OnMouseDown", ...)` so the channel join fires on the player's first click after login.
- File: `Network/Protocol.lua` lines 83–90 (`P.JoinSyncChannel`).
- Risk: If Blizzard changes this restriction in a future patch the workaround becomes redundant but harmless. If the restriction is tightened further (e.g., requiring a specific UI hardware event frame), the channel join will silently fail again and sync will never start.

**`SendAddonMessage("CHANNEL")` not available in TBC Classic:**
- The addon cannot use the dedicated `SendAddonMessage` API. All sync traffic is sent as plain `CHANNEL` chat messages (`SendChatMessage`) with an `OW:` prefix.
- A `ChatFrame_AddMessageEventFilter` suppresses these messages from the player's chat frame, but the filter only applies to frames that exist at load time.
- File: `Network/Protocol.lua` lines 46–50.
- Risk: Chat frames created by third-party addons after OnlineWhen loads (e.g., ElvUI chat modules that rebuild frames on demand) will not have the filter applied and will show raw `OW:1;ANN;...` messages to the player.

**`GetServerTime()` availability:**
- All time-relative display depends on `GetServerTime`. The code defensively falls back to `time()` (machine-local time) with `(GetServerTime and GetServerTime()) or time()` throughout `UI/TabPlayers.lua`.
- If `GetServerTime` is unavailable, all relative countdown labels ("in 2 hours") and server-time column values silently drift by the machine's UTC offset with no warning to the user.

---

## Tech Debt

**DST not handled — timezone offsets are static:**
- `Data/Timezones.lua` stores fixed `offset` values in minutes. Timezones that observe DST (e.g., `US/Eastern` is listed as `-300` which is EST; EDT is `-240`) have no automatic switching.
- The label hints at DST (`EST/EDT`) but the actual offset stored is always the standard-time value.
- File: `Data/Timezones.lua` lines 8–45.
- Impact: Users in DST-observing regions who do not manually pick the correct seasonal offset will schedule meetings off by one hour for roughly half the year.
- Fix approach: Add a second `dstOffset` field per timezone entry and a mechanism (even manual) to select the current DST state, or document clearly that users must pick the correct offset themselves.

**Protocol version is a single string literal with no negotiation:**
- `MSG_VERSION = "1"` is baked into `Network/Protocol.lua` line 12. All received messages whose `fields[1] ~= "1"` are silently dropped by `validateANN` and `HandleBYE`.
- File: `Network/Protocol.lua` line 12.
- Risk: Any future wire-format change (new field, reordered fields) requires bumping the version and dropping all messages from clients on the old version. There is no backward-compatibility mechanism or user notification when a version mismatch occurs — peers simply become invisible to each other.

**Class list is hardcoded to TBC (9 classes):**
- `VALID_CLASSES` in `Network/Protocol.lua` lines 18–21 and the full class enum in `Core/Classes.lua` list exactly the 9 TBC classes. Death Knight, Monk, Demon Hunter, etc. are absent.
- `.toc` interface version is `20504` (TBC Classic Anniversary), so this is intentional, but it means the addon cannot be ported to other game versions without changing multiple files.

**Level cap is hardcoded to 70:**
- `validateANN` in `Network/Protocol.lua` line 179: `if not level or level < 1 or level > 70 then return false end`.
- Any peer broadcasting a level above 70 (e.g., after a Blizzard level-squish or expansion bump) will be rejected silently.

**`DEFAULT_TIMEZONE` defaults to `"Europe/Berlin"`:**
- `Data/Timezones.lua` line 47 and `UI/TabSchedule.lua` line 9.
- Non-European players see Berlin pre-selected every time they open the Schedule form until they change it. There is no auto-detection of the client machine's timezone.

**`onSave` in `UI/TabSchedule.lua` uses a hardcoded English error string:**
- Line 244: `showError("Pick a date and time.")` — this string is not in `OW.L` (the locale table) and cannot be translated.
- File: `UI/TabSchedule.lua` line 244.

---

## Fragile Areas

**Channel number can drift to 0 silently:**
- `channelNum` is a local in `Network/Protocol.lua` and is refreshed by `refreshChannelNum()`. If the channel is forcibly left (e.g., `/leave` by the user, or another addon evicting it), `channelNum` becomes 0 and `sendMsg` silently returns without sending anything.
- There is no re-join attempt in this case — the only re-join path is `WorldFrame:OnMouseDown` which only triggers if `channelNum == 0` **and** the hook has not already been deregistered. Once hooked, `channelJoinHooked = true` permanently, so subsequent evictions will not re-join the channel unless the player reloads their UI.
- Files: `Network/Protocol.lua` lines 33–36, 64–90.

**`BYE` message is sent from `PLAYER_LOGOUT`:**
- `Core/Init.lua` line 81 calls `OW.Protocol.BroadcastBye()` inside `PLAYER_LOGOUT`. WoW does not guarantee that `SendChatMessage` completes before the session ends; a hard disconnect (crash, power loss) will never send `BYE`.
- Peers who go offline via crash remain `ONLINE` in everyone else's UI indefinitely until they either log back in, or another player manually presses Sync and the grace period expires.
- File: `Core/Init.lua` line 81.

**Self-identification relies on `UnitName("player")` string equality:**
- `P.OnChannelMessage` skips messages where `senderName == myName` (line 229). On connected realms, player names are unique per realm but `GetChannelName` is realm-scoped, so cross-realm collisions are not a concern — but the comparison does not account for realm suffixes in the sender string.
- Line 228: `sender:match("^([^%-]+)") or sender` strips the realm suffix before comparison. If a player's name genuinely contains a hyphen this silently truncates it.
- File: `Network/Protocol.lua` line 228.

**REQ broadcast storm mitigation is probabilistic only:**
- `HandleREQ` (line 290) uses `math.random(0, 5)` seconds jitter to stagger ANN responses. With a large guild (50+ users) all logging in simultaneously (e.g., at raid time), this produces 50 ANN broadcasts within a 5-second window, all going to the same channel — potentially flooding chat message rate limits.
- File: `Network/Protocol.lua` line 290.

**`UpsertPeer` and `HandleANN` both call `OW.TabPlayers.Refresh()`:**
- `HandleANN` in `Protocol.lua` lines 269–271 calls `Refresh()` unconditionally after `UpsertPeer`. `UpsertPeer` in `Database.lua` lines 45–47 also calls `Refresh()` if the entry was updated. This means `Refresh()` is called twice per ANN that results in a data update.
- Files: `Core/Database.lua` lines 44–48, `Network/Protocol.lua` lines 268–271.

---

## Missing Error Handling

**`OW.BuildUTCTimestamp` machine-bias calculation assumes `time()` and `date("!*t")` agree:**
- `Data/Timezones.lua` lines 110–117 compute a `bias` by diffing `time()` against a reconstructed UTC timestamp. This is mathematically correct but fragile if the player's system clock is set to a non-standard timezone that Lua's `os.date` does not handle the same way WoW's `date()` does. There is no guard against a `bias` that is implausibly large (e.g., > 24 hours).

**No validation on `peer.name` before using as map key in `playerStatus`:**
- `HandleANN` (line 264) writes `OW.playerStatus[entry.name]` before calling `validateANN`. `validateANN` checks field count and bounds but does not enforce a maximum name length or character set for `fields[3]` (name). A malicious or malformed `name` value could insert an arbitrary key into `playerStatus`.
- File: `Network/Protocol.lua` lines 252–264.

**`ParseDate` only validates month 1–12 and day 1–31 — does not cross-validate:**
- `OW.ParseDate` in `Data/Timezones.lua` line 85 returns without error for `"2026-02-30"`. The nonsense date is passed into `time({...})` which silently rolls over to March 1 or 2 depending on year. The UI prevents this from the dropdowns (which cap days correctly per month), but if `BuildUTCTimestamp` were ever called directly with a raw string, the silent rollover would produce a wrong timestamp with no error.
- File: `Data/Timezones.lua` lines 80–87.

**`OnlineWhenDB` accessed before `EnsureDefaults` in some edge paths:**
- `P.JoinSyncChannel` (line 78) reads `OnlineWhenDB.settings.realm` directly. `EnsureDefaults` is called in `OW.OnLogin`, but `PLAYER_ENTERING_WORLD` fires before `PLAYER_LOGIN` completes in some reload scenarios. The code uses `or GetRealmName()` as a fallback, but this silently masks the race condition rather than fixing it.
- File: `Network/Protocol.lua` line 78.

---

## Hardcoded Values / Magic Numbers

| Value | Location | Notes |
|---|---|---|
| `14 * 24 * 60 * 60` (stale cutoff = 14 days) | `Core/Database.lua` line 53 | Inline arithmetic, not a named constant |
| `30 * 60` (grace period = 30 min) | `Core/Database.lua` line 64, `UI/TabPlayers.lua` line 168 | Duplicated across two files; must be kept in sync manually |
| `70` (max level) | `Network/Protocol.lua` line 179 | TBC cap; breaks on any expansion port |
| `math.random(0, 5)` (REQ jitter seconds) | `Network/Protocol.lua` line 290 | Inline; not a named constant |
| `WINDOW_W = 800`, `WINDOW_H = 520` | `UI/Window.lua` lines 7–8 | Window is not resizable; hardcoded size |
| `contentAreaHeight = 472` | `UI/TabSchedule.lua` line 359 | Derived comment formula not enforced at runtime; breaks if `WINDOW_H`, `TAB_H`, or `INSET` change |
| `groupWidth = 776` | `UI/TabSchedule.lua` line 368 | Same derivation concern as above |
| `PAGE_SIZE = 12` | `UI/TabPlayers.lua` line 19 | Not tied to window height; adding rows requires also updating layout math |
| `"Europe/Berlin"` (default timezone) | `Data/Timezones.lua` line 47 | Euro-centric default with no client-side detection |
| `MSG_VERSION = "1"` | `Network/Protocol.lua` line 12 | Version bump requires coordinated rollout across all users |
| `TS_MAX_OFFSET = 60 * 24 * 60 * 60` (60 days future) | `Network/Protocol.lua` line 24 | Limits how far in advance a schedule entry can be set |

---

## Scalability Concerns

**All peer data lives in a single flat `OnlineWhenDB.peers` table:**
- `Core/Database.lua` iterates the full `peers` table on every `GetAllEntries()` call (line 91). `GetAllEntries()` is called on every `Refresh()`. With many peers (e.g., a large raiding community with hundreds of toons tracked), this O(n) scan happens on every channel message that results in a status change.
- There is no index. Filtering, sorting, and pagination are all done in Lua on the full set on each Refresh.

**No deduplication between `myEntry` and `peers`:**
- If the player's own entry is received back from the network (e.g., after a REQ), `HandleANN` would upsert it into `OnlineWhenDB.peers` under the `name-realm` key. `GetAllEntries` also includes `myEntry`. The self-check in `updateRows` (`isSelf`) prevents the invite button from appearing, but the player could appear twice in the list if the upserted peer entry key happens to differ from the `myEntry` name.
- This is partially mitigated by the `senderName == myName` check in `OnChannelMessage` (line 229), but only when the sender name string matches exactly.

---

## Areas That Are Risky to Change

**`OW.BuildUTCTimestamp` in `Data/Timezones.lua`:**
- The machine-bias removal logic (lines 110–121) is subtle. Changing how `time({...})` is called or how the bias is computed can silently shift all scheduled times by hours. Any change here needs careful testing across machines in different system timezones.

**Wire format in `Network/Protocol.lua`:**
- Field order in `SerializeANN` (line 126), field indices in `validateANN` (line 164), and `HandleANN` (line 252) are tightly coupled. Adding or reordering a field in the serializer without updating the validator and handler in lockstep will silently drop or misparse all incoming messages.

**`CONTENT_W`, `contentAreaHeight`, `groupWidth` in `UI/TabSchedule.lua` and `UI/TabPlayers.lua`:**
- Several layout constants are derived from `WINDOW_W`/`WINDOW_H` in comments but are not computed at runtime — they are hardcoded to their pre-calculated values. Changing `WINDOW_W` or `WINDOW_H` in `UI/Window.lua` without also updating these derived constants will misalign the UI silently.

**`PurgeStalePeers` and `PurgeExpiredPeers` run destructively with no undo:**
- `Core/Database.lua` lines 52–81. Both functions permanently delete entries from `OnlineWhenDB.peers`. They are called at login and from the "Clear Past" button respectively. There is no confirmation dialog and no recycle bin — deleted entries can only be recovered by re-syncing with online peers.

---

*Concerns audit: 2026-03-24*
