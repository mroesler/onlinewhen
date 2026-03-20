-- Core/Commands.lua — Slash commands and debug output.
-- Registers /ow and /onlinewhen. Database mutations are delegated to Database.lua.

local addonName, OW = ...

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

SLASH_ONLINEWHEN1 = "/onlinewhen"
SLASH_ONLINEWHEN2 = "/ow"

SlashCmdList["ONLINEWHEN"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "help" then
        OW.PrintHelp()
    elseif msg == "debug" then
        OW.PrintDebug()
    elseif msg == "reset" then
        -- Wipe DB and refresh all UI
        OnlineWhenDB = nil
        OW.EnsureDefaults()
        if OW.TabPlayers then OW.TabPlayers.Refresh() end
        print("|cFF00FF00OnlineWhen:|r " .. (OW.L.RESET_DONE or "DB reset."))
    elseif msg == "channel" then
        if OW.Protocol then
            local name = OW.Protocol.GetChannelName()
            local num  = OW.Protocol.GetChannelNum()
            print(string.format("|cFF00FF00OnlineWhen:|r Sync channel: %s (number: %d)", name, num))
        end
    else
        if OW.UI then OW.UI.Toggle() end
    end
end

-- ---------------------------------------------------------------------------
-- Help
-- ---------------------------------------------------------------------------

function OW.PrintHelp()
    local p = function(line) print(line) end
    p("|cFFFFD700=== OnlineWhen Commands ===|r")
    p("|cFF00FF00/ow|r or |cFF00FF00/onlinewhen|r  — Toggle the OnlineWhen window")
    p("|cFF00FF00/ow help|r                — Show this help text")
    p("|cFF00FF00/ow channel|r             — Print the active sync channel name and number")
    p("|cFF00FF00/ow reset|r               — Wipe the saved database and clear the player list")
    p("|cFF00FF00/ow debug|r               — Dump the full saved database to the chat window")
end

-- ---------------------------------------------------------------------------
-- Debug
-- ---------------------------------------------------------------------------

function OW.PrintDebug()
    local db = OnlineWhenDB
    print("|cFFFFD700=== OnlineWhen Debug ===|r")
    print(string.format("  Realm: %s", tostring(db.settings.realm)))

    local my = db.myEntry
    if my then
        print("  My Entry:")
        print(string.format("    %s | %s | onlineAt=%d | tz=%s | updated=%d",
            tostring(my.name), tostring(my.role),
            my.onlineAt or 0, tostring(my.timezone), my.updated or 0))
    else
        print("  My Entry: (none)")
    end

    local count = 0
    for _ in pairs(db.peers) do count = count + 1 end
    print(string.format("  Peers (%d):", count))
    for key, peer in pairs(db.peers) do
        print(string.format("    [%s] %s | %s | onlineAt=%d | updated=%d",
            key, tostring(peer.name), tostring(peer.role),
            peer.onlineAt or 0, peer.updated or 0))
    end
end
