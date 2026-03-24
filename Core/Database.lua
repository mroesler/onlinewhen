-- Core/Database.lua — All SavedVariables data access.
-- Single source of truth for reading and writing OnlineWhenDB.
-- Provides: EnsureDefaults, GetMyEntry, SaveMyEntry,
--           UpsertPeer, GetAllEntries, PurgeStalePeers, PurgeExpiredPeers.

local addonName, OW = ...

function OW.EnsureDefaults()
    if not OnlineWhenDB then OnlineWhenDB = {} end
    local db = OnlineWhenDB
    if db.peers    == nil then db.peers    = {} end
    if db.settings == nil then db.settings = {} end
end

function OW.GetMyEntry()
    return OnlineWhenDB.myEntry
end

-- Save the player's own schedule entry and broadcast it to peers.
function OW.SaveMyEntry(name, spec, class, level, onlineAt, tzId)
    OnlineWhenDB.myEntry = {
        name     = name,
        realm    = OnlineWhenDB.settings.realm or GetRealmName(),
        spec     = spec,
        class    = class,
        level    = level,
        onlineAt = onlineAt,
        timezone = tzId,
        updated  = time(),
    }
    if OW.Protocol then
        OW.Protocol.BroadcastSelf()
    end
end

-- Upsert a peer received from the network. Only updates if the incoming record
-- is newer. Returns true if the record was updated.
function OW.UpsertPeer(key, entry)
    local existing = OnlineWhenDB.peers[key]
    if existing and existing.updated and entry.updated and existing.updated >= entry.updated then
        return false
    end
    OnlineWhenDB.peers[key] = entry
    -- Live-update the Players tab if it is currently visible
    if OW.TabPlayers and OW.UI and OW.UI.GetCurrentTab and OW.UI.GetCurrentTab() == 2 then
        OW.TabPlayers.Refresh()
    end
    return true
end

-- Remove peers whose record is older than 14 days.
function OW.PurgeStalePeers()
    local staleCutoff = time() - (14 * 24 * 60 * 60)
    for key, peer in pairs(OnlineWhenDB.peers) do
        if peer.updated and peer.updated < staleCutoff then
            OnlineWhenDB.peers[key] = nil
        end
    end
end

-- Remove entries whose scheduled time is more than 30 minutes in the past,
-- unless the player is currently online (in which case keep them regardless).
function OW.PurgeExpiredPeers()
    local gracePeriodSecs = 30 * 60   -- 30-minute grace period
    local now             = time()
    for key, peer in pairs(OnlineWhenDB.peers) do
        if peer.onlineAt and peer.onlineAt < (now - gracePeriodSecs) then
            local status = OW.GetStatusForEntry and OW.GetStatusForEntry(peer.name) or OW.STATUS.UNKNOWN
            if status ~= OW.STATUS.ONLINE then
                OnlineWhenDB.peers[key] = nil
            end
        end
    end
    local myEntry = OnlineWhenDB.myEntry
    if myEntry and myEntry.onlineAt and myEntry.onlineAt < (now - gracePeriodSecs) then
        local status = OW.GetStatusForEntry and OW.GetStatusForEntry(myEntry.name) or OW.STATUS.UNKNOWN
        if status ~= OW.STATUS.ONLINE then
            OnlineWhenDB.myEntry = nil
        end
    end
end

-- Return all entries (self + peers) filtered to the local realm.
function OW.GetAllEntries()
    local realm  = OnlineWhenDB.settings.realm
    local result = {}
    local myEntry = OnlineWhenDB.myEntry
    if myEntry and (not realm or myEntry.realm == realm) then
        table.insert(result, myEntry)
    end
    for _, peer in pairs(OnlineWhenDB.peers) do
        if not realm or peer.realm == realm then
            table.insert(result, peer)
        end
    end
    return result
end
