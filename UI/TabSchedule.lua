-- UI/TabSchedule.lua — Schedule tab with two visual groups and clean alignment

local addonName, OW = ...
OW.TabSchedule = {}
local TI = OW.TabSchedule

-- Form state
local selectedSpec = nil
local selectedTzId = OW.DEFAULT_TIMEZONE or "Europe/Berlin"

-- Widget references
local nameBox  = nil
local levelBox = nil
local saveBtn  = nil
local ddSpec, ddDay, ddMonth, ddYear, ddHour, ddMin, ddTz

local MONTH_NAMES = {
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
}

-- Returns the number of days in a given month, accounting for leap years.
local function daysInMonth(month, year)
    if not month then return 31 end
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 then
        local leap = year and ((year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0))
        return leap and 29 or 28
    end
    return days[month] or 31
end

-- Rebuilds the Day dropdown items to match the currently selected month/year.
-- Called whenever month or year changes. ddDay/ddMonth/ddYear are upvalues.
local function updateDayItems()
    if not ddDay or not ddMonth or not ddYear then return end
    local month = ddMonth:GetValue()
    local year  = ddYear:GetValue()
    if not month or not year then return end
    local maxDay = daysInMonth(month, year)
    local items  = {}
    for day = 1, maxDay do
        items[#items+1] = { value = day, label = string.format("%02d", day) }
    end
    ddDay:SetItems(items)
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

-- Returns dropdown items for the specs available to the given class name.
local function specItemsForClass(className)
    local specs = OW.CLASS_SPECS and className and OW.CLASS_SPECS[className]
    if not specs then return {} end
    local items = {}
    for _, spec in ipairs(specs) do
        items[#items+1] = { value = spec.label, label = spec.label }
    end
    return items
end

local function monthItems()
    local items = {}
    for m = 1, 12 do items[#items+1] = { value = m, label = MONTH_NAMES[m] } end
    return items
end

local function yearItems()
    local currentYear = tonumber(date("!%Y", time()))
    local items = {}
    for y = currentYear, currentYear + 10 do items[#items+1] = { value = y, label = tostring(y) } end
    return items
end

local function hourItems()
    local items = {}
    for hour = 0, 23 do items[#items+1] = { value = hour, label = string.format("%02d", hour) } end
    return items
end

local function minuteItems()
    local items = {}
    for minute = 0, 55, 5 do items[#items+1] = { value = minute, label = string.format("%02d", minute) } end
    return items
end

local function tzItems()
    local items = {}
    for _, tz in ipairs(OW.Timezones) do
        items[#items+1] = { value = tz.id, label = tz.label }
    end
    return items
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

    selectedSpec = ddSpec and ddSpec:GetValue()
    if not selectedSpec then showError(OW.L.ERR_NO_SPEC or "Select a spec.") return end

    local day    = ddDay   and ddDay:GetValue()
    local month  = ddMonth and ddMonth:GetValue()
    local year   = ddYear  and ddYear:GetValue()
    local hour   = ddHour  and ddHour:GetValue()
    local minute = ddMin   and ddMin:GetValue()
    if not (day and month and year and hour and minute) then showError("Pick a date and time.") return end

    local utcTs, err = OW.BuildUTCTimestamp(
        string.format("%04d-%02d-%02d", year, month, day),
        string.format("%02d:%02d", hour, minute),
        selectedTzId)
    if not utcTs then showError(err or "Invalid date/time.") return end

    local level = UnitLevel("player") or 1
    local _, cToken = UnitClass("player")
    local myClass   = (cToken and OW.CLASS_TOKEN_NAME and OW.CLASS_TOKEN_NAME[cToken]) or ""
    OnlineWhen.SaveMyEntry(name, selectedSpec, myClass, level, utcTs, selectedTzId)

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
    if ddSpec   then ddSpec:ClearValue() end
    selectedSpec = nil

    local serverTimestamp = (GetServerTime and GetServerTime()) or time()
    local today           = tonumber(date("!%d", serverTimestamp))
    local thisMonth       = tonumber(date("!%m", serverTimestamp))
    local thisYear        = tonumber(date("!%Y", serverTimestamp))
    if ddMonth then ddMonth:SetValue(thisMonth) end
    if ddYear  then ddYear:SetValue(thisYear)   end
    updateDayItems()
    if ddDay   then ddDay:SetValue(today)       end

    local realmHour, realmMinute = GetGameTime()
    realmMinute = math.ceil(realmMinute / 5) * 5
    if realmMinute >= 60 then realmMinute = 0; realmHour = (realmHour + 1) % 24 end
    if ddHour then ddHour:SetValue(realmHour)   end
    if ddMin  then ddMin:SetValue(realmMinute)  end

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
    local L            = OW.L
    local contentLeft  = INNER_PAD   -- shared left x for labels and inputs inside each group

    -- Group box dimensions
    -- Group 1 (Character): title + single label row + single field row (all four fields inline)
    --   CONTENT_Y(-28) → labels(20) → fields(26) → INNER_PAD(16) → charGroupHeight = 90
    local charGroupHeight = 90

    -- Save button metrics — needed to size Group 2
    local saveButtonHeight  = 28
    local saveButtonPadding = 14   -- equal gap: G2-bottom→button-top and button-bottom→frame-bottom

    -- contentAreaHeight = tab frame height: 680 window − 32 tab − 6 top inset − 6 bottom inset − 4 gap = 632
    local contentAreaHeight = 632

    -- Group 2 fills remaining space so saveButtonPadding is equal on both sides of the button
    --   dateTimeGroupTopAbs = groupMargin + charGroupHeight + 8 = 6 + 90 + 8 = 104
    --   Bottom space with Activity group: activityGroupHeight(152) + gap(8) + saveButtonPadding(14) + saveButtonHeight(28) + saveButtonPadding(14) = 216
    --   dateTimeGroupHeight = contentAreaHeight − dateTimeGroupTopAbs − bottomSpace = 632 − 104 − 216 = 312
    local dateTimeGroupHeight = 312

    -- Group box width = parent width minus 2×side margin (6px each side)
    local groupMargin = 6
    local groupWidth  = 776   -- 788 content width − 2×6 margin

    -- Group 1 position in parent
    local charGroupY     = -groupMargin               -- 6px from content area top
    -- Group 2 position in parent
    local dateTimeGroupY = charGroupY - charGroupHeight - 8   -- 8px gap between groups

    -- ============================================================
    -- GROUP 1 — Character
    -- ============================================================
    local charGroup = makeGroupBox(parent, "Character", groupMargin, charGroupY, groupWidth, charGroupHeight)

    local curY = CONTENT_Y

    -- Labels: Name | Level | Class | Spec — all on one row
    lbl(charGroup, L.LABEL_NAME  or "Character Name", contentLeft,        curY)
    lbl(charGroup, L.LABEL_LEVEL or "Level",          contentLeft + 210,  curY)
    lbl(charGroup, "Class",                           contentLeft + 280,  curY)
    lbl(charGroup, L.LABEL_SPEC  or "Spec",           contentLeft + 430,  curY)
    curY = curY - 20

    -- Fields: Name (readonly) | Level (readonly) | Class (readonly) | Spec (dropdown)
    nameBox  = makeReadonlyField(charGroup, contentLeft,       curY, 195)
    levelBox = makeReadonlyField(charGroup, contentLeft + 210, curY, 50)
    nameBox:SetText(UnitName("player") or "")
    levelBox:SetText(tostring(UnitLevel("player") or ""))

    local _, classToken = UnitClass("player")
    local className     = classToken and OW.CLASS_TOKEN_NAME and OW.CLASS_TOKEN_NAME[classToken]
    local classColor    = className and OW.CLASS_COLOR and OW.CLASS_COLOR[className]
    local classFs       = makeReadonlyField(charGroup, contentLeft + 280, curY, 130)
    classFs:SetText(className or "")
    if classColor then
        nameBox:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
        classFs:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
    end

    ddSpec = makeDropdown(charGroup, "OWDdSpec", specItemsForClass(className), nil, contentLeft + 430, curY, 130,
        function(v) selectedSpec = v end, "— Select —")

    -- ============================================================
    -- GROUP 2 — Date & Time
    -- ============================================================
    local dateTimeGroup = makeGroupBox(parent, "Date & Time", groupMargin, dateTimeGroupY, groupWidth, dateTimeGroupHeight)

    curY = CONTENT_Y

    -- Date row: Month | Day | Year — all left-aligned at contentLeft
    -- Horizontal offsets (frame anchor = visual x - 16 due to UIDropDownMenu padding):
    --   Month visual at contentLeft        → frame at contentLeft - 16
    --   Day   visual at contentLeft + 130  → frame at contentLeft + 114
    --   Year  visual at contentLeft + 195  → frame at contentLeft + 179
    lbl(dateTimeGroup, L.LABEL_DATE or "Date", contentLeft, curY)
    curY = curY - 20

    -- Use server timestamp for date; GetGameTime() for realm H:M (matches the in-game clock).
    local serverTimestamp = (GetServerTime and GetServerTime()) or time()
    local today           = tonumber(date("!%d", serverTimestamp))
    local thisMonth       = tonumber(date("!%m", serverTimestamp))
    local thisYear        = tonumber(date("!%Y", serverTimestamp))

    -- Order: Month | Day | Year
    -- Month onChange rebuilds Day items; Year onChange does the same (Feb leap-year check).
    local initDayItems = {}
    for day = 1, daysInMonth(thisMonth, thisYear) do
        initDayItems[#initDayItems+1] = { value = day, label = string.format("%02d", day) }
    end

    ddMonth = makeDropdown(dateTimeGroup, "OWDdMonth", monthItems(),   thisMonth, contentLeft,        curY, 110, function() updateDayItems() end)
    ddDay   = makeDropdown(dateTimeGroup, "OWDdDay",   initDayItems,   today,     contentLeft + 130,  curY, 42,  nil)
    ddYear  = makeDropdown(dateTimeGroup, "OWDdYear",  yearItems(),    thisYear,  contentLeft + 195,  curY, 68,  function() updateDayItems() end)

    -- Time row: Hour | Minute — equal spacing below date section
    curY = curY - 62
    lbl(dateTimeGroup, L.LABEL_TIME or "Time", contentLeft, curY)
    curY = curY - 20

    -- Default to current realm time rounded up to nearest 5-minute mark.
    local defaultHour, defaultMinute = GetGameTime()
    defaultMinute = math.ceil(defaultMinute / 5) * 5
    if defaultMinute >= 60 then defaultMinute = 0; defaultHour = (defaultHour + 1) % 24 end

    ddHour = makeDropdown(dateTimeGroup, "OWDdHour", hourItems(),   defaultHour,   contentLeft,      curY, 42, nil)
    ddMin  = makeDropdown(dateTimeGroup, "OWDdMin",  minuteItems(), defaultMinute, contentLeft + 74, curY, 42, nil)

    -- Timezone — equal spacing below time section
    curY = curY - 62
    lbl(dateTimeGroup, L.LABEL_TIMEZONE or "Timezone", contentLeft, curY)
    curY = curY - 20

    ddTz = makeDropdown(dateTimeGroup, "OWDdTz", tzItems(), selectedTzId, contentLeft, curY, 320, function(v)
        selectedTzId = v
    end)

    -- Helper note (below timezone dropdown, inside group)
    curY = curY - 62
    local note = dateTimeGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", dateTimeGroup, "TOPLEFT", contentLeft, curY)
    note:SetText(L.TZ_NOTE or "Pick the time in your timezone — it will be converted to Server Time automatically.")
    note:SetTextColor(unpack(DIM))

    -- ============================================================
    -- SAVE BUTTON — centered horizontally, equal spacing to Group 2 bottom and frame bottom.
    --   saveButtonPadding (14px) is identical above and below the button.
    --   Anchored at BOTTOM so it moves naturally if window height changes.
    -- ============================================================
    saveBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    saveBtn:SetSize(140, saveButtonHeight)
    saveBtn:SetPoint("BOTTOM", parent, "BOTTOM", 0, saveButtonPadding)
    saveBtn:SetText(L.BTN_SAVE or "Save")
    saveBtn:SetScript("OnClick", onSave)
end

-- Repopulate when re-opened with an existing saved entry
function TI.Populate()
    local my = OnlineWhen.GetMyEntry()
    if not my then return end
    if ddSpec and my.spec then ddSpec:SetValue(my.spec); selectedSpec = my.spec end
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
