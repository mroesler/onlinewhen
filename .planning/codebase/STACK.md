# Technology Stack

**Analysis Date:** 2026-03-24

## Languages

**Primary:**
- Lua 5.1 — All addon logic (WoW embeds Lua 5.1 with minor extensions)

**Tooling/Scripting:**
- PowerShell — Deployment scripts (`Deployment/release.ps1`, `Deployment/sync.ps1`)

## Runtime

**Environment:**
- World of Warcraft TBC Classic Anniversary (Interface version `20504`)
- Lua runs sandboxed inside the WoW client; no file I/O, no sockets, no OS libraries
- All standard library access is via the WoW Lua API (e.g. `time()`, `date()`, `CreateFrame()`)

**Target Client:**
- WoW Anniversary edition, game directory: `D:\Battle.net\World of Warcraft\_anniversary_`

**Package Manager:**
- None. No external Lua package manager. All code is hand-authored.

## Frameworks

**UI:**
- WoW Widget API — native frames, textures, font strings (`CreateFrame`, `UIParent`, etc.)
- No XML/Blizzard template files; all UI is constructed programmatically in Lua
- Custom dark "ElvUI-Norm style" color palette defined inline in `UI/Window.lua`

**Timers:**
- `C_Timer.After` — used in `Network/Protocol.lua` for staggered REQ responses and initial sync delay

**Testing:**
- None detected. No test framework or test files present.

## Addon Structure

**Entry Point:**
- `OnlineWhen.toc` — declares load order, Interface version, SavedVariables name, and addon metadata

**Load Order** (as declared in `.toc`):
1. `Locales/enUS.lua`
2. `Data/Timezones.lua`
3. `Core/Status.lua`
4. `Core/Classes.lua`
5. `Core/Specs.lua`
6. `Core/Database.lua`
7. `Network/Protocol.lua`
8. `UI/Window.lua`
9. `UI/TabSchedule.lua`
10. `UI/TabPlayers.lua`
11. `Core/Commands.lua`
12. `Core/Init.lua`

**Namespace:**
- Shared addon-local namespace via the `addonName, OW = ...` varargs pattern. Exposed globally as `OnlineWhen = OW` by `Core/Init.lua`.

## Key WoW API Usage

- `CreateFrame` — all UI widget creation
- `SendChatMessage(..., "CHANNEL", ...)` — network transport (addon messages not available in TBC Classic)
- `ChatFrame_AddMessageEventFilter` — suppress protocol messages from chat display
- `JoinChannelByName` — join the realm-specific sync channel (hardware-event restricted; hooked via `WorldFrame:HookScript("OnMouseDown")`)
- `GetChannelName`, `GetRealmName`, `UnitName`, `UnitClass`, `UnitLevel` — player and channel info
- `SlashCmdList` / `SLASH_*` — slash command registration (`/ow`, `/onlinewhen`)
- `time()`, `date()` — Unix-epoch timestamps and UTC formatting
- `SavedVariables: OnlineWhenDB` — persistent cross-session storage

## Build / Packaging

**Release:**
- `Deployment/release.ps1` — PowerShell script that zips the addon, creates a GitHub release via `gh` CLI, and uploads to CurseForge via REST API

**Dev Sync:**
- `Deployment/sync.ps1` — PowerShell + `robocopy` mirror from dev folder to live WoW AddOns directory

**Version Source of Truth:**
- `## Version:` field in `OnlineWhen.toc` (currently `1.1.0`)

**Archive Output:**
- `E:\Development\Projects\WoW\OnlineWhenArchive\OnlineWhen-{version}.zip`

## Technical Constraints

- `SendAddonMessage` with `"CHANNEL"` distribution is not available in TBC Classic — plain `SendChatMessage` on a custom channel is used instead, with a chat filter to suppress display.
- `JoinChannelByName` is hardware-event restricted in TBC Classic Anniversary — it is called inside a `WorldFrame` mouse-down hook rather than from event handlers or timers.
- Level cap is hard-coded to 70 in protocol validation (`Network/Protocol.lua`, line 179).
- No DST automation — users manually select their current UTC offset from a timezone dropdown.
- No external Lua libraries; the entire dependency surface is the WoW client API.

---

*Stack analysis: 2026-03-24*
