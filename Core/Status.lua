-- Core/Status.lua — Session-only online/offline status.
-- Status is populated by the network layer (ANN = online, BYE = offline).
-- NOT stored in SavedVariables — resets on every reload.

local addonName, OW = ...

-- Status constants
OW.STATUS_UNKNOWN = 0
OW.STATUS_ONLINE  = 1
OW.STATUS_OFFLINE = 2

OW.playerStatus = {}   -- ["PlayerName"] = STATUS_ONLINE | STATUS_OFFLINE

-- Return the known status for a player name, or STATUS_UNKNOWN if not yet seen.
function OW.GetStatusForEntry(name)
    return OW.playerStatus[name] or OW.STATUS_UNKNOWN
end
