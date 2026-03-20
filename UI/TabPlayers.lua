-- UI/TabPlayers.lua — Players tab: sortable, scrollable table.
-- Primary time (top):    Server Time  e.g. "2024-03-10 21:30 ST  (in 2 hours)"
-- Secondary time (btm):  Viewer's local tz  e.g. "19:30 CET"

local addonName, OW = ...
OW.TabPlayers = {}
local TL = OW.TabPlayers

-- Sort state
local sortColumn = "time"
local sortDir    = "ASC"

-- Layout constants
-- Content width = WINDOW_W(620) - INSET*2(12) = 608
-- scrollFrame right offset = 22 (scrollbar area)
-- Actual scrollable content width ≈ 608 - 22 = 586, minus scrollbar ~16 = 570 → use 560
local CONTENT_W  = 560
local ROW_HEIGHT = 30
local MAX_ROWS   = 50   -- pool size; scroll handles visibility

local COL_X = { name = 0,   role = 145, level = 210, time = 280 }
local COL_W = { name = 140, role = 60,  level = 65,  time = 280 }

local headerBtns   = {}
local rowPool      = {}
local scrollFrame  = nil
local contentFrame = nil
local refreshBtn   = nil
local clearBtn     = nil

local ROLE_ORDER = { Tank = 1, Heal = 2, DPS = 3 }

-- Colors for dark background
local WHITE      = { 1.0,  1.0,  1.0,  1.0 }
local DIM        = { 0.5,  0.5,  0.55, 1.0 }
local ROLE_COLOR = {
    Tank = { 0.3, 0.5, 1.0, 1.0 },
    Heal = { 0.2, 0.9, 0.2, 1.0 },
    DPS  = { 1.0, 0.3, 0.3, 1.0 },
}

-- ---------------------------------------------------------------------------
-- Sorting
-- ---------------------------------------------------------------------------

local function sortEntries(entries)
    table.sort(entries, function(a, b)
        if not a or not b then return false end
        local av, bv
        if sortColumn == "name" then
            av = (a.name or ""):lower()
            bv = (b.name or ""):lower()
        elseif sortColumn == "role" then
            av = ROLE_ORDER[a.role] or 99
            bv = ROLE_ORDER[b.role] or 99
        elseif sortColumn == "level" then
            av = a.level or 0
            bv = b.level or 0
        else
            av = a.onlineAt or 0
            bv = b.onlineAt or 0
        end
        if sortDir == "ASC" then return av < bv else return av > bv end
    end)
end

local function setSort(col)
    if sortColumn == col then
        sortDir = (sortDir == "ASC") and "DESC" or "ASC"
    else
        sortColumn = col
        sortDir = "ASC"
    end
    TL.Refresh()
end

local function arrowFor(col)
    if sortColumn ~= col then return "" end
    return sortDir == "ASC" and " ^" or " v"
end

-- ---------------------------------------------------------------------------
-- Time formatting
-- Returns: primaryStr (server/UTC), secondaryStr (viewer's local, abbr only)
-- ---------------------------------------------------------------------------

-- Build "in X day(s) Y hour(s) Z minute(s)" or "(now)" relative label.
local function formatRelative(utcTs)
    local now  = (GetServerTime and GetServerTime()) or time()
    local diff = utcTs - now
    if diff <= 0 then return "(past)" end

    local totalMin = math.floor(diff / 60)
    local days     = math.floor(totalMin / 1440)
    local hours    = math.floor((totalMin % 1440) / 60)
    local mins     = totalMin % 60

    local parts = {}
    if days  > 0 then parts[#parts+1] = days  .. (days  == 1 and " day"    or " days")    end
    if hours > 0 then parts[#parts+1] = hours .. (hours == 1 and " hour"   or " hours")   end
    if mins  > 0 then parts[#parts+1] = mins  .. (mins  == 1 and " minute" or " minutes") end
    if #parts == 0 then return "(in less than a minute)" end
    return "(in " .. table.concat(parts, " ") .. ")"
end

local function formatTimes(utcTs)
    if not utcTs or utcTs == 0 then return "—", "" end

    -- Compute server's UTC offset: GetGameTime() returns server local H:M, GetServerTime() is UTC
    local svrH, svrM = GetGameTime()
    local utcNow     = (GetServerTime and GetServerTime()) or time()
    local utcH       = tonumber(date("!%H", utcNow))
    local utcMi      = tonumber(date("!%M", utcNow))
    local svrOffMin  = (svrH * 60 + svrM) - (utcH * 60 + utcMi)
    if svrOffMin >  720 then svrOffMin = svrOffMin - 1440 end
    if svrOffMin < -720 then svrOffMin = svrOffMin + 1440 end

    -- Primary: server local time + relative countdown
    local svrTs      = utcTs + svrOffMin * 60
    local serverStr  = date("!%Y-%m-%d %H:%M", svrTs) .. " ST"
    local relStr     = formatRelative(utcTs)
    local primaryStr = serverStr .. "  " .. relStr

    -- Secondary: time-only in viewer's timezone (e.g. "19:30 CET (Local Time)")
    local myEntry      = OnlineWhen.GetMyEntry()
    local displayTz    = (myEntry and myEntry.timezone) or "UTC"
    local secondaryStr = OW.FormatTimeOnly(utcTs, displayTz) .. " (Local Time)"

    return primaryStr, secondaryStr
end

-- ---------------------------------------------------------------------------
-- Row rendering
-- ---------------------------------------------------------------------------

local function updateRows(entries)
    local now = (GetServerTime and GetServerTime()) or time()

    for i, row in ipairs(rowPool) do
        local entry = entries[i]
        if entry then
            local isPast = entry.onlineAt and entry.onlineAt <= now
            local alpha  = isPast and 0.38 or 1.0

            local primaryStr, secondaryStr = formatTimes(entry.onlineAt)

            row.name:SetText(entry.name or "?")
            row.name:SetTextColor(1, 1, 1, alpha)

            local rc = ROLE_COLOR[entry.role] or { 0.8, 0.8, 0.8, 1 }
            row.role:SetTextColor(rc[1], rc[2], rc[3], alpha)
            row.role:SetText(entry.role or "?")

            row.level:SetText(entry.level and tostring(entry.level) or "?")
            row.level:SetTextColor(1, 1, 1, alpha)

            row.timePrimary:SetText(primaryStr)
            row.timePrimary:SetTextColor(1, 1, 1, alpha)

            row.timeSecondary:SetText(secondaryStr)
            row.timeSecondary:SetTextColor(unpack(DIM))
            row.timeSecondary:SetAlpha(alpha)

            row.frame:Show()
        else
            row.frame:Hide()
        end
    end

    -- Resize content frame so scrollbar range reflects actual entry count
    if contentFrame then
        contentFrame:SetHeight(math.max(#entries, 1) * ROW_HEIGHT)
    end
end

-- ---------------------------------------------------------------------------
-- Public: Refresh
-- ---------------------------------------------------------------------------

function TL.Refresh()
    local entries = OnlineWhen.GetAllEntries()
    sortEntries(entries)
    updateRows(entries)

    local L = OW.L
    if headerBtns.name then
        headerBtns.name:SetText((L.COL_NAME or "Character Name") .. arrowFor("name"))
    end
    if headerBtns.role then
        headerBtns.role:SetText((L.COL_ROLE or "Role") .. arrowFor("role"))
    end
    if headerBtns.level then
        headerBtns.level:SetText((L.COL_LEVEL or "Level") .. arrowFor("level"))
    end
    if headerBtns.time then
        headerBtns.time:SetText((L.COL_TIME or "Online At") .. arrowFor("time"))
    end
end

-- ---------------------------------------------------------------------------
-- Build
-- ---------------------------------------------------------------------------

function TL.Build(parent)
    local L = OW.L
    local headerY = -4

    -- ---- Column headers ----
    local function makeHeader(col, defaultLabel, px, pw)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", px, headerY)
        btn:SetSize(pw, 20)
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        btn:SetText(defaultLabel)
        btn:GetFontString():SetJustifyH("LEFT")
        btn:GetFontString():SetTextColor(unpack(WHITE))
        btn:SetScript("OnClick", function() setSort(col) end)

        local line = btn:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0.3, 0.3, 0.35, 1)
        line:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
        line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(1)

        headerBtns[col] = btn
    end

    makeHeader("name",  (L.COL_NAME  or "Character Name") .. " ^", COL_X.name,  COL_W.name)
    makeHeader("role",  L.COL_ROLE  or "Role",                    COL_X.role,  COL_W.role)
    makeHeader("level", L.COL_LEVEL or "Level",                   COL_X.level, COL_W.level)
    makeHeader("time",  L.COL_TIME  or "Online At",               COL_X.time,  COL_W.time)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.25, 0.25, 0.3, 1)
    divider:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, headerY - 20)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, headerY - 20)
    divider:SetHeight(1)

    -- ---- Scroll frame ----
    scrollFrame = CreateFrame("ScrollFrame", "OnlineWhenScrollFrame", parent,
                              "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0,   headerY - 22)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -22, 34)

    -- Content frame: fixed width so rows are always correctly sized
    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetWidth(CONTENT_W)
    contentFrame:SetHeight(ROW_HEIGHT)   -- grows dynamically in updateRows
    scrollFrame:SetScrollChild(contentFrame)

    -- ---- Row pool (MAX_ROWS pre-created; only entries-count shown) ----
    for i = 1, MAX_ROWS do
        local rowFrame = CreateFrame("Frame", nil, contentFrame)
        rowFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        rowFrame:SetSize(CONTENT_W, ROW_HEIGHT)

        -- Alternating subtle background
        if i % 2 == 0 then
            local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(1, 1, 1, 0.03)
        end

        -- Character name (vertically centred)
        local nameFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.name, 0)
        nameFs:SetWidth(COL_W.name)
        nameFs:SetJustifyH("LEFT")
        nameFs:SetTextColor(unpack(WHITE))

        -- Role (vertically centred)
        local roleFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        roleFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.role, 0)
        roleFs:SetWidth(COL_W.role)
        roleFs:SetJustifyH("LEFT")

        -- Level (vertically centred)
        local levelFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        levelFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.level, 0)
        levelFs:SetWidth(COL_W.level)
        levelFs:SetJustifyH("LEFT")
        levelFs:SetTextColor(unpack(WHITE))

        -- Server time / UTC (top line of time cell)
        local timePrimary = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timePrimary:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", COL_X.time, -4)
        timePrimary:SetWidth(COL_W.time)
        timePrimary:SetJustifyH("LEFT")
        timePrimary:SetTextColor(unpack(WHITE))

        -- Local time with tz abbreviation (bottom line, dimmer)
        local timeSecondary = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        timeSecondary:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", COL_X.time, 4)
        timeSecondary:SetWidth(COL_W.time)
        timeSecondary:SetJustifyH("LEFT")
        timeSecondary:SetTextColor(unpack(DIM))

        rowPool[i] = {
            frame         = rowFrame,
            name          = nameFs,
            role          = roleFs,
            level         = levelFs,
            timePrimary   = timePrimary,
            timeSecondary = timeSecondary,
        }
        rowFrame:Hide()
    end

    -- ---- Bottom buttons ----
    refreshBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    refreshBtn:SetSize(100, 26)
    refreshBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    refreshBtn:SetText(L.BTN_REFRESH or "Refresh")
    refreshBtn:SetScript("OnClick", function()
        OW.PurgeExpiredPeers()
        if OW.Protocol then OW.Protocol.RequestPeers() end
        refreshBtn:SetText(L.BTN_REQUESTING or "Syncing...")
        C_Timer.After(3, function()
            if refreshBtn then refreshBtn:SetText(L.BTN_REFRESH or "Sync") end
            OW.PurgeExpiredPeers()
            TL.Refresh()
        end)
    end)

    clearBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    clearBtn:SetSize(100, 26)
    clearBtn:SetPoint("BOTTOMRIGHT", refreshBtn, "BOTTOMLEFT", -6, 0)
    clearBtn:SetText(L.BTN_CLEAR_OLD or "Clear Past")
    clearBtn:SetScript("OnClick", function()
        OW.PurgeExpiredPeers()
        TL.Refresh()
    end)

    TL.Refresh()
end
