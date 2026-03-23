-- UI/TabSchedule.lua — Schedule tab with two visual groups and clean alignment

local addonName, OW = ...
OW.TabSchedule = {}
local TI = OW.TabSchedule

-- Form state
local selectedRole = nil
local selectedTzId = OW.DEFAULT_TIMEZONE or "Europe/Berlin"

-- Widget references
local nameBox  = nil
local levelBox = nil
local saveBtn  = nil
local ddRole, ddDay, ddMonth, ddYear, ddHour, ddMin, ddTz

local MONTH_NAMES = {
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
}

-- Returns the number of days in a given month, accounting for leap years.
local function daysInMonth(mo, yr)
    if not mo then return 31 end
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if mo == 2 then
        local leap = yr and ((yr % 4 == 0 and yr % 100 ~= 0) or (yr % 400 == 0))
        return leap and 29 or 28
    end
    return days[mo] or 31
end

-- Rebuilds the Day dropdown items to match the currently selected month/year.
-- Called whenever month or year changes. ddDay/ddMonth/ddYear are upvalues.
local function updateDayItems()
    if not ddDay or not ddMonth or not ddYear then return end
    local mo   = ddMonth:GetValue()
    local yr   = ddYear:GetValue()
    if not mo or not yr then return end
    local maxD = daysInMonth(mo, yr)
    local t    = {}
    for d = 1, maxD do
        t[#t+1] = { value = d, label = string.format("%02d", d) }
    end
    ddDay:SetItems(t)
end

-- Layout constants
local INNER_PAD = 12   -- padding from group-box edges to content
local TITLE_Y   = -6   -- title label y inside box
local CONTENT_Y = -28  -- first content element y inside box (below title)

-- Colors
local WHITE    = { 1.0,  1.0,  1.0,  1.0 }
local DIM      = { 0.35, 0.35, 0.4,  1.0 }
local ACCENT   = { 0.2,  0.6,  1.0,  1.0 }
local GRP_BG   = { 0.12, 0.12, 0.15, 1.0 }
local GRP_EDGE = { 0.25, 0.25, 0.3,  1.0 }

-- ---------------------------------------------------------------------------
-- Group box visual container
-- Returns the box frame. Children should be parented to it.
-- ---------------------------------------------------------------------------

local function makeGroupBox(parent, title, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetSize(w, h)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(GRP_BG))

    -- Accent top bar (2px)
    local topBar = box:CreateTexture(nil, "BORDER")
    topBar:SetColorTexture(unpack(ACCENT))
    topBar:SetPoint("TOPLEFT",  box, "TOPLEFT",  0, 0)
    topBar:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, 0)
    topBar:SetHeight(2)

    -- Left / right / bottom borders (1px)
    for _, cfg in ipairs({
        { "TOPLEFT", "BOTTOMLEFT", true },
        { "TOPRIGHT","BOTTOMRIGHT",true },
        { "BOTTOMLEFT","BOTTOMRIGHT",false },
    }) do
        local t = box:CreateTexture(nil, "BORDER")
        t:SetColorTexture(unpack(GRP_EDGE))
        t:SetPoint(cfg[1], box, cfg[1], 0, 0)
        t:SetPoint(cfg[2], box, cfg[2], 0, 0)
        if cfg[3] then t:SetWidth(1) else t:SetHeight(1) end
    end

    local titleFs = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleFs:SetPoint("TOPLEFT", box, "TOPLEFT", INNER_PAD, TITLE_Y)
    titleFs:SetText(title)
    titleFs:SetTextColor(unpack(ACCENT))

    return box
end

-- ---------------------------------------------------------------------------
-- Dropdown factory — notCheckable=true for equal indentation on all items.
-- Passing defaultValue=nil shows placeholder text with no item pre-selected.
-- Frame anchor: (x - 16, y) so the visible button's left edge is at x.
-- This aligns with labels placed at the same x.
-- ---------------------------------------------------------------------------

local function makeDropdown(parent, uniqueName, items, defaultValue, x, y, menuWidth, onChange, placeholder)
    local dd = CreateFrame("Frame", uniqueName, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y)
    UIDropDownMenu_SetWidth(dd, menuWidth)

    local currentValue = defaultValue
    local activeItems  = items   -- mutable so SetItems can replace it

    local function initMenu()
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, item in ipairs(activeItems) do
                local info        = UIDropDownMenu_CreateInfo()
                info.text         = item.label
                info.value        = item.value
                info.notCheckable = true
                info.func = (function(v, lbl)
                    return function()
                        currentValue = v
                        UIDropDownMenu_SetText(dd, lbl)
                        CloseDropDownMenus()
                        if onChange then onChange(v) end
                    end
                end)(item.value, item.label)
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    initMenu()

    local initText = placeholder or ""
    if defaultValue ~= nil then
        for _, item in ipairs(activeItems) do
            if item.value == defaultValue then initText = item.label; break end
        end
    end
    UIDropDownMenu_SetText(dd, initText)

    function dd:GetValue()  return currentValue end
    function dd:SetValue(v)
        currentValue = v
        for _, item in ipairs(activeItems) do
            if item.value == v then UIDropDownMenu_SetText(dd, item.label); return end
        end
    end
    function dd:ClearValue()
        currentValue = nil
        UIDropDownMenu_SetText(dd, placeholder or "")
    end
    -- Replace items list; clamps currentValue to the new maximum if out of range.
    function dd:SetItems(newItems)
        activeItems = newItems
        initMenu()
        local found = false
        for _, item in ipairs(activeItems) do
            if item.value == currentValue then found = true; break end
        end
        if not found and #activeItems > 0 then
            local last = activeItems[#activeItems]
            currentValue = last.value
            UIDropDownMenu_SetText(dd, last.label)
        end
    end
    return dd
end

-- ---------------------------------------------------------------------------
-- Item builders
-- ---------------------------------------------------------------------------

local function roleItems()
    return {
        { value = "Tank", label = "Tank" },
        { value = "Heal", label = "Heal" },
        { value = "DPS",  label = "DPS"  },
    }
end

local function monthItems()
    local t = {}
    for m = 1, 12 do t[#t+1] = { value = m, label = MONTH_NAMES[m] } end
    return t
end

local function yearItems()
    local cur = tonumber(date("!%Y", time()))
    local t = {}
    for y = cur, cur + 10 do t[#t+1] = { value = y, label = tostring(y) } end
    return t
end

local function hourItems()
    local t = {}
    for h = 0, 23 do t[#t+1] = { value = h, label = string.format("%02d", h) } end
    return t
end

local function minuteItems()
    local t = {}
    for m = 0, 55, 5 do t[#t+1] = { value = m, label = string.format("%02d", m) } end
    return t
end

local function tzItems()
    local t = {}
    for _, tz in ipairs(OW.Timezones) do
        t[#t+1] = { value = tz.id, label = tz.label }
    end
    return t
end

-- ---------------------------------------------------------------------------
-- Save & reset
-- ---------------------------------------------------------------------------

local function showError(msg)
    if not saveBtn then return end
    saveBtn:SetText("|cFFFF5555" .. msg .. "|r")
    C_Timer.After(2.5, function() if saveBtn then saveBtn:SetText(OW.L.BTN_SAVE or "Save") end end)
end

local function onSave()
    local name = UnitName("player") or ""
    if name == "" then showError(OW.L.ERR_NO_NAME or "Enter a name.") return end

    selectedRole = ddRole and ddRole:GetValue()
    if not selectedRole then showError(OW.L.ERR_NO_ROLE or "Select a role.") return end

    local d  = ddDay   and ddDay:GetValue()
    local mo = ddMonth and ddMonth:GetValue()
    local y  = ddYear  and ddYear:GetValue()
    local h  = ddHour  and ddHour:GetValue()
    local mi = ddMin   and ddMin:GetValue()
    if not (d and mo and y and h and mi) then showError("Pick a date and time.") return end

    local utcTs, err = OW.BuildUTCTimestamp(
        string.format("%04d-%02d-%02d", y, mo, d),
        string.format("%02d:%02d", h, mi),
        selectedTzId)
    if not utcTs then showError(err or "Invalid date/time.") return end

    local level = UnitLevel("player") or 1
    OnlineWhen.SaveMyEntry(name, selectedRole, level, utcTs, selectedTzId)

    saveBtn:SetText(OW.L.BTN_SAVED or "Saved!")
    C_Timer.After(1.5, function()
        if saveBtn then saveBtn:SetText(OW.L.BTN_SAVE or "Save") end
        TI.Reset()
        if OW.UI then OW.UI.ShowTab(2) end
    end)
end

function TI.Reset()
    local charName  = UnitName("player") or ""
    local charLevel = tostring(UnitLevel("player") or "")
    if nameBox  then nameBox:SetText(charName)   end
    if levelBox then levelBox:SetText(charLevel) end
    if ddRole   then ddRole:ClearValue() end
    selectedRole = nil

    local serverTs  = (GetServerTime and GetServerTime()) or time()
    local today     = tonumber(date("!%d", serverTs))
    local thisMonth = tonumber(date("!%m", serverTs))
    local thisYear  = tonumber(date("!%Y", serverTs))
    if ddMonth then ddMonth:SetValue(thisMonth) end
    if ddYear  then ddYear:SetValue(thisYear)   end
    updateDayItems()
    if ddDay   then ddDay:SetValue(today)       end

    local rH, rM = GetGameTime()
    rM = math.ceil(rM / 5) * 5
    if rM >= 60 then rM = 0; rH = (rH + 1) % 24 end
    if ddHour then ddHour:SetValue(rH) end
    if ddMin  then ddMin:SetValue(rM)  end

    selectedTzId = OW.DEFAULT_TIMEZONE or "Europe/Berlin"
    if ddTz then ddTz:SetValue(selectedTzId) end
end

-- ---------------------------------------------------------------------------
-- Layout helpers
-- ---------------------------------------------------------------------------

local function lbl(box, text, x, y)
    local fs = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", box, "TOPLEFT", x, y)
    fs:SetText(text)
    fs:SetTextColor(unpack(WHITE))
    return fs
end

-- Creates a dimmed, non-interactive display field (background + border + FontString).
-- Returns the FontString so the caller can call :SetText().
local function makeReadonlyField(parent, x, y, w)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.04, 0.04, 0.06, 1)
    bg:SetPoint("TOPLEFT",     parent, "TOPLEFT", x,   y)
    bg:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x+w, y-24)

    local border = parent:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0.2, 0.2, 0.22, 1)
    border:SetPoint("TOPLEFT",     parent, "TOPLEFT", x,   y)
    border:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x+w, y-24)

    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", bg, "LEFT", 6, 0)
    fs:SetWidth(w - 12)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(0.55, 0.55, 0.6, 1)
    return fs
end

-- ---------------------------------------------------------------------------
-- Build
--
-- Alignment rule:
--   Labels and inputs share the same left-edge x = INNER_PAD inside each group box.
--   Readonly field: SetPoint x = INNER_PAD  (direct pixel alignment)
--   Dropdown: frame SetPoint x = INNER_PAD - 16  (UIDropDownMenu internal offset)
--             so the visual button left edge appears at INNER_PAD.
--
-- Vertical rhythm inside a group (y values relative to group box TOPLEFT):
--   Content starts at CONTENT_Y (-28), below the title.
--   After a label        (~14px): y -= 20  (label + 6px gap)
--   After a readonly field (24px): y -= 34 (24px + 10px gap)
--   After a dropdown      (~26px): y -= 36 (26px + 10px gap)
--   Bottom padding: INNER_PAD (12px)
--
-- Group boxes are children of 'parent' (the tab content frame).
-- Save button is a child of 'parent', centered horizontally, below Group 2.
-- ---------------------------------------------------------------------------

function TI.Build(parent)
    local L   = OW.L
    local px  = INNER_PAD   -- shared left x for labels and inputs inside each group

    -- Group box dimensions
    -- Group 1 (Character): title + name + role
    --   CONTENT_Y(-28) → name lbl → -48 → editbox(24) → -82 → role lbl → -102 → dd(26) → -128 → +INNER_PAD = 140
    local G1_H = 140

    -- Group 2 (Date & Time): title + date + time + timezone + note
    --   CONTENT_Y(-28) → date lbl → -48 → dd(26) → -84 → time lbl → -104 → dd(26) → -140
    --   → tz lbl → -160 → dd(26) → -196 → note(~12) → -218 → +INNER_PAD = 230
    local G2_H = 230

    -- Group box width = parent width minus 2×side margin (6px each side)
    local MARGIN = 6
    local GW     = 716   -- 728 content width − 2×6 margin

    -- Group 1 position in parent
    local G1_Y   = -MARGIN               -- 6px from content area top
    -- Group 2 position in parent
    local G2_Y   = G1_Y - G1_H - 8       -- 8px gap between groups

    -- ============================================================
    -- GROUP 1 — Character
    -- ============================================================
    local g1 = makeGroupBox(parent, "Character", MARGIN, G1_Y, GW, G1_H)

    local py = CONTENT_Y

    -- Name + Level labels on the same row
    lbl(g1, L.LABEL_NAME  or "Character Name", px,        py)
    lbl(g1, L.LABEL_LEVEL or "Level",          px + 210,  py)
    py = py - 20

    -- Name + Level: readonly display fields (pre-filled from current character)
    nameBox  = makeReadonlyField(g1, px,       py, 195)
    levelBox = makeReadonlyField(g1, px + 210, py, 50)
    nameBox:SetText(UnitName("player") or "")
    levelBox:SetText(tostring(UnitLevel("player") or ""))

    py = py - 34   -- 24px editbox + 10px section gap
    lbl(g1, L.LABEL_ROLE or "Role", px, py)
    py = py - 20
    ddRole = makeDropdown(g1, "OWDdRole", roleItems(), nil, px, py, 100,
        function(v) selectedRole = v end, "— Select —")

    -- ============================================================
    -- GROUP 2 — Date & Time
    -- ============================================================
    local g2 = makeGroupBox(parent, "Date & Time", MARGIN, G2_Y, GW, G2_H)

    py = CONTENT_Y

    -- Date row: Month | Day | Year — all left-aligned at px
    -- Horizontal offsets (frame anchor = visual x - 16 due to UIDropDownMenu padding):
    --   Month visual at px        → frame at px - 16
    --   Day   visual at px + 130  → frame at px + 114
    --   Year  visual at px + 195  → frame at px + 179
    lbl(g2, L.LABEL_DATE or "Date", px, py)
    py = py - 20

    -- Use server timestamp for date; GetGameTime() for realm H:M (matches the in-game clock).
    local serverTs  = (GetServerTime and GetServerTime()) or time()
    local today     = tonumber(date("!%d", serverTs))
    local thisMonth = tonumber(date("!%m", serverTs))
    local thisYear  = tonumber(date("!%Y", serverTs))

    -- Order: Month | Day | Year
    -- Month onChange rebuilds Day items; Year onChange does the same (Feb leap-year check).
    local initDayItems = {}
    for d = 1, daysInMonth(thisMonth, thisYear) do
        initDayItems[#initDayItems+1] = { value = d, label = string.format("%02d", d) }
    end

    ddMonth = makeDropdown(g2, "OWDdMonth", monthItems(),   thisMonth, px,        py, 110, function() updateDayItems() end)
    ddDay   = makeDropdown(g2, "OWDdDay",   initDayItems,   today,     px + 130,  py, 42,  nil)
    ddYear  = makeDropdown(g2, "OWDdYear",  yearItems(),    thisYear,  px + 195,  py, 68,  function() updateDayItems() end)

    -- Time row: Hour | Minute — aligned at px, same rhythm
    py = py - 36
    lbl(g2, L.LABEL_TIME or "Time", px, py)
    py = py - 20

    -- Default to current realm time rounded up to nearest 5-minute mark.
    local defH, defM = GetGameTime()
    defM = math.ceil(defM / 5) * 5
    if defM >= 60 then defM = 0; defH = (defH + 1) % 24 end

    ddHour = makeDropdown(g2, "OWDdHour", hourItems(),   defH, px,      py, 42, nil)
    ddMin  = makeDropdown(g2, "OWDdMin",  minuteItems(), defM, px + 74, py, 42, nil)

    -- Timezone
    py = py - 36
    lbl(g2, L.LABEL_TIMEZONE or "Timezone", px, py)
    py = py - 20

    ddTz = makeDropdown(g2, "OWDdTz", tzItems(), selectedTzId, px, py, 320, function(v)
        selectedTzId = v
    end)

    -- Helper note (below timezone dropdown, inside group)
    py = py - 36
    local note = g2:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", g2, "TOPLEFT", px, py)
    note:SetText(L.TZ_NOTE or "Pick the time in your timezone — it will be converted to Server Time automatically.")
    note:SetTextColor(unpack(DIM))

    -- ============================================================
    -- SAVE BUTTON — child of parent, centered, below Group 2
    -- Vertical: equal spacing between Group 2 bottom and content area bottom.
    --   Group 2 bottom in parent coords: G2_Y - G2_H
    --   Content area bottom: approximately -432 (480 window - 32 tab - 6 top - 6 bottom - 4 gap)
    --   Available: 432 - (|G2_Y| + G2_H)
    -- Use TOP anchor at content-center-x for horizontal centering.
    -- ============================================================
    local G2_bottom   = math.abs(G2_Y) + G2_H     -- distance from parent top to G2 bottom
    local CONTENT_H   = 472                         -- estimated content area height (520 window − 32 tab − 10 insets − 6 gap)
    local btnH        = 28
    local spaceBelow  = CONTENT_H - G2_bottom
    local btnTopY     = -(G2_bottom + (spaceBelow - btnH) / 2)

    saveBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    saveBtn:SetSize(140, btnH)
    -- TOP anchor at parent center → horizontally centered
    saveBtn:SetPoint("TOP", parent, "TOP", 0, btnTopY)
    saveBtn:SetText(L.BTN_SAVE or "Save")
    saveBtn:SetScript("OnClick", onSave)
end

-- Repopulate when re-opened with an existing saved entry
function TI.Populate()
    local my = OnlineWhen.GetMyEntry()
    if not my then return end
    if ddRole and my.role then ddRole:SetValue(my.role); selectedRole = my.role end
    if my.timezone then
        selectedTzId = my.timezone
        if ddTz then ddTz:SetValue(my.timezone) end
    end
    if my.onlineAt and my.onlineAt > 0 then
        local localTs = OW.UTCToLocal(my.onlineAt, selectedTzId)
        if ddDay   then ddDay:SetValue(tonumber(date("!%d", localTs)))  end
        if ddMonth then ddMonth:SetValue(tonumber(date("!%m", localTs))) end
        if ddYear  then ddYear:SetValue(tonumber(date("!%Y", localTs)))  end
        if ddHour  then ddHour:SetValue(tonumber(date("!%H", localTs)))  end
        if ddMin   then ddMin:SetValue(math.floor(tonumber(date("!%M", localTs)) / 5) * 5) end
    end
end
