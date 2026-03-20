-- Data/Timezones.lua — Timezone table and UTC conversion utilities.
-- Label format: "ABBR/DST_ABBR (City)". abbr field used for display in time strings.
-- DST is not automatic; users select their current offset from the dropdown.

local addonName, OW = ...
OW = OW or {}

OW.Timezones = {
    -- UTC
    { id = "UTC",              abbr = "UTC",   label = "UTC +00:00",              offset =    0 },
    -- Europe +0
    { id = "Europe/London",    abbr = "GMT",   label = "GMT/BST (London)",        offset =    0 },
    { id = "Europe/Lisbon",    abbr = "WET",   label = "WET/WEST (Lisbon)",       offset =    0 },
    -- Europe +1
    { id = "Europe/Berlin",    abbr = "CET",   label = "CET/CEST (Berlin)",       offset =   60 },
    { id = "Europe/Paris",     abbr = "CET",   label = "CET/CEST (Paris)",        offset =   60 },
    { id = "Europe/Madrid",    abbr = "CET",   label = "CET/CEST (Madrid)",       offset =   60 },
    { id = "Europe/Rome",      abbr = "CET",   label = "CET/CEST (Rome)",         offset =   60 },
    { id = "Europe/Warsaw",    abbr = "CET",   label = "CET/CEST (Warsaw)",       offset =   60 },
    { id = "Europe/Amsterdam", abbr = "CET",   label = "CET/CEST (Amsterdam)",    offset =   60 },
    { id = "Europe/Stockholm", abbr = "CET",   label = "CET/CEST (Stockholm)",    offset =   60 },
    -- Europe +2
    { id = "Europe/Athens",    abbr = "EET",   label = "EET/EEST (Athens)",       offset =  120 },
    { id = "Europe/Helsinki",  abbr = "EET",   label = "EET/EEST (Helsinki)",     offset =  120 },
    { id = "Europe/Bucharest", abbr = "EET",   label = "EET/EEST (Bucharest)",    offset =  120 },
    { id = "Europe/Kiev",      abbr = "EET",   label = "EET/EEST (Kyiv)",         offset =  120 },
    -- Europe +3
    { id = "Europe/Moscow",    abbr = "MSK",   label = "MSK (Moscow)",            offset =  180 },
    -- Asia
    { id = "Asia/Dubai",       abbr = "GST",   label = "GST (Dubai)",             offset =  240 },
    { id = "Asia/Kolkata",     abbr = "IST",   label = "IST (Kolkata)",           offset =  330 },
    { id = "Asia/Bangkok",     abbr = "ICT",   label = "ICT (Bangkok)",           offset =  420 },
    { id = "Asia/Shanghai",    abbr = "CST",   label = "CST (Shanghai)",          offset =  480 },
    { id = "Asia/Tokyo",       abbr = "JST",   label = "JST (Tokyo)",             offset =  540 },
    -- Oceania
    { id = "Australia/Sydney", abbr = "AEST",  label = "AEST/AEDT (Sydney)",      offset =  600 },
    -- Americas (west)
    { id = "US/Hawaii",        abbr = "HST",   label = "HST (Hawaii)",            offset = -600 },
    { id = "US/Alaska",        abbr = "AKST",  label = "AKST/AKDT (Alaska)",      offset = -540 },
    { id = "US/Pacific",       abbr = "PST",   label = "PST/PDT (US Pacific)",    offset = -480 },
    { id = "US/Mountain",      abbr = "MST",   label = "MST/MDT (US Mountain)",   offset = -420 },
    { id = "US/Central",       abbr = "CST",   label = "CST/CDT (US Central)",    offset = -360 },
    { id = "US/Eastern",       abbr = "EST",   label = "EST/EDT (US Eastern)",    offset = -300 },
    { id = "America/Sao_Paulo",abbr = "BRT",   label = "BRT (Sao Paulo)",         offset = -180 },
}

OW.DEFAULT_TIMEZONE = "Europe/Berlin"

-- O(1) lookup by id
local tzById = {}
for _, tz in ipairs(OW.Timezones) do
    tzById[tz.id] = tz
end

function OW.GetTimezoneById(id)
    return tzById[id] or tzById[OW.DEFAULT_TIMEZONE]
end

-- Convert a "local" unix timestamp (as-if-UTC from time()) to true UTC.
function OW.LocalToUTC(localTs, tzId)
    local tz = OW.GetTimezoneById(tzId)
    return localTs - (tz.offset * 60)
end

-- Convert a UTC unix timestamp to local for display.
function OW.UTCToLocal(utcTs, tzId)
    local tz = OW.GetTimezoneById(tzId)
    return utcTs + (tz.offset * 60)
end

-- Time-only: "19:30 CET"
function OW.FormatTimeOnly(utcTs, tzId)
    if not utcTs or utcTs == 0 then return "—" end
    local tz        = OW.GetTimezoneById(tzId)
    local displayTs = utcTs + (tz.offset * 60)
    return date("!%H:%M", displayTs) .. " " .. (tz.abbr or "UTC")
end

-- Parse "YYYY-MM-DD". Returns y, m, d or nil.
function OW.ParseDate(str)
    if not str then return nil end
    local y, m, d = str:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if not y then return nil end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if m < 1 or m > 12 or d < 1 or d > 31 then return nil end
    return y, m, d
end

-- Parse "HH:MM". Returns h, mi or nil.
function OW.ParseTime(str)
    if not str then return nil end
    local h, mi = str:match("^(%d%d):(%d%d)$")
    if not h then return nil end
    h, mi = tonumber(h), tonumber(mi)
    if h > 23 or mi > 59 then return nil end
    return h, mi
end

-- Build a UTC unix timestamp from dropdown-provided components and a timezone.
-- WoW's time({...}) treats the date table as machine-local time, not UTC.
-- We undo that bias so the entered values are interpreted as pure UTC first,
-- then subtract the user's selected timezone offset exactly once.
function OW.BuildUTCTimestamp(dateStr, timeStr, tzId)
    local y, mo, d = OW.ParseDate(dateStr)
    if not y then return nil, "Invalid date" end
    local h, mi = OW.ParseTime(timeStr)
    if not h then return nil, "Invalid time" end

    -- Compute machine's UTC offset: positive = machine is east of UTC (e.g. CET = +3600)
    local now     = time()
    local utcTbl  = date("!*t", now)
    local bias    = now - time({ year=utcTbl.year, month=utcTbl.month, day=utcTbl.day,
                                  hour=utcTbl.hour, min=utcTbl.min,   sec=utcTbl.sec })

    -- time({...}) bakes in machine-local offset; add bias back to get a pure-UTC value
    local machineLocalTs = time({ year = y, month = mo, day = d, hour = h, min = mi, sec = 0 })
    local asUTC          = machineLocalTs + bias

    -- Subtract user's timezone offset to convert their local time → UTC
    return OW.LocalToUTC(asUTC, tzId), nil
end
