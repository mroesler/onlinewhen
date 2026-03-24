-- UI/Window.lua — Main window, integrated tab header (top), dark ElvUI-style background

local addonName, OW = ...
OW.UI = {}
local UI = OW.UI

local WINDOW_W  = 800
local WINDOW_H  = 680
local TAB_COUNT = 2
local TAB_H     = 32   -- height of the integrated tab header strip
local INSET     = 6    -- interior inset from frame edge

-- Colors — dark ElvUI-Norm style
local C = {
    bg          = { 0.09, 0.09, 0.09, 0.97 },
    border      = { 0.3,  0.3,  0.35, 1    },
    tabActive   = { 0.13, 0.13, 0.15, 1    },
    tabInactive = { 0.06, 0.06, 0.07, 1    },
    tabLine     = { 0.2,  0.6,  1.0,  1    },  -- bright blue accent line
    tabSep      = { 0.25, 0.25, 0.3,  1    },  -- vertical divider between tabs
    divider     = { 0.22, 0.22, 0.27, 1    },  -- horizontal divider below tabs
    txtActive   = { 1.0,  1.0,  1.0,  1    },
    txtInactive = { 0.45, 0.45, 0.5,  1    },
}

local mainFrame  = nil
local tabFrames  = {}
local tabBtns    = {}
local currentTab = 1

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function solidTex(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a)
    return t
end

local function addBorders(frame, r, g, b, a)
    local top = solidTex(frame, "BORDER", r, g, b, a)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(1)

    local bot = solidTex(frame, "BORDER", r, g, b, a)
    bot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bot:SetHeight(1)

    local lft = solidTex(frame, "BORDER", r, g, b, a)
    lft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    lft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    lft:SetWidth(1)

    local rgt = solidTex(frame, "BORDER", r, g, b, a)
    rgt:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rgt:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    rgt:SetWidth(1)
end

-- ---------------------------------------------------------------------------
-- Tab visuals
-- ---------------------------------------------------------------------------

local function updateTabVisuals()
    for i = 1, TAB_COUNT do
        local tabBtn = tabBtns[i]
        if tabBtn then
            if i == currentTab then
                tabBtn.bg:SetColorTexture(unpack(C.tabActive))
                tabBtn.line:Show()
                tabBtn.label:SetTextColor(unpack(C.txtActive))
            else
                tabBtn.bg:SetColorTexture(unpack(C.tabInactive))
                tabBtn.line:Hide()
                tabBtn.label:SetTextColor(unpack(C.txtInactive))
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Window creation
-- ---------------------------------------------------------------------------

function UI.CreateMainWindow()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "OnlineWhenMainFrame", UIParent)
    mainFrame:SetSize(WINDOW_W, WINDOW_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UI.SaveWindowPosition()
    end)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetFrameLevel(10)
    mainFrame:Hide()

    -- Solid dark background
    local bg = solidTex(mainFrame, "BACKGROUND", unpack(C.bg))
    bg:SetAllPoints()

    -- 1-pixel border around the whole window
    addBorders(mainFrame, unpack(C.border))

    -- ---- Integrated tab header strip ----
    local tabWidth = math.floor((WINDOW_W - INSET * 2) / 2)
    local tabLabels = { OW.L.TAB_SCHEDULE or "Schedule", OW.L.TAB_PLAYERS or "Player List" }

    for i = 1, TAB_COUNT do
        local btn = CreateFrame("Button", "OWTab" .. i, mainFrame)
        btn:SetSize(tabWidth, TAB_H)
        btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", INSET + (i - 1) * tabWidth, -INSET)

        -- Tab background
        local bgTex = solidTex(btn, "BACKGROUND", unpack(C.tabInactive))
        bgTex:SetAllPoints()
        btn.bg = bgTex

        -- Bottom accent line (shown only on active tab)
        local line = solidTex(btn, "ARTWORK", unpack(C.tabLine))
        line:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        line:SetHeight(2)
        line:Hide()
        btn.line = line

        -- Label
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetAllPoints()
        lbl:SetText(tabLabels[i])
        btn.label = lbl

        -- Border around each tab button
        addBorders(btn, unpack(C.border))

        btn:SetScript("OnClick", function() UI.ShowTab(i) end)
        tabBtns[i] = btn
    end

    -- Vertical divider between tabs
    local tabVerticalDivider = solidTex(mainFrame, "ARTWORK", unpack(C.tabSep))
    tabVerticalDivider:SetWidth(1)
    tabVerticalDivider:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT", INSET + tabWidth, -INSET)
    tabVerticalDivider:SetHeight(TAB_H)

    -- Horizontal divider below tab strip
    local tabHorizontalDivider = solidTex(mainFrame, "ARTWORK", unpack(C.divider))
    tabHorizontalDivider:SetHeight(1)
    tabHorizontalDivider:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  INSET, -(INSET + TAB_H))
    tabHorizontalDivider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -INSET, -(INSET + TAB_H))

    -- Close button (top-right, above tab strip)
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    -- ---- Content frames (one per tab) ----
    local contentTopY = -(INSET + TAB_H + 4)
    for i = 1, TAB_COUNT do
        local tabContentFrame = CreateFrame("Frame", nil, mainFrame)
        tabContentFrame:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     INSET,  contentTopY)
        tabContentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -INSET, INSET)
        tabContentFrame:Hide()
        tabFrames[i] = tabContentFrame
    end

    if OW.TabSchedule then OW.TabSchedule.Build(tabFrames[1]) end
    if OW.TabPlayers  then OW.TabPlayers.Build(tabFrames[2])  end

    UI.RestoreWindowPosition()
    UI.ShowTab(1)
end

-- ---------------------------------------------------------------------------
-- Tab management
-- ---------------------------------------------------------------------------

function UI.ShowTab(n)
    currentTab = n
    for i = 1, TAB_COUNT do
        tabFrames[i]:Hide()
    end
    tabFrames[n]:Show()
    updateTabVisuals()

    if n == 1 and OW.TabSchedule then
        OW.TabSchedule.Populate()
    end
    if n == 2 and OW.TabPlayers then
        OW.TabPlayers.Refresh()
    end
end

function UI.GetCurrentTab()
    return currentTab
end

function UI.Toggle()
    if not mainFrame then return end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        if currentTab == 2 and OW.TabPlayers then
            OW.TabPlayers.Refresh()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Position persistence
-- ---------------------------------------------------------------------------

function UI.SaveWindowPosition()
    if not mainFrame then return end
    local point, _, relPoint, x, y = mainFrame:GetPoint()
    if point then
        OnlineWhenDB.settings.windowPos = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function UI.RestoreWindowPosition()
    if not mainFrame then return end
    local pos = OnlineWhenDB and OnlineWhenDB.settings and OnlineWhenDB.settings.windowPos
    if pos then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end
end
