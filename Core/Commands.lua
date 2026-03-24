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
    local printLine = function(line) print(line) end
    printLine("|cFFFFD700=== OnlineWhen Commands ===|r")
    printLine("|cFF00FF00/ow|r or |cFF00FF00/onlinewhen|r - Toggle the OnlineWhen window")
    printLine("|cFF00FF00/ow help|r - Show this help text")
    printLine("|cFF00FF00/ow channel|r - Print the active sync channel name and number")
    printLine("|cFF00FF00/ow reset|r - Wipe the saved database and clear the player list")
    printLine("|cFF00FF00/ow debug|r - Dump the full saved database to the chat window")
end

-- ---------------------------------------------------------------------------
-- Debug
-- ---------------------------------------------------------------------------

function OW.PrintDebug()
    local db = OnlineWhenDB
    print("|cFFFFD700=== OnlineWhen Debug ===|r")
    print(string.format("  settings.realm = %s", tostring(db.settings.realm)))

    local myEntry = db.myEntry
    if myEntry then
        print("  myEntry = {")
        print(string.format("    name     = %s", tostring(myEntry.name)))
        print(string.format("    spec     = %s", tostring(myEntry.spec)))
        print(string.format("    class    = %s", tostring(myEntry.class)))
        print(string.format("    level    = %s", tostring(myEntry.level)))
        print(string.format("    onlineAt = %d", myEntry.onlineAt or 0))
        print(string.format("    timezone = %s", tostring(myEntry.timezone)))
        print(string.format("    updated  = %d", myEntry.updated or 0))
        print("  }")
    else
        print("  myEntry = (none)")
    end

    local peerCount = 0
    for _ in pairs(db.peers) do peerCount = peerCount + 1 end
    print(string.format("  peers (%d) = {", peerCount))
    for key, peer in pairs(db.peers) do
        print(string.format("    [\"%s\"] = {", key))
        print(string.format("      name     = %s", tostring(peer.name)))
        print(string.format("      spec     = %s", tostring(peer.spec)))
        print(string.format("      class    = %s", tostring(peer.class)))
        print(string.format("      level    = %s", tostring(peer.level)))
        print(string.format("      onlineAt = %d", peer.onlineAt or 0))
        print(string.format("      timezone = %s", tostring(peer.timezone)))
        print(string.format("      updated  = %d", peer.updated or 0))
        print("    }")
    end
    print("  }")
end
