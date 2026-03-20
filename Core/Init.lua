-- Core/Init.lua — Addon lifecycle: namespace exposure, event handling, login sequence.

local addonName, OW = ...

-- Expose the shared namespace as a global so all modules can reference OnlineWhen.*
OnlineWhen = OW

-- ---------------------------------------------------------------------------
-- Event handling
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "OnlineWhenEventFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OW.OnLogin()
    elseif event == "CHAT_MSG_ADDON" then
        if OW.Protocol and OW.Protocol.OnMessage then OW.Protocol.OnMessage(...) end
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

    if OW.Protocol then
        OW.Protocol.JoinSyncChannel()
        C_Timer.After(3, function()
            OW.Protocol.BroadcastSelf()
            C_Timer.After(1, OW.Protocol.RequestPeers)
        end)
    end
end

function OW.OnLogout()
    if OW.UI then OW.UI.SaveWindowPosition() end
end
