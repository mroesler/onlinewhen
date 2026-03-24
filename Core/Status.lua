-- Core/Status.lua — Session-only online/offline status.
-- Status is populated by the network layer (ANN = online, BYE = offline).
-- NOT stored in SavedVariables — resets on every reload.

local addonName, OW = ...

OW.STATUS = setmetatable({ ONLINE = 1, OFFLINE = 2, UNKNOWN = 0 }, {
    __index    = function(_, k) error("OW.STATUS: unknown key: " .. tostring(k), 2) end,
    __newindex = function()     error("OW.STATUS: is read-only", 2) end,
})

OW.playerStatus = {}   -- ["PlayerName"] = OW.STATUS.ONLINE | .OFFLINE

function OW.GetStatusForEntry(name)
    return OW.playerStatus[name] or OW.STATUS.UNKNOWN
end
