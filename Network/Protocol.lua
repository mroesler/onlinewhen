-- Network/Protocol.lua — Network sync engine
-- Handles addon channel join, message serialization, broadcast, and receive.

local addonName, OW = ...
OW.Protocol = {}
local P = OW.Protocol

local ADDON_PREFIX   = "OnlineWhen"
local CHANNEL_PREFIX = "OW_"  -- realm appended at runtime: "OW_Mankrik"
local MSG_VERSION    = "1"
local VALID_ROLES    = { Tank = true, Heal = true, DPS = true }
-- Sanity bounds for timestamps: 30 days in the past, 60 days in the future
local TS_MIN_OFFSET  = -30 * 24 * 60 * 60
local TS_MAX_OFFSET  =  60 * 24 * 60 * 60

local channelName = ""
local channelNum  = 0

-- API shim: SendAddonMessage lives under C_ChatInfo in newer client builds.
local function sendAddonMsg(prefix, msg, distrib, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, msg, distrib, target)
    else
        SendAddonMessage(prefix, msg, distrib, target)
    end
end

-- Register the addon message prefix so WoW routes messages to our handler.
-- TBC Anniversary uses a modernised client where the global may live under C_ChatInfo.
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(ADDON_PREFIX)
end

-- ---------------------------------------------------------------------------
-- Channel management
-- ---------------------------------------------------------------------------

function P.GetChannelName()
    return channelName
end

function P.GetChannelNum()
    return channelNum
end

function P.JoinSyncChannel()
    local realm = (OnlineWhenDB and OnlineWhenDB.settings.realm) or GetRealmName()
    -- Sanitize realm name: remove spaces and hyphens to keep channel name simple
    local safeRealm = realm:gsub("[ %-]", "")
    channelName = CHANNEL_PREFIX .. safeRealm
    JoinChannelByName(channelName)
    -- Channel number may not be available immediately; we'll re-fetch before sending
end

local function refreshChannelNum()
    local n = GetChannelName(channelName)
    channelNum = n or 0
    return channelNum
end

-- ---------------------------------------------------------------------------
-- Serialization
-- ---------------------------------------------------------------------------
-- Wire format: VERSION|TYPE|field1|field2|...
-- ANN: 1|ANN|Name|Realm|Role|Level|OnlineAtUTC|TzId|UpdatedUTC
-- REQ: 1|REQ|Name|Realm

local SEP = "|"

function P.SerializeANN(entry)
    return table.concat({
        MSG_VERSION,
        "ANN",
        entry.name     or "",
        entry.realm    or "",
        entry.role     or "",
        tostring(entry.level    or 1),
        tostring(entry.onlineAt or 0),
        entry.timezone or "UTC",
        tostring(entry.updated  or 0),
    }, SEP)
end

function P.SerializeREQ(name, realm)
    return table.concat({ MSG_VERSION, "REQ", name or "", realm or "" }, SEP)
end

-- Split a string by a separator character (single char only).
local function split(str, sep)
    local parts = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

function P.Deserialize(message)
    local fields = split(message, SEP)
    return fields
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

local function validateANN(fields)
    -- fields: [1]=version [2]="ANN" [3]=name [4]=realm [5]=role
    --         [6]=level [7]=onlineAt [8]=tzId [9]=updated
    if #fields ~= 9 then return false, "field count" end
    if fields[1] ~= MSG_VERSION then return false, "version" end
    if fields[2] ~= "ANN" then return false, "type" end
    if not VALID_ROLES[fields[5]] then return false, "role" end

    local level    = tonumber(fields[6])
    if not level or level < 1 or level > 70 then return false, "level out of range" end

    local onlineAt = tonumber(fields[7])
    local updated  = tonumber(fields[9])
    if not onlineAt or not updated then return false, "timestamp not numeric" end

    local now = time()
    if onlineAt < now + TS_MIN_OFFSET or onlineAt > now + TS_MAX_OFFSET then
        return false, "onlineAt out of range"
    end
    if updated < now + TS_MIN_OFFSET or updated > now + 300 then
        return false, "updated out of range"
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------

function P.BroadcastSelf()
    local myEntry = OnlineWhen.GetMyEntry()
    if not myEntry then return end  -- nothing to broadcast yet

    refreshChannelNum()
    if channelNum == 0 then return end  -- not in channel yet

    local msg = P.SerializeANN(myEntry)
    if #msg > 255 then
        -- Shouldn't happen with our format, but guard anyway
        return
    end
    sendAddonMsg(ADDON_PREFIX, msg, "CHANNEL", channelNum)
end

function P.RequestPeers()
    refreshChannelNum()
    if channelNum == 0 then return end

    local myName  = UnitName("player") or ""
    local myRealm = (OnlineWhenDB and OnlineWhenDB.settings.realm) or GetRealmName()
    local msg     = P.SerializeREQ(myName, myRealm)
    sendAddonMsg(ADDON_PREFIX, msg, "CHANNEL", channelNum)
end

-- ---------------------------------------------------------------------------
-- Receiving
-- ---------------------------------------------------------------------------

function P.OnMessage(prefix, message, distribution, sender)
    if prefix ~= ADDON_PREFIX then return end
    if not message or message == "" then return end

    -- Ignore our own messages (sender format is "Name-Realm" or just "Name")
    local myName = UnitName("player") or ""
    local senderName = sender:match("^([^%-]+)") or sender
    if senderName == myName then return end

    local fields = P.Deserialize(message)
    if not fields or #fields < 2 then return end

    local msgType = fields[2]
    if msgType == "ANN" then
        P.HandleANN(fields)
    elseif msgType == "REQ" then
        P.HandleREQ(fields)
    end
end

function P.HandleANN(fields)
    local ok, reason = validateANN(fields)
    if not ok then return end  -- silently drop invalid messages

    local myRealm = OnlineWhenDB and OnlineWhenDB.settings.realm
    local msgRealm = fields[4]

    -- Realm guard: only accept entries from same realm
    if myRealm and msgRealm ~= myRealm then return end

    local entry = {
        name     = fields[3],
        realm    = fields[4],
        role     = fields[5],
        level    = tonumber(fields[6]),
        onlineAt = tonumber(fields[7]),
        timezone = fields[8],
        updated  = tonumber(fields[9]),
    }

    local key = entry.name .. "-" .. entry.realm
    OnlineWhen.UpsertPeer(key, entry)
end

function P.HandleREQ(fields)
    -- Staggered response to avoid broadcast storm
    C_Timer.After(math.random(0, 5), P.BroadcastSelf)
end
