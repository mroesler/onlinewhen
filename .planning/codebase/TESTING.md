# Testing Patterns

**Analysis Date:** 2026-03-24

## Automated Tests

None. This is a World of Warcraft addon. The Lua runtime is the WoW client itself,
which provides no test harness. There are no unit test files, no test framework
dependencies, and no CI pipeline for running tests.

## Manual In-Game Testing

All testing is performed by loading the addon in the WoW TBC Classic client and
exercising it directly. The primary workflow:

1. Copy addon files to the WoW AddOns directory (handled by `Deployment/sync.ps1`).
2. Log in to a character or `/reload` the UI.
3. Exercise features through the in-game UI and slash commands.
4. Observe results in the chat window and the addon's main frame.

## Slash Commands Available for Testing

Registered in `Core/Commands.lua`. All commands use `/ow` or `/onlinewhen`.

| Command | What it does |
|---------|-------------|
| `/ow` | Toggles the main window. Confirms UI initialised correctly. |
| `/ow help` | Prints all commands to chat. |
| `/ow debug` | Dumps the full `OnlineWhenDB` structure to chat: `settings.realm`, `myEntry` (all fields), and every peer entry with all fields. Primary tool for inspecting saved state. |
| `/ow reset` | Wipes `OnlineWhenDB` to nil, re-runs `EnsureDefaults()`, and refreshes the Players tab. Used to reset state between test scenarios. |
| `/ow channel` | Prints the active sync channel name (e.g. `owthunderstrike`) and its assigned channel slot number. Confirms the channel join succeeded. |

## Debug Output Format

`/ow debug` prints to the default chat frame in a structured pseudo-table format:

```
=== OnlineWhen Debug ===
  settings.realm = Thunderstrike
  myEntry = {
    name     = Speedlemon
    spec     = Retribution
    class    = Paladin
    level    = 70
    onlineAt = 1710000000
    timezone = Europe/Berlin
    updated  = 1710000000
  }
  peers (3) = {
    ["Altchar-Thunderstrike"] = {
      name     = Altchar
      ...
    }
  }
```

Implemented in `OW.PrintDebug()` in `Core/Commands.lua`.

## How Errors Surface

**Lua errors:** WoW surfaces Lua errors as red text in chat and/or via the default
error dialog. No custom error handler is registered. Runtime errors in event handlers
are caught by WoW's pcall wrapper and printed to chat.

**Validation errors (UI):** The Save button in the Schedule tab temporarily displays
the error message in red for 2.5 seconds, then resets to "Save". This covers missing
spec selection and invalid date/time inputs. Implemented via `showError()` in
`UI/TabSchedule.lua`.

**Silent failures:** Functions that receive bad network data return early without
error. `validateANN()` in `Network/Protocol.lua` rejects malformed or out-of-range
messages silently. This is intentional — bad network input should not surface to the
player.

**Enum guard errors:** Accessing an unknown key on `OW.STATUS`, `OW.CLASS`, or
`OW.SPEC` raises a Lua error via metamethod, which surfaces as a red error in chat.
This provides early feedback during development if a key name is mistyped.

## Network Testing

The network layer (`Network/Protocol.lua`) is tested by having two or more characters
logged in on the same realm:

- Character A saves a schedule entry — it broadcasts `ANN` on the sync channel.
- Character B opens the Players tab — it should show Character A's entry.
- Character A logs out — `BYE` is sent; Character B's Players tab should update status.
- `/ow channel` on both characters should show the same channel name and number.

The sync channel name is deterministic: `ow` + realm name lowercased with spaces and
hyphens removed (e.g. `owthunderstrike`). `/ow channel` confirms this is correct.

## Stale Data Testing

- `/ow reset` clears all peers, allowing a fresh sync test.
- `OW.PurgeStalePeers()` runs at login and removes entries older than 14 days.
  This can be verified via `/ow debug` before and after adjusting `updated` timestamps
  in the SavedVariables file directly (offline, before loading the client).

## Deployment Sync

`Deployment/sync.ps1` copies source files to the live WoW AddOns directory.
After syncing, a UI reload (`/reload`) is required for changes to take effect.
This is the standard iteration loop: edit → sync → reload → test in-game.
