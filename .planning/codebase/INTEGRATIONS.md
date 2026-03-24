# External Integrations

**Analysis Date:** 2026-03-24

## In-Game Communication (Addon-to-Addon / Peer-to-Peer)

**Custom Chat Channel (primary transport):**
- Mechanism: `SendChatMessage(payload, "CHANNEL", nil, channelNum)` / `CHAT_MSG_CHANNEL` event
- Why: `SendAddonMessage` with `"CHANNEL"` distribution is unavailable in TBC Classic
- Channel name: `"ow" + safeRealm` where `safeRealm` is the realm name lowercased with spaces and hyphens stripped (e.g. `"owthunderstrike"`)
- Channel is joined once per session via `JoinChannelByName`, deferred to the first hardware mouse event via `WorldFrame:HookScript("OnMouseDown")`
- Implementation: `Network/Protocol.lua`

**Message Filtering:**
- `ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ...)` suppresses all `OW:`-prefixed messages from appearing in the player's chat window
- Implementation: `Network/Protocol.lua` lines 47–50

## Wire Protocol

**Message Envelope:**
- Every outbound chat message is prefixed with `"OW:"` (`MSG_PREFIX`)
- The payload after the prefix is a semicolon-delimited string: `VERSION;TYPE;field1;field2;...`
- Semicolon chosen as separator because `|` is WoW's color-escape character

**Protocol Version:** `"1"` (hardcoded as `MSG_VERSION` in `Network/Protocol.lua`)

**Message Types:**

| Type | Fields | Purpose |
|------|--------|---------|
| `ANN` | version; `ANN`; name; realm; spec; level; onlineAt; tzId; updated; class | Announce own schedule to channel |
| `REQ` | version; `REQ`; name; realm | Request all peers to re-announce |
| `BYE` | version; `BYE`; name; realm | Notify peers of logout/going offline |

**ANN field detail:**
- `onlineAt` — UTC Unix timestamp of the player's scheduled next-online time
- `updated` — UTC Unix timestamp of when the entry was last saved
- `spec` — spec label string (e.g. `"Restoration"`) or empty string
- `class` — class display name (e.g. `"Druid"`) or empty string
- `level` — integer 1–70

**Validation bounds** (enforced in `Network/Protocol.lua`):
- `onlineAt`: must be within 30 days past – 60 days future of `time()`
- `updated`: must be within 30 days past – 2 hours future of `time()`
- `level`: 1–70
- `spec` and `class` must be from known enum sets; cross-validated against each other

**Broadcast behaviour:**
- On channel join: immediately broadcasts `ANN` (self), then after 1-second delay sends `REQ`
- On `REQ` received: responds with own `ANN` after a random 0–5 second delay to avoid broadcast storms
- On logout: broadcasts `BYE`

## Persistent Storage (SavedVariables)

**Variable name:** `OnlineWhenDB`
**Declared in:** `OnlineWhen.toc` — `## SavedVariables: OnlineWhenDB`
**Managed by:** `Core/Database.lua`

**Schema:**
```lua
OnlineWhenDB = {
    settings = {
        realm      = "RealmName",          -- set once on first login, never shown in UI
        windowPos  = { point, relPoint, x, y },  -- persisted window position
    },
    myEntry = {
        name     = "CharacterName",
        realm    = "RealmName",
        spec     = "SpecLabel",            -- e.g. "Restoration", or nil
        class    = "ClassName",            -- e.g. "Druid", or nil
        level    = 60,
        onlineAt = 1710000000,             -- UTC Unix timestamp
        timezone = "Europe/Berlin",        -- timezone id string
        updated  = 1710000000,             -- UTC Unix timestamp
    },
    peers = {
        ["Name-Realm"] = { -- same shape as myEntry, no status field }
    }
}
```

**Data lifetime:**
- Peers older than 14 days are purged on login (`PurgeStalePeers`)
- Peers whose `onlineAt` is more than 30 minutes past are removed if not currently online (`PurgeExpiredPeers`)
- Online/offline status (`OW.playerStatus`) is session-only — never written to `SavedVariables`

## WoW Events Consumed

| Event | Handler | Purpose |
|-------|---------|---------|
| `PLAYER_LOGIN` | `Core/Init.lua` | Initialize DB defaults, set self online, build UI |
| `PLAYER_ENTERING_WORLD` | `Core/Init.lua` | Trigger sync channel join |
| `CHAT_MSG_CHANNEL` | `Network/Protocol.lua` | Receive peer messages |
| `CHAT_MSG_CHANNEL_NOTICE` | `Network/Protocol.lua` | Detect channel join success, get channel number |
| `CHANNEL_UI_UPDATE` | `Network/Protocol.lua` | Refresh channel number after renumbering |
| `GROUP_ROSTER_UPDATE` | `Core/Init.lua` | Refresh Players tab when group changes |
| `PLAYER_LOGOUT` | `Core/Init.lua` | Broadcast BYE, save window position |

## External Release Services

**GitHub:**
- Used for: version-tagged releases with zip attachment
- Client: `gh` CLI (must be authenticated via `gh auth login`)
- API calls: `gh release create`, `gh release delete`, `gh api` (tag deletion on rollback)
- Invoked by: `Deployment/release.ps1`

**CurseForge:**
- Used for: public addon distribution
- Project ID: `1491238`
- Game version ID: `14300` (TBC Classic Anniversary)
- API endpoint: `https://wow.curseforge.com/api/projects/{id}/upload-file`
- Auth: `X-Api-Token` header, token read from `$env:CF_API_TOKEN` environment variable
- Payload format: `multipart/form-data` with JSON metadata part and zip file part
- Invoked by: `Deployment/release.ps1`

**Rollback behaviour:** if CurseForge upload fails after a successful GitHub release, the script automatically deletes the GitHub release and tag before exiting with an error.

## Locale / i18n

**Mechanism:** Single locale table `OW.L` defined in `Locales/enUS.lua`, referenced throughout UI code as `OW.L.KEY`
- No runtime locale detection; only `enUS` is implemented
- No external translation service

---

*Integration audit: 2026-03-24*
