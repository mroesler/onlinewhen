-- UI/TabPlayers.lua — Players tab: sortable, scrollable table.
-- Primary time (top):    Server Time  e.g. "2024-03-10 21:30 ST  (in 2 hours)"
-- Secondary time (btm):  Viewer's local tz  e.g. "19:30 CET"

local addonName, OW = ...
OW.TabPlayers = {}
local TL = OW.TabPlayers

-- Sort state
local sortColumn = "time"
local sortDir    = "ASC"

-- Pagination state
local currentPage = 1

-- Layout constants
local CONTENT_W      = 938   -- full tab frame width (WINDOW_W 950 - INSET*2 6)
local ROW_HEIGHT     = 30
local PAGE_SIZE      = 12   -- entries per page
local MAX_ROWS       = PAGE_SIZE
local FILTER_TOP_PAD = 8    -- gap between tab area and filter bar
local FILTER_H       = 28   -- filter bar height
local FILTER_BOT_PAD = 8    -- gap between filter bar and column headers
local ROWS_BOT_PAD   = 6    -- gap below last row before pagination/buttons

local COL_X = { status = 0, name = 22, level = 168, class = 218, spec = 314, activity = 420, time = 576, actions = 828 }
local COL_W = { status = 18, name = 140, level = 44, class = 90, spec = 100, activity = 150, time = 246, actions = 90  }

local headerBtns   = {}
local rowPool      = {}
local contentFrame = nil
local refreshBtn   = nil
local clearBtn     = nil
local prevPageBtn  = nil
local nextPageBtn  = nil
local pageLabel    = nil

-- Filter state (nil = no filter applied)
local filterLevel  = nil   -- { min=N, max=N } level range, or nil
local filterSpec   = nil   -- OW.SPEC enum integer (class-qualified)
local filterStatus = nil   -- OW.STATUS integer
local filterClass  = nil   -- OW.CLASS integer
local openDropdown = nil   -- currently visible dropdown popup
local statusFilterBtn = nil
local levelFilterBtn  = nil
local classFilterBtn  = nil
local specFilterBtn   = nil  -- forward ref; set during Build, read by class filter onChange

-- Colors for dark background
local WHITE      = { 1.0,  1.0,  1.0,  1.0 }
local DIM        = { 0.5,  0.5,  0.55, 1.0 }

local CLASS_COLOR = OW.CLASS_COLOR   -- shared from Core/Classes.lua

-- ---------------------------------------------------------------------------
-- Sorting
-- ---------------------------------------------------------------------------

-- Display order for status sort: online first, then unknown, then offline
local STATUS_SORT_ORDER = {
    [OW.STATUS.ONLINE]  = 1,
    [OW.STATUS.UNKNOWN] = 2,
    [OW.STATUS.OFFLINE] = 3,
}

local function sortEntries(entries)
    table.sort(entries, function(a, b)
        if not a or not b then return false end
        local sortValA, sortValB
        if sortColumn == "name" then
            sortValA = (a.name or ""):lower()
            sortValB = (b.name or ""):lower()
        elseif sortColumn == "spec" then
            sortValA = (a.spec or ""):lower()
            sortValB = (b.spec or ""):lower()
        elseif sortColumn == "level" then
            sortValA = a.level or 0
            sortValB = b.level or 0
        elseif sortColumn == "class" then
            sortValA = (a.class or ""):lower()
            sortValB = (b.class or ""):lower()
        elseif sortColumn == "activity" then
            local aNil = (a.primaryActivity == nil)
            local bNil = (b.primaryActivity == nil)
            if aNil ~= bNil then
                return bNil   -- nil entries always sort last (non-nil < nil in ASC, non-nil > nil in DESC handled by returning bNil directly before the ASC/DESC flip below)
            end
            sortValA = ((a.exactActivity and a.exactActivity ~= "") and a.exactActivity or (a.primaryActivity or "")):lower()
            sortValB = ((b.exactActivity and b.exactActivity ~= "") and b.exactActivity or (b.primaryActivity or "")):lower()
        elseif sortColumn == "status" then
            local statusA = OW.GetStatusForEntry and OW.GetStatusForEntry(a.name) or OW.STATUS.UNKNOWN
            local statusB = OW.GetStatusForEntry and OW.GetStatusForEntry(b.name) or OW.STATUS.UNKNOWN
            sortValA = STATUS_SORT_ORDER[statusA] or 2
            sortValB = STATUS_SORT_ORDER[statusB] or 2
        else
            sortValA = a.onlineAt or 0
            sortValB = b.onlineAt or 0
        end
        if sortDir == "ASC" then return sortValA < sortValB else return sortValA > sortValB end
    end)
end

local function setSort(col)
    if sortColumn == col then
        sortDir = (sortDir == "ASC") and "DESC" or "ASC"
    else
        sortColumn = col
        sortDir = "ASC"
    end
    currentPage = 1
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

    local GRACE = 30 * 60
    for i, row in ipairs(rowPool) do
        local entry = entries[i]
        if entry then
            local entryStatus = OW.GetStatusForEntry and OW.GetStatusForEntry(entry.name) or OW.STATUS.UNKNOWN
            local isPast = entry.onlineAt and entry.onlineAt <= (now - GRACE) and entryStatus ~= OW.STATUS.ONLINE
            local alpha  = isPast and 0.38 or 1.0

            local primaryStr, secondaryStr = formatTimes(entry.onlineAt)

            row.name:SetText(entry.name or "?")
            row.name:SetTextColor(1, 1, 1, alpha)

            -- Status dot
            if entryStatus == OW.STATUS.ONLINE then
                row.statusDot:SetVertexColor(0, 1, 0, 1)
                row.dotRegion._tip = OW.L.STATUS_ONLINE or "Online"
            elseif entryStatus == OW.STATUS.OFFLINE then
                row.statusDot:SetVertexColor(1, 0.27, 0.27, 1)
                row.dotRegion._tip = OW.L.STATUS_OFFLINE or "Offline"
            else
                row.statusDot:SetVertexColor(0.5, 0.5, 0.5, 1)
                row.dotRegion._tip = OW.L.STATUS_UNKNOWN or "Unknown"
            end

            local classColor = entry.class and CLASS_COLOR[entry.class]
            row.class:SetText(entry.class or "?")
            if classColor then
                row.class:SetTextColor(classColor[1], classColor[2], classColor[3], alpha)
            else
                row.class:SetTextColor(1, 1, 1, alpha)
            end

            row.spec:SetText(entry.spec or "?")
            row.spec:SetTextColor(1, 1, 1, alpha)

            row.activityPrimary:SetText(entry.primaryActivity or "")
            row.activityPrimary:SetTextColor(1, 1, 1, alpha)

            row.activityExact:SetText(entry.exactActivity or "")
            row.activityExact:SetTextColor(DIM[1], DIM[2], DIM[3], DIM[4])
            row.activityExact:SetAlpha(alpha)

            row.level:SetText(entry.level and tostring(entry.level) or "?")
            row.level:SetTextColor(1, 1, 1, alpha)

            row.timePrimary:SetText(primaryStr)
            row.timePrimary:SetTextColor(1, 1, 1, alpha)

            row.timeSecondary:SetText(secondaryStr)
            row.timeSecondary:SetTextColor(unpack(DIM))
            row.timeSecondary:SetAlpha(alpha)

            local myEntry  = OnlineWhen.GetMyEntry()
            local isSelf   = myEntry and entry.name == myEntry.name
            local inGroup  = false
            for j = 1, 4 do
                if UnitExists("party" .. j) and UnitName("party" .. j) == entry.name then
                    inGroup = true
                    break
                end
            end
            if isSelf or inGroup then
                row.inviteBtn:Hide()
            else
                row.inviteBtn:Show()
                local entryName = entry.name
                local canInvite = (entryStatus == OW.STATUS.ONLINE)
                row.inviteBtn:SetEnabled(canInvite)
                if canInvite then
                    row.inviteBtn:SetScript("OnEnter", nil)
                    row.inviteBtn:SetScript("OnLeave", nil)
                    row.inviteBtn:SetScript("OnClick", function()
                        SendChatMessage(
                            "Hey " .. entryName .. ", I am using OnlineWhen and would like to group with you.",
                            "WHISPER", nil, entryName)
                        SlashCmdList["INVITE"](entryName)
                    end)
                else
                    row.inviteBtn:SetScript("OnClick", nil)
                    row.inviteBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(OW.L.INVITE_OFFLINE_TIP or "User is offline or cannot be invited")
                        GameTooltip:Show()
                    end)
                    row.inviteBtn:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                end
            end

            row.frame:Show()
        else
            row.inviteBtn:Hide()
            row.frame:Hide()
        end
    end

end

-- ---------------------------------------------------------------------------
-- Dropdown helper
-- ---------------------------------------------------------------------------

local dropdownHookSet = false

local function thinBorder(f)
    local function seg(p1, p2, w, h)
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.3, 0.3, 0.35, 1)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then t:SetWidth(w) else t:SetHeight(h) end
    end
    seg("TOPLEFT",    "TOPRIGHT",    nil, 1)
    seg("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    seg("TOPLEFT",    "BOTTOMLEFT",  1,   nil)
    seg("TOPRIGHT",   "BOTTOMRIGHT", 1,   nil)
end

-- choices: array of { label=string, value=any }  (value=nil means "clear filter")
-- onChange: function(value)
-- Returns the trigger Button; set its anchor externally.
-- Supports .setChoices(newChoices, newLabel) and .setActive(bool) for dynamic updates.
local function makeDropdown(parent, width, defaultText, choices, onChange)
    if not dropdownHookSet then
        dropdownHookSet = true
        WorldFrame:HookScript("OnMouseDown", function()
            if openDropdown then openDropdown:Hide(); openDropdown = nil end
        end)
    end

    -- Trigger button
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 22)
    btn._active = true

    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(0.12, 0.12, 0.14, 1)
    thinBorder(btn)

    local btnFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnFs:SetPoint("LEFT",  btn, "LEFT",   6,   0)
    btnFs:SetPoint("RIGHT", btn, "RIGHT", -16,  0)
    btnFs:SetJustifyH("LEFT")
    btnFs:SetTextColor(unpack(WHITE))
    btnFs:SetText(defaultText)

    local arrowFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrowFs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    arrowFs:SetJustifyH("RIGHT")
    arrowFs:SetTextColor(0.55, 0.55, 0.6, 1)
    arrowFs:SetText("v")

    btn:SetScript("OnEnter", function()
        if btn._active then btnBg:SetColorTexture(0.18, 0.18, 0.22, 1) end
    end)
    btn:SetScript("OnLeave", function()
        if btn._active then btnBg:SetColorTexture(0.12, 0.12, 0.14, 1) end
    end)

    -- Popup list
    local ITEM_H   = 20
    local popup    = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(100)
    popup:SetWidth(width)
    popup:SetHeight(1)

    local popBg = popup:CreateTexture(nil, "BACKGROUND")
    popBg:SetAllPoints()
    popBg:SetColorTexture(0.09, 0.09, 0.09, 0.97)
    thinBorder(popup)

    -- Item slot pool — reused across setChoices calls; grows as needed.
    local itemSlots = {}

    local function getOrCreateSlot(i)
        if itemSlots[i] then return itemSlots[i] end
        local item = CreateFrame("Button", nil, popup)
        item:SetSize(width - 2, ITEM_H)

        local itemBg = item:CreateTexture(nil, "BACKGROUND")
        itemBg:SetAllPoints()
        itemBg:SetColorTexture(0.2, 0.4, 0.8, 0)
        item._bg = itemBg

        local itemFs = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemFs:SetPoint("LEFT", item, "LEFT", 6, 0)
        itemFs:SetJustifyH("LEFT")
        itemFs:SetTextColor(unpack(WHITE))
        item._fs = itemFs

        item:SetScript("OnEnter", function() itemBg:SetColorTexture(0.2, 0.4, 0.8, 0.35) end)
        item:SetScript("OnLeave", function() itemBg:SetColorTexture(0.2, 0.4, 0.8, 0)    end)

        itemSlots[i] = item
        return item
    end

    local function applyChoices(cs)
        popup:SetHeight(math.max(1, #cs) * ITEM_H + 6)
        for i, choice in ipairs(cs) do
            local item = getOrCreateSlot(i)
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -(i - 1) * ITEM_H - 3)
            item._fs:SetText(choice.label)
            local val = choice.value
            local lbl = choice.label
            item:SetScript("OnClick", function()
                btnFs:SetText(lbl)
                popup:Hide()
                openDropdown = nil
                onChange(val)
            end)
            item:Show()
        end
        for i = #cs + 1, #itemSlots do
            itemSlots[i]:Hide()
        end
    end

    applyChoices(choices)
    popup:Hide()

    btn:SetScript("OnClick", function()
        if not btn._active then return end
        if openDropdown and openDropdown ~= popup then openDropdown:Hide() end
        if popup:IsShown() then
            popup:Hide()
            openDropdown = nil
        else
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
            openDropdown = popup
        end
    end)

    btn._fs      = btnFs
    btn._default = defaultText
    btn.popup    = popup

    -- Update choices and reset button label. Does NOT call onChange — caller
    -- is responsible for resetting the associated filter variable before Refresh.
    btn.setChoices = function(newChoices, newLabel)
        if openDropdown == popup then popup:Hide(); openDropdown = nil end
        btnFs:SetText(newLabel or defaultText)
        applyChoices(newChoices)
    end

    -- Enable or disable the dropdown (greyed out when inactive).
    btn.setActive = function(active)
        btn._active = active
        if active then
            btnBg:SetColorTexture(0.12, 0.12, 0.14, 1)
            btnFs:SetTextColor(1, 1, 1, 1)
            arrowFs:SetTextColor(0.55, 0.55, 0.6, 1)
        else
            if openDropdown == popup then popup:Hide(); openDropdown = nil end
            btnBg:SetColorTexture(0.08, 0.08, 0.10, 1)
            btnFs:SetTextColor(0.35, 0.35, 0.4, 1)
            arrowFs:SetTextColor(0.3, 0.3, 0.35, 1)
        end
    end

    return btn
end

-- ---------------------------------------------------------------------------
-- Public: Refresh
-- ---------------------------------------------------------------------------

function TL.Refresh()
    local allEntries = OnlineWhen.GetAllEntries()
    sortEntries(allEntries)

    -- Apply active filters (AND logic)
    local entries = {}
    for _, e in ipairs(allEntries) do
        local ok = true
        if filterLevel then
            local lvl = e.level or 0
            if lvl < filterLevel.min or lvl > filterLevel.max then ok = false end
        end
        if ok and filterStatus then
            local st = OW.GetStatusForEntry and OW.GetStatusForEntry(e.name) or OW.STATUS.UNKNOWN
            if st ~= filterStatus then ok = false end
        end
        if ok and filterClass and (OW.CLASS_ID[e.class] or 0) ~= filterClass then ok = false end
        if ok and filterSpec then
            local sid = e.class and e.spec and OW.SPEC_ID[e.class] and OW.SPEC_ID[e.class][e.spec]
            if sid ~= filterSpec then ok = false end
        end
        if ok then entries[#entries + 1] = e end
    end

    local total      = #entries
    local totalPages = math.max(1, math.ceil(total / PAGE_SIZE))
    if currentPage > totalPages then currentPage = totalPages end

    local startIdx    = (currentPage - 1) * PAGE_SIZE + 1
    local pageEntries = {}
    for i = startIdx, math.min(startIdx + PAGE_SIZE - 1, total) do
        pageEntries[#pageEntries + 1] = entries[i]
    end

    updateRows(pageEntries)

    if pageLabel    then pageLabel:SetText("Page " .. currentPage .. " of " .. totalPages) end
    if prevPageBtn  then prevPageBtn:SetEnabled(currentPage > 1) end
    if nextPageBtn  then nextPageBtn:SetEnabled(currentPage < totalPages) end

    local L = OW.L
    if headerBtns.status then
        headerBtns.status:SetText((L.COL_STATUS or "S") .. arrowFor("status"))
    end
    if headerBtns.name then
        headerBtns.name:SetText((L.COL_NAME or "Character Name") .. arrowFor("name"))
    end
    if headerBtns.spec then
        headerBtns.spec:SetText((L.COL_SPEC or "Spec") .. arrowFor("spec"))
    end
    if headerBtns.level then
        headerBtns.level:SetText((L.COL_LEVEL or "Level") .. arrowFor("level"))
    end
    if headerBtns.class then
        headerBtns.class:SetText("Class" .. arrowFor("class"))
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

    -- columnHeaderY: top of column headers, pushed down to make room for the filter bar
    local columnHeaderY = -(FILTER_TOP_PAD + FILTER_H + FILTER_BOT_PAD)   -- = -44

    -- ---- Filter bar ----
    local filterBarY = -(FILTER_TOP_PAD + math.floor((FILTER_H - 22) / 2))  -- vertically centre 22px buttons in bar = -11

    -- Filter order: Status | Level | Class | Spec                [Reset →]
    statusFilterBtn = makeDropdown(parent, 120, "Any Status", {
        { label = "Any Status", value = nil                },
        { label = "Online",     value = OW.STATUS.ONLINE   },
        { label = "Offline",    value = OW.STATUS.OFFLINE  },
        { label = "Unknown",    value = OW.STATUS.UNKNOWN  },
    }, function(val)
        filterStatus = val ; currentPage = 1 ; TL.Refresh()
    end)
    statusFilterBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, filterBarY)

    local levelChoices = {
        { label = "Any Level", value = nil },
        { label = "1-9",       value = { min =  1, max =  9 } },
        { label = "10-19",     value = { min = 10, max = 19 } },
        { label = "20-29",     value = { min = 20, max = 29 } },
        { label = "30-39",     value = { min = 30, max = 39 } },
        { label = "40-49",     value = { min = 40, max = 49 } },
        { label = "50-59",     value = { min = 50, max = 59 } },
        { label = "60-69",     value = { min = 60, max = 69 } },
        { label = "70",        value = { min = 70, max = 70 } },
    }
    levelFilterBtn = makeDropdown(parent, 148, "Any Level", levelChoices, function(val)
        filterLevel = val ; currentPage = 1 ; TL.Refresh()
    end)
    levelFilterBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 130, filterBarY)

    classFilterBtn = makeDropdown(parent, 130, "Any Class", {
        { label = "Any Class", value = nil                  },
        { label = "Druid",     value = OW.CLASS.DRUID       },
        { label = "Hunter",    value = OW.CLASS.HUNTER      },
        { label = "Mage",      value = OW.CLASS.MAGE        },
        { label = "Paladin",   value = OW.CLASS.PALADIN     },
        { label = "Priest",    value = OW.CLASS.PRIEST      },
        { label = "Rogue",     value = OW.CLASS.ROGUE       },
        { label = "Shaman",    value = OW.CLASS.SHAMAN      },
        { label = "Warlock",   value = OW.CLASS.WARLOCK     },
        { label = "Warrior",   value = OW.CLASS.WARRIOR     },
    }, function(val)
        filterClass = val
        filterSpec  = nil
        currentPage = 1
        if specFilterBtn then
            if val == nil then
                specFilterBtn.setChoices({ { label = "Any Spec", value = nil } }, "Any Spec")
                specFilterBtn.setActive(false)
            else
                local className = OW.CLASS_NAME[val]
                local specs     = OW.CLASS_SPECS and className and OW.CLASS_SPECS[className]
                local specChoices = { { label = "Any Spec", value = nil } }
                if specs then
                    for _, sp in ipairs(specs) do
                        specChoices[#specChoices + 1] = { label = sp.label, value = sp.id }
                    end
                end
                specFilterBtn.setChoices(specChoices, "Any Spec")
                specFilterBtn.setActive(true)
            end
        end
        TL.Refresh()
    end)
    classFilterBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 288, filterBarY)

    -- Spec filter — starts inactive; enabled when a class is selected above.
    specFilterBtn = makeDropdown(parent, 130, "Any Spec",
        { { label = "Any Spec", value = nil } },
        function(val)
            filterSpec = val ; currentPage = 1 ; TL.Refresh()
        end)
    specFilterBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 428, filterBarY)
    specFilterBtn.setActive(false)

    -- Reset Filters button — right-aligned in the filter bar, same visual style as dropdowns.
    local resetBtn = CreateFrame("Button", nil, parent)
    resetBtn:SetSize(90, 22)
    resetBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, filterBarY)

    local resetBg = resetBtn:CreateTexture(nil, "BACKGROUND")
    resetBg:SetAllPoints()
    resetBg:SetColorTexture(0.12, 0.12, 0.14, 1)
    thinBorder(resetBtn)

    local resetFs = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetFs:SetAllPoints()
    resetFs:SetJustifyH("CENTER")
    resetFs:SetTextColor(unpack(WHITE))
    resetFs:SetText("Reset Filters")

    resetBtn:SetScript("OnEnter", function() resetBg:SetColorTexture(0.18, 0.18, 0.22, 1) end)
    resetBtn:SetScript("OnLeave", function() resetBg:SetColorTexture(0.12, 0.12, 0.14, 1) end)
    resetBtn:SetScript("OnClick", function()
        filterStatus = nil
        filterLevel  = nil
        filterClass  = nil
        filterSpec   = nil
        currentPage  = 1
        if statusFilterBtn then statusFilterBtn._fs:SetText(statusFilterBtn._default) end
        if levelFilterBtn  then levelFilterBtn._fs:SetText(levelFilterBtn._default)   end
        if classFilterBtn  then classFilterBtn._fs:SetText(classFilterBtn._default)   end
        if specFilterBtn   then
            specFilterBtn.setChoices({ { label = "Any Spec", value = nil } }, "Any Spec")
            specFilterBtn.setActive(false)
        end
        TL.Refresh()
    end)

    -- ---- Column headers ----
    local function makeHeader(col, defaultLabel, px, pw)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", px, columnHeaderY)
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

    makeHeader("status", L.COL_STATUS or "S",                        COL_X.status, COL_W.status)
    headerBtns["status"]:GetFontString():SetJustifyH("CENTER")
    headerBtns["status"]:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.COL_STATUS_TIP or "Online / Offline status")
        GameTooltip:Show()
    end)
    headerBtns["status"]:SetScript("OnLeave", function() GameTooltip:Hide() end)

    makeHeader("name",  (L.COL_NAME  or "Character Name") .. " ^", COL_X.name,  COL_W.name)
    makeHeader("level", L.COL_LEVEL or "Level",                   COL_X.level, COL_W.level)
    makeHeader("class", "Class",                                   COL_X.class, COL_W.class)
    makeHeader("spec",  L.COL_SPEC  or "Spec",                    COL_X.spec,  COL_W.spec)
    makeHeader("time",  L.COL_TIME  or "Online At",               COL_X.time,  COL_W.time)

    -- Non-sortable "Actions" header (plain FontString, no click handler)
    local actionsHdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionsHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", COL_X.actions, columnHeaderY)
    actionsHdr:SetSize(COL_W.actions, 20)
    actionsHdr:SetJustifyH("CENTER")
    actionsHdr:SetText(L.COL_ACTIONS or "Actions")
    actionsHdr:SetTextColor(unpack(WHITE))

    local actionsLine = parent:CreateTexture(nil, "BACKGROUND")
    actionsLine:SetColorTexture(0.3, 0.3, 0.35, 1)
    actionsLine:SetPoint("BOTTOMLEFT",  actionsHdr, "BOTTOMLEFT",  0, 0)
    actionsLine:SetPoint("BOTTOMRIGHT", actionsHdr, "BOTTOMRIGHT", 0, 0)
    actionsLine:SetHeight(1)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.25, 0.25, 0.3, 1)
    divider:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, columnHeaderY - 20)
    divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, columnHeaderY - 20)
    divider:SetHeight(1)

    -- ---- Content frame (fixed size — rows sit flush against pagination) ----
    contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, columnHeaderY - 22)
    contentFrame:SetSize(CONTENT_W, PAGE_SIZE * ROW_HEIGHT)

    -- ---- Row pool (MAX_ROWS pre-created; only entries-count shown) ----
    for i = 1, MAX_ROWS do
        local rowFrame = CreateFrame("Frame", nil, contentFrame)
        rowFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        rowFrame:SetSize(CONTENT_W, ROW_HEIGHT)

        -- Row background: all rows get a base tint; even rows slightly brighter
        local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0.01)

        -- Character name (vertically centred)
        local nameFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.name + 6, 0)
        nameFs:SetWidth(COL_W.name - 6)
        nameFs:SetJustifyH("LEFT")
        nameFs:SetTextColor(unpack(WHITE))

        -- Level (vertically centred)
        local levelFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        levelFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.level, 0)
        levelFs:SetWidth(COL_W.level)
        levelFs:SetJustifyH("LEFT")
        levelFs:SetTextColor(unpack(WHITE))

        -- Class (vertically centred)
        local classFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        classFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.class, 0)
        classFs:SetWidth(COL_W.class)
        classFs:SetJustifyH("LEFT")
        classFs:SetTextColor(unpack(WHITE))

        -- Spec (vertically centred)
        local specFs = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        specFs:SetPoint("LEFT", rowFrame, "LEFT", COL_X.spec, 0)
        specFs:SetWidth(COL_W.spec)
        specFs:SetJustifyH("LEFT")
        specFs:SetTextColor(unpack(WHITE))

        -- Activity primary (top line of activity cell)
        local activityPrimary = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        activityPrimary:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", COL_X.activity, -4)
        activityPrimary:SetWidth(COL_W.activity - 4)
        activityPrimary:SetJustifyH("LEFT")
        activityPrimary:SetTextColor(unpack(WHITE))

        -- Activity exact (bottom line of activity cell, dimmer)
        local activityExact = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        activityExact:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", COL_X.activity, 4)
        activityExact:SetWidth(COL_W.activity - 4)
        activityExact:SetJustifyH("LEFT")
        activityExact:SetTextColor(unpack(DIM))

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

        -- Status dot (solid colored square texture, updated each refresh)
        local statusDot = rowFrame:CreateTexture(nil, "OVERLAY")
        statusDot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        statusDot:SetSize(10, 10)
        statusDot:SetPoint("CENTER", rowFrame, "LEFT", COL_X.status + COL_W.status / 2, 0)
        statusDot:SetVertexColor(0.5, 0.5, 0.5, 1)   -- grey (unknown) by default

        -- Transparent interactive region over the dot for tooltip support
        local dotRegion = CreateFrame("Frame", nil, rowFrame)
        dotRegion:SetPoint("CENTER", rowFrame, "LEFT", COL_X.status + COL_W.status / 2, 0)
        dotRegion:SetSize(COL_W.status, ROW_HEIGHT)
        dotRegion:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self._tip or "")
            GameTooltip:Show()
        end)
        dotRegion:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Invite button (Actions column)
        local inviteBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
        inviteBtn:SetSize(70, 20)
        inviteBtn:SetPoint("LEFT", rowFrame, "LEFT", COL_X.actions + (COL_W.actions - 70) / 2, 0)
        inviteBtn:SetText("Invite")
        inviteBtn:Hide()

        rowPool[i] = {
            frame         = rowFrame,
            statusDot     = statusDot,
            dotRegion     = dotRegion,
            name          = nameFs,
            level         = levelFs,
            class         = classFs,
            spec          = specFs,
            activityPrimary = activityPrimary,
            activityExact   = activityExact,
            timePrimary   = timePrimary,
            timeSecondary = timeSecondary,
            inviteBtn     = inviteBtn,
        }
        rowFrame:Hide()
    end

    -- ---- Pagination controls (bottom-center, fixed to frame bottom) ----
    local paginationBottomPad = 12   -- padding between buttons and frame bottom edge

    prevPageBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    prevPageBtn:SetSize(28, 22)
    prevPageBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOM", -60, paginationBottomPad)
    prevPageBtn:SetText("<")
    prevPageBtn:SetScript("OnClick", function()
        currentPage = currentPage - 1
        TL.Refresh()
    end)

    pageLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageLabel:SetPoint("BOTTOM", parent, "BOTTOM", 0, paginationBottomPad + 4)
    pageLabel:SetWidth(110)
    pageLabel:SetJustifyH("CENTER")
    pageLabel:SetText("Page 1 of 1")

    nextPageBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    nextPageBtn:SetSize(28, 22)
    nextPageBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOM", 60, paginationBottomPad)
    nextPageBtn:SetText(">")
    nextPageBtn:SetScript("OnClick", function()
        currentPage = currentPage + 1
        TL.Refresh()
    end)

    -- ---- Bottom buttons ----
    refreshBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    refreshBtn:SetSize(100, 26)
    refreshBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, paginationBottomPad)
    refreshBtn:SetText(L.BTN_REFRESH or "Refresh")
    refreshBtn:SetScript("OnClick", function()
        OW.PurgeExpiredPeers()
        if OW.Protocol then OW.Protocol.RequestPeers() end
        refreshBtn:SetText(L.BTN_REQUESTING or "Syncing...")
        C_Timer.After(3, function()
            if refreshBtn then refreshBtn:SetText(L.BTN_REFRESH or "Sync")  end
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
