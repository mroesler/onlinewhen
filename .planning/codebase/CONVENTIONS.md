# Coding Conventions

**Analysis Date:** 2026-03-24

## Namespace Pattern

Every file starts with the same two-line header to receive the shared addon namespace:

```lua
local addonName, OW = ...
```

`OW` is the shared table passed by the WoW addon loader. `Core/Init.lua` immediately
aliases it as a global so all modules can reference either form:

```lua
OnlineWhen = OW   -- global alias exposed in Init.lua
```

Module-level sub-namespaces are declared at the top of each file and aliased locally:

```lua
OW.Protocol = {}
local P = OW.Protocol   -- short alias used throughout the file

OW.UI = {}
local UI = OW.UI

OW.TabSchedule = {}
local TI = OW.TabSchedule

OW.TabPlayers = {}
local TL = OW.TabPlayers
```

All public functions are attached to these sub-namespace tables (`P.BroadcastSelf`,
`UI.Toggle`, `TI.Build`, `TL.Refresh`). File-private helpers are `local function`.

## Naming Conventions

**Files:** PascalCase, no separators. Examples: `TabPlayers.lua`, `TabSchedule.lua`,
`Database.lua`, `Protocol.lua`.

**Directories:** PascalCase. `Core/`, `UI/`, `Network/`, `Data/`, `Locales/`.

**Public functions on namespace tables:** PascalCase verbs.
Examples: `OW.EnsureDefaults`, `OW.SaveMyEntry`, `OW.UpsertPeer`,
`P.BroadcastSelf`, `P.HandleANN`, `UI.CreateMainWindow`, `UI.ShowTab`.

**Private (local) functions:** camelCase.
Examples: `solidTex`, `addBorders`, `updateTabVisuals`, `refreshChannelNum`,
`makeGroupBox`, `makeDropdown`, `validateANN`, `sendMsg`, `split`.

**Variables:** camelCase for locals, SCREAMING_SNAKE_CASE for module-level
layout/config constants.
Examples of constants: `WINDOW_W`, `WINDOW_H`, `TAB_H`, `INSET`, `ROW_HEIGHT`,
`PAGE_SIZE`, `CHANNEL_PREFIX`, `MSG_PREFIX`, `MSG_VERSION`.

**Enum tables:** SCREAMING_SNAKE_CASE keys.
Examples: `OW.STATUS.ONLINE`, `OW.STATUS.OFFLINE`, `OW.CLASS.DRUID`,
`OW.SPEC.DRUID_BALANCE`. Spec keys are `CLASS_SPECNAME` to avoid collisions on
shared names like "Restoration".

**Localization keys:** SCREAMING_SNAKE_CASE in `OW.L`.
Examples: `OW.L.BTN_SAVE`, `OW.L.ERR_NO_SPEC`, `OW.L.TAB_SCHEDULE`.

**Loop variables:** short and descriptive — `key`, `peer`, `entry`, `item`, `spec`,
`day`, `v`, `lbl`.

## Enum Pattern

Enums use `setmetatable` with error-raising `__index` and `__newindex` metamethods to
catch typos and prevent mutation at runtime:

```lua
OW.STATUS = setmetatable({ ONLINE = 1, OFFLINE = 2, UNKNOWN = 0 }, {
    __index    = function(_, k) error("OW.STATUS: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.STATUS: is read-only", 2) end,
})
```

Same pattern applied to `OW.CLASS` and `OW.SPEC`.

## Comment Style

**File header:** every file opens with a single-line comment naming the file and its
purpose, followed by a blank line.

```lua
-- Core/Database.lua — All SavedVariables data access.
-- Single source of truth for reading and writing OnlineWhenDB.
-- Provides: EnsureDefaults, GetMyEntry, SaveMyEntry, ...
```

**Section dividers:** 75-dash separator lines delimit logical sections within a file.

```lua
-- ---------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------
```

**Inline comments:** appear on the same line or on the line above, explaining _why_
not _what_, often covering non-obvious WoW API constraints or design decisions.

```lua
-- JoinChannelByName is hardware-event restricted in TBC Classic Anniversary —
-- it silently does nothing when called from timers or event handlers.
```

**No block comments** (`--[[ ]]`) are used anywhere in the codebase.

## Guard Pattern for Optional Modules

Cross-module calls guard against load-order issues with `and` short-circuit:

```lua
if OW.Protocol then OW.Protocol.JoinSyncChannel() end
if OW.TabPlayers and OW.UI and OW.UI.GetCurrentTab and OW.UI.GetCurrentTab() == 2 then
    OW.TabPlayers.Refresh()
end
```

This pattern is used consistently in `Core/Init.lua`, `Core/Database.lua`, and
`Network/Protocol.lua`.

## Localization Pattern

All user-visible strings are accessed via `OW.L` with a fallback literal:

```lua
saveBtn:SetText(OW.L.BTN_SAVE or "Save")
print(OW.L.RESET_DONE or "DB reset.")
```

The fallback ensures the UI remains functional even if the locale file fails to load.
`OW.L` is populated in `Locales/enUS.lua`. Only English is provided; no additional
locale files exist.

## UI Color Pattern

Colors are collected into a local table at the top of each UI file, using short keys:

```lua
-- In Window.lua
local C = {
    bg          = { 0.09, 0.09, 0.09, 0.97 },
    border      = { 0.3,  0.3,  0.35, 1    },
    tabActive   = { 0.13, 0.13, 0.15, 1    },
    ...
}

-- In TabSchedule.lua
local WHITE    = { 1.0,  1.0,  1.0,  1.0 }
local DIM      = { 0.35, 0.35, 0.4,  1.0 }
local ACCENT   = { 0.2,  0.6,  1.0,  1.0 }
```

Colors are always passed to `SetColorTexture` / `SetTextColor` via `unpack()`.

## UI Construction Pattern

UI is built programmatically — no XML or `.frag` files. Construction follows a
consistent sequence per widget:

1. `CreateFrame(...)` or `CreateTexture(...)` / `CreateFontString(...)`
2. `SetPoint(...)` / `SetSize(...)` / `SetAllPoints()`
3. Set visual properties (`SetColorTexture`, `SetText`, `SetTextColor`, etc.)
4. Assign child references to the parent frame as fields (`btn.bg`, `btn.line`,
   `btn.label`) so they can be updated later.
5. Attach `SetScript("OnClick", ...)` or equivalent.

Factory helpers (`solidTex`, `addBorders`, `makeGroupBox`, `makeDropdown`) encapsulate
repeated widget construction. Helper functions defined in `UI/Window.lua` are local to
that file; helpers in tab files are local to their respective files.

Layout constants (pixel dimensions, padding values) are defined as named local
constants at the top of each UI file. Inline arithmetic documents the derivation:

```lua
-- dateTimeGroupHeight = contentAreaHeight − dateTimeGroupTopAbs − (padding + button + padding)
--                     = 472 − 104 − 56 = 312
local dateTimeGroupHeight = 312
```

## Dropdown Pattern

All dropdowns are created via the local `makeDropdown` factory in `UI/TabSchedule.lua`.
The factory wraps `UIDropDownMenuTemplate` and exposes a consistent interface:
`dd:GetValue()`, `dd:SetValue(v)`, `dd:ClearValue()`, `dd:SetItems(newItems)`.

Dropdown frame `SetPoint` x is always `visualX - 16` to compensate for
`UIDropDownMenuTemplate`'s internal left padding.

## Error Feedback Pattern

Validation errors in the UI repurpose the Save button text temporarily:

```lua
local function showError(msg)
    saveBtn:SetText("|cFFFF5555" .. msg .. "|r")
    C_Timer.After(2.5, function() if saveBtn then saveBtn:SetText(OW.L.BTN_SAVE or "Save") end end)
end
```

After 2.5 seconds the button text resets. The same self-resetting timer approach is
used for the "Saved!" confirmation state.

## WoW Color Code Pattern

Inline chat and UI text uses WoW's `|cAARRGGBB...|r` color codes directly in string
literals. Prefix color for addon messages is always `|cFF00FF00OnlineWhen:|r` (green).
Section headers use `|cFFFFD700...|r` (gold).

## SavedVariables Access Pattern

All reads and writes to `OnlineWhenDB` are centralized in `Core/Database.lua`.
Other modules call `OW.GetMyEntry()`, `OW.SaveMyEntry(...)`, `OW.UpsertPeer(...)`,
etc. Direct access to `OnlineWhenDB` outside `Core/Database.lua` exists only in
`Core/Commands.lua` (for the reset command and debug dump) and `Core/Init.lua`
(for login-time bootstrap).
