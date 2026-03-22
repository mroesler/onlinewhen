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
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
eventFrame:RegisterEvent("CHANNEL_UI_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OW.OnLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = ...
        if isInitialLogin and OW.Protocol then OW.Protocol.JoinSyncChannel() end
    elseif event == "CHAT_MSG_ADDON" then
        if OW.Protocol and OW.Protocol.OnMessage then OW.Protocol.OnMessage(...) end
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        if OW.Protocol then OW.Protocol.OnChannelNotice(...) end
    elseif event == "CHANNEL_UI_UPDATE" then
        if OW.Protocol then OW.Protocol.OnChannelUpdate() end
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

    if OW.UI then
        OW.UI.CreateMainWindow()
    end

    -- Initial broadcast and peer request happen in Protocol.OnChannelNotice
    -- once the channel is confirmed joined on the player's first click.
end

function OW.OnLogout()
    if OW.UI then OW.UI.SaveWindowPosition() end
end
