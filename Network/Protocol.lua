-- Network/Protocol.lua — Network sync engine
-- Transport: SendChatMessage("OW:...", "CHANNEL") / CHAT_MSG_CHANNEL.
-- SendAddonMessage("CHANNEL") is not supported in TBC Classic; plain channel
-- chat messages are used instead. A chat frame filter suppresses them from display.

local addonName, OW = ...
OW.Protocol = {}
local P = OW.Protocol

local CHANNEL_PREFIX = "ow"   -- realm name appended at runtime, e.g. "owthunderstrike"
local MSG_PREFIX     = "OW:"  -- prepended to every chat message we send
local MSG_VERSION    = "1"
local VALID_ROLES    = { Tank = true, Heal = true, DPS = true }
-- Sanity bounds for timestamps: 30 days in the past, 60 days in the future
local TS_MIN_OFFSET  = -30 * 24 * 60 * 60
local TS_MAX_OFFSET  =  60 * 24 * 60 * 60

local channelName = ""
local channelNum  = 0

-- ---------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------

local function sendMsg(msg)
    if channelNum == 0 then return end
    SendChatMessage(MSG_PREFIX .. msg, "CHANNEL", nil, channelNum)
end

-- ---------------------------------------------------------------------------
-- Suppress our addon messages from appearing in chat frames
-- ---------------------------------------------------------------------------

local function isMsgPrefixed(msg)
    return type(msg) == "string" and msg:sub(1, #MSG_PREFIX) == MSG_PREFIX
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(_, _, msg)
        if isMsgPrefixed(msg) then return true end
    end)
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

local function refreshChannelNum()
    if channelName == "" then channelNum = 0; return 0 end
    local n = GetChannelName(channelName)
    channelNum = (n and n > 0) and n or 0
    return channelNum
end

-- JoinChannelByName is hardware-event restricted in TBC Classic Anniversary —
-- it silently does nothing when called from timers or event handlers.
-- Mirror AutoLayer's proven approach: hook WorldFrame OnMouseDown so the call
-- happens inside a real hardware event on the player's first click.
local channelJoinHooked = false

function P.JoinSyncChannel()
    local realm     = (OnlineWhenDB and OnlineWhenDB.settings.realm) or GetRealmName()
    local safeRealm = realm:gsub("[ %-]", ""):lower()
    channelName     = CHANNEL_PREFIX .. safeRealm

    if not channelJoinHooked then
        channelJoinHooked = true
        WorldFrame:HookScript("OnMouseDown", function()
            if channelNum == 0 then
                JoinChannelByName(channelName)
                refreshChannelNum()
            end
        end)
    end
end

-- CHAT_MSG_CHANNEL_NOTICE fires when we successfully join a channel and
-- passes the assigned slot number directly — no polling needed.
-- On first join, immediately broadcast self and request peers so sync
-- happens automatically without needing to click the Sync button.
function P.OnChannelNotice(noticeType, _, _, _, _, _, _, num, noticedName)
    if (noticeType == "YOU_JOINED_CHANNEL" or noticeType == "YOU_CHANGED")
    and noticedName and channelName ~= ""
    and noticedName:lower() == channelName:lower() then
        local firstJoin = (channelNum == 0)
        channelNum = num
        if firstJoin then
            P.BroadcastSelf()
            C_Timer.After(1, P.RequestPeers)
        end
    end
end

-- Called from Init when CHANNEL_UI_UPDATE fires (channels renumber on join/leave).
function P.OnChannelUpdate()
    refreshChannelNum()
end

-- ---------------------------------------------------------------------------
-- Serialization
-- ---------------------------------------------------------------------------
-- Wire format: VERSION;TYPE;field1;field2;...  (semicolon — pipe is WoW's color escape)
-- ANN: 1;ANN;Name;Realm;Role;Level;OnlineAtUTC;TzId;UpdatedUTC
-- REQ: 1;REQ;Name;Realm

local SEP = ";"

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

local function split(str, sep)
    local parts = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

function P.Deserialize(message)
    return split(message, SEP)
end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------

local function validateANN(fields)
    -- fields: [1]=version [2]="ANN" [3]=name [4]=realm [5]=role
    --         [6]=level [7]=onlineAt [8]=tzId [9]=updated
    if #fields ~= 9 then return false end
    if fields[1] ~= MSG_VERSION then return false end
    if not VALID_ROLES[fields[5]] then return false end

    local level = tonumber(fields[6])
    if not level or level < 1 or level > 70 then return false end

    local onlineAt = tonumber(fields[7])
    local updated  = tonumber(fields[9])
    if not onlineAt or not updated then return false end

    local now = time()
    if onlineAt < now + TS_MIN_OFFSET or onlineAt > now + TS_MAX_OFFSET then return false end
    if updated  < now + TS_MIN_OFFSET or updated  > now + 7200           then return false end

    return true
end

-- ---------------------------------------------------------------------------
-- Public send
-- ---------------------------------------------------------------------------

function P.BroadcastSelf()
    local myEntry = OnlineWhen.GetMyEntry()
    if not myEntry then return end
    refreshChannelNum()
    sendMsg(P.SerializeANN(myEntry))
end

function P.RequestPeers()
    refreshChannelNum()
    if channelNum == 0 then return end
    local myName  = UnitName("player") or ""
    local myRealm = (OnlineWhenDB and OnlineWhenDB.settings.realm) or GetRealmName()
    sendMsg(P.SerializeREQ(myName, myRealm))
end

-- ---------------------------------------------------------------------------
-- Receiving — CHAT_MSG_CHANNEL
-- ---------------------------------------------------------------------------

function P.OnChannelMessage(msg, sender, _, _, _, _, _, msgChannelNum)
    if msgChannelNum ~= channelNum then return end
    if not isMsgPrefixed(msg) then return end

    local myName     = UnitName("player") or ""
    local senderName = sender:match("^([^%-]+)") or sender
    if senderName == myName then return end

    local payload = msg:sub(#MSG_PREFIX + 1)
    local fields  = P.Deserialize(payload)
    if not fields or #fields < 2 then return end

    local msgType = fields[2]
    if msgType == "ANN" then
        P.HandleANN(fields)
    elseif msgType == "REQ" then
        P.HandleREQ(fields)
    end
end

function P.HandleANN(fields)
    if not validateANN(fields) then return end

    local myRealm  = OnlineWhenDB and OnlineWhenDB.settings.realm
    local msgRealm = fields[4]
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
