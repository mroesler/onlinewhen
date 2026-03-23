-- Core/Init.lua — Addon lifecycle: namespace exposure, event handling, login sequence.

local addonName, OW = ...

-- Expose the shared namespace as a global so all modules can reference OnlineWhen.*
OnlineWhen = OW

-- ---------------------------------------------------------------------------
-- Event handling
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "OnlineWhenEventFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
eventFrame:RegisterEvent("CHANNEL_UI_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OW.OnLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if OW.Protocol then OW.Protocol.JoinSyncChannel() end
    elseif event == "CHAT_MSG_CHANNEL" then
        if OW.Protocol and OW.Protocol.OnChannelMessage then OW.Protocol.OnChannelMessage(...) end
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        if OW.Protocol then OW.Protocol.OnChannelNotice(...) end
    elseif event == "CHANNEL_UI_UPDATE" then
        if OW.Protocol then OW.Protocol.OnChannelUpdate() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if OW.TabPlayers and OW.UI and OW.UI.GetCurrentTab and OW.UI.GetCurrentTab() == 2 then
            OW.TabPlayers.Refresh()
        end
    elseif event == "PLAYER_LOGOUT" then
        OW.OnLogout()
    end
end)

-- ---------------------------------------------------------------------------
-- Login / logout sequence
-- ---------------------------------------------------------------------------

function OW.OnLogin()
    OW.EnsureDefaults()

    -- Store realm once, permanently — never shown in the UI
    local db = OnlineWhenDB
    if not db.settings.realm then
        db.settings.realm = GetRealmName()
    end

    OW.PurgeStalePeers()

    -- Mark self as online immediately
    local myName = UnitName("player")
    if myName and OW.playerStatus then
        OW.playerStatus[myName] = OW.STATUS_ONLINE
    end

    if OW.UI then
        OW.UI.CreateMainWindow()
    end

    -- Initial broadcast and peer request happen in Protocol.OnChannelNotice
    -- once the channel is confirmed joined on the player's first click.
end

function OW.OnLogout()
    -- Notify peers we are going offline before disconnecting
    if OW.Protocol then OW.Protocol.BroadcastBye() end
    if OW.UI then OW.UI.SaveWindowPosition() end
end
