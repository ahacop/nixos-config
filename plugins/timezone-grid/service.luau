--!nonstrict
-- Timezone Grid service — owns the device timezone and the ordered list of
-- comparison cities, and republishes one computed row per city every
-- second. The panel reads that state and does layout only, so the clock
-- keeps running while the panel is closed.
--
-- Persistence: pluginDataDir()/data.json -> { cities = { { tz, label }, ... } }
--
-- State:
--   timezone_grid.device_tz        -> string, the IANA name from timedatectl
--   timezone_grid.cities           -> ordered { { tz, label }, ... }
--   timezone_grid.rows             -> { { key, label, tz, isDevice, timeText,
--                                        dateText, abbrev, deltaText,
--                                        offsetMinutes }, ... }
--   timezone_grid.all_zones        -> { "Area/City", ... }, loaded on demand
--   timezone_grid.all_zones_loaded -> bool
--
-- Commands (timezone_grid.cmd):
--   { op = "add", tz, label } | { op = "remove", tz }
--   { op = "reorder", tz, index } | { op = "load_zones" }

noctalia.setUpdateInterval(1000)

local MAX_CITIES = 6
local ZONES_LOAD_TIMEOUT_MS = 8000

-- Offered when `timedatectl list-timezones` is unavailable, so the picker is
-- never empty.
local FALLBACK_ZONES = {
  "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
  "America/Sao_Paulo", "America/Mexico_City", "America/Toronto", "America/Vancouver",
  "America/Bogota", "America/Lima", "America/Argentina/Buenos_Aires",
  "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Madrid", "Europe/Rome",
  "Europe/Amsterdam", "Europe/Zurich", "Europe/Stockholm", "Europe/Athens",
  "Europe/Istanbul", "Europe/Moscow", "Europe/Warsaw", "Europe/Dublin",
  "Africa/Cairo", "Africa/Johannesburg", "Africa/Lagos", "Africa/Nairobi",
  "Asia/Dubai", "Asia/Karachi", "Asia/Kolkata", "Asia/Dhaka", "Asia/Bangkok",
  "Asia/Jakarta", "Asia/Singapore", "Asia/Hong_Kong", "Asia/Shanghai",
  "Asia/Manila", "Asia/Seoul", "Asia/Tokyo",
  "Australia/Perth", "Australia/Brisbane", "Australia/Sydney", "Australia/Melbourne",
  "Pacific/Auckland", "Pacific/Honolulu", "UTC",
}

local deviceTz = ""
local cities = {}
local allZones = {}
local allZonesLoaded = false
local allZonesLoading = false
local allZonesLoadStartedMs = nil

-- ---------------------------------------------------------------------
-- Persistence
-- ---------------------------------------------------------------------
local function dataPath()
  local dir = noctalia.pluginDataDir()
  if dir == nil then
    return nil
  end
  return dir .. "/data.json"
end

local function saveData()
  local path = dataPath()
  if path == nil then
    return
  end
  local encoded = noctalia.json.encode({ cities = cities })
  if encoded ~= nil then
    noctalia.writeFile(path, encoded)
  end
end

local function loadData()
  cities = {}
  local path = dataPath()
  if path == nil then
    return
  end
  local raw = noctalia.readFile(path)
  if raw == nil then
    return
  end
  local decoded = noctalia.json.decode(raw)
  if type(decoded) ~= "table" or type(decoded.cities) ~= "table" then
    return
  end
  for _, entry in ipairs(decoded.cities) do
    if type(entry) == "table" and type(entry.tz) == "string" and entry.tz ~= "" then
      table.insert(cities, { tz = entry.tz, label = entry.label or entry.tz })
    end
  end
end

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
local function shortLabel(zone)
  local city = zone:match(".*/(.*)$")
  if city ~= nil then
    return (city:gsub("_", " "))
  end
  return zone
end

local function indexOfCity(zone)
  for i, entry in ipairs(cities) do
    if entry.tz == zone then
      return i
    end
  end
  return nil
end

-- "+0200" -> 120, "-0930" -> -570
local function parseOffsetMinutes(value)
  if type(value) ~= "string" or #value < 5 then
    return nil
  end
  local sign = value:sub(1, 1) == "-" and -1 or 1
  local hours = tonumber(value:sub(2, 3)) or 0
  local minutes = tonumber(value:sub(4, 5)) or 0
  return sign * (hours * 60 + minutes)
end

local function timeText(zone)
  local raw = noctalia.formatTime("%H|%M", nil, zone)
  local hh, mm = raw:match("(%d+)|(%d+)")
  if hh == nil then
    return "--:--"
  end
  if noctalia.getConfig("time_format") == "12h" then
    local hour12 = tonumber(hh) % 12
    if hour12 == 0 then
      hour12 = 12
    end
    return string.format("%d:%s %s", hour12, mm, tonumber(hh) < 12 and "AM" or "PM")
  end
  return hh .. ":" .. mm
end

local function dateText(zone)
  local style = noctalia.getConfig("date_format") or "weekday"
  local format = "%a, %b %d"
  if style == "short" then
    format = "%b %d"
  elseif style == "iso" then
    format = "%Y-%m-%d"
  end
  return noctalia.formatTime(format, nil, zone)
end

-- "+7h", "-5h 30m", or the "same time" string when the zones agree.
local function deltaText(offsetMinutes, deviceOffsetMinutes)
  if offsetMinutes == nil or deviceOffsetMinutes == nil then
    return ""
  end
  local difference = offsetMinutes - deviceOffsetMinutes
  if difference == 0 then
    return noctalia.tr("row.same-time")
  end
  local sign = difference > 0 and "+" or "\u{2212}"
  local absolute = math.abs(difference)
  local hours = math.floor(absolute / 60)
  local minutes = absolute % 60
  if minutes == 0 then
    return sign .. tostring(hours) .. "h"
  end
  if hours == 0 then
    return sign .. tostring(minutes) .. "m"
  end
  return sign .. tostring(hours) .. "h " .. tostring(minutes) .. "m"
end

-- ---------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------
local function computeRows()
  local rows = {}
  if deviceTz == "" then
    return rows
  end

  local deviceOffset = parseOffsetMinutes(noctalia.formatTime("%z", nil, deviceTz))
  table.insert(rows, {
    key = "__device__",
    label = shortLabel(deviceTz),
    tz = deviceTz,
    isDevice = true,
    timeText = timeText(deviceTz),
    dateText = dateText(deviceTz),
    abbrev = noctalia.formatTime("%Z", nil, deviceTz),
    deltaText = noctalia.tr("row.device"),
    offsetMinutes = deviceOffset,
  })

  for index, entry in ipairs(cities) do
    if entry.tz ~= deviceTz then
      local offset = parseOffsetMinutes(noctalia.formatTime("%z", nil, entry.tz))
      table.insert(rows, {
        key = entry.tz .. "#" .. index,
        label = entry.label or shortLabel(entry.tz),
        tz = entry.tz,
        isDevice = false,
        timeText = timeText(entry.tz),
        dateText = dateText(entry.tz),
        abbrev = noctalia.formatTime("%Z", nil, entry.tz),
        deltaText = deltaText(offset, deviceOffset),
        offsetMinutes = offset,
      })
    end
  end
  return rows
end

local function publish()
  noctalia.state.set("timezone_grid.device_tz", deviceTz)
  -- The raw ordered list as well as the computed rows: `rows` hides a city
  -- that currently matches the device zone, so the panel needs the real list
  -- to index drop positions against.
  noctalia.state.set("timezone_grid.cities", cities)
  noctalia.state.set("timezone_grid.rows", computeRows())
end

-- ---------------------------------------------------------------------
-- Device timezone
-- ---------------------------------------------------------------------
local function detectDeviceTimezone()
  noctalia.runAsync({ "timedatectl", "show", "-p", "Timezone", "--value" }, function(result)
    local tz = result.stdout and noctalia.string.trim(result.stdout) or ""
    if tz ~= "" then
      deviceTz = tz
      publish()
      return
    end
    noctalia.runAsync(
      { "sh", "-c", "readlink -f /etc/localtime | sed 's#.*/zoneinfo/##'" },
      function(fallback)
        local fallbackTz = fallback.stdout and noctalia.string.trim(fallback.stdout) or ""
        if fallbackTz ~= "" then
          deviceTz = fallbackTz
          publish()
        else
          noctalia.log("TimezoneGrid: could not detect the device timezone")
        end
      end
    )
  end)
end

-- ---------------------------------------------------------------------
-- Zone list for the picker
-- ---------------------------------------------------------------------
local function loadAllZones()
  if allZonesLoaded or allZonesLoading then
    return
  end
  allZonesLoading = true
  allZonesLoadStartedMs = noctalia.nowMs()
  noctalia.runAsync({ "timedatectl", "list-timezones" }, function(result)
    allZonesLoading = false
    allZonesLoadStartedMs = nil
    local list = {}
    if result.exitCode == 0 and result.stdout then
      for line in result.stdout:gmatch("[^\r\n]+") do
        local trimmed = noctalia.string.trim(line)
        if trimmed ~= "" then
          table.insert(list, trimmed)
        end
      end
    end
    allZones = #list > 0 and list or FALLBACK_ZONES
    allZonesLoaded = true
    noctalia.state.set("timezone_grid.all_zones", allZones)
    noctalia.state.set("timezone_grid.all_zones_loaded", true)
  end)
end

-- ---------------------------------------------------------------------
-- City list
-- ---------------------------------------------------------------------
local function addCity(tz, label)
  tz = noctalia.string.trim(tz or "")
  if tz == "" or tz == deviceTz or not noctalia.isValidTimezone(tz) then
    return false, "invalid"
  end
  if indexOfCity(tz) ~= nil then
    return false, "duplicate"
  end
  if #cities >= MAX_CITIES then
    return false, "full"
  end
  table.insert(cities, { tz = tz, label = (label and label ~= "") and label or shortLabel(tz) })
  saveData()
  publish()
  return true
end

local function removeCity(tz)
  local index = indexOfCity(tz)
  if index == nil then
    return false
  end
  table.remove(cities, index)
  saveData()
  publish()
  return true
end

-- Move `tz` so it ends up at 1-based `index` in the final list.
local function reorderCity(tz, index)
  local from = indexOfCity(tz)
  local insertAt = tonumber(index)
  if from == nil or insertAt == nil then
    return false
  end
  local entry = table.remove(cities, from)
  if from < insertAt then
    insertAt -= 1
  end
  insertAt = math.max(1, math.min(insertAt, #cities + 1))
  table.insert(cities, insertAt, entry)
  saveData()
  publish()
  return true
end

-- ---------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------
noctalia.state.watch("timezone_grid.cmd", function(cmd)
  if type(cmd) ~= "table" then
    return
  end
  local op = cmd.op
  if op == "add" then
    local ok, reason = addCity(cmd.tz, cmd.label)
    if not ok then
      if reason == "duplicate" then
        noctalia.notifyError(noctalia.tr("toast.title"), noctalia.tr("toast.duplicate", { zone = cmd.tz or "" }))
      elseif reason == "full" then
        noctalia.notifyError(noctalia.tr("toast.title"), noctalia.tr("toast.full", { count = tostring(MAX_CITIES) }))
      else
        noctalia.notifyError(noctalia.tr("toast.title"), noctalia.tr("toast.invalid", { zone = cmd.tz or "" }))
      end
    end
  elseif op == "remove" then
    removeCity(cmd.tz)
  elseif op == "reorder" then
    reorderCity(cmd.tz, cmd.index)
  elseif op == "load_zones" then
    loadAllZones()
  end
  noctalia.state.set("timezone_grid.cmd", nil)
end)

function onIpc(event, payload)
  if event == "add" then
    addCity(payload or "")
  elseif event == "remove" then
    removeCity(payload or "")
  elseif event == "list" then
    local names = {}
    for _, entry in ipairs(cities) do
      table.insert(names, entry.tz)
    end
    local body = table.concat(names, "\n")
    noctalia.notify(noctalia.tr("toast.title"), body ~= "" and body or noctalia.tr("toast.empty-list"))
  end
end

function update()
  -- Self-heal a zone-list fetch whose callback never fired, so a picker left
  -- on "Loading…" recovers without restarting the plugin.
  if allZonesLoading
    and allZonesLoadStartedMs ~= nil
    and (noctalia.nowMs() - allZonesLoadStartedMs) > ZONES_LOAD_TIMEOUT_MS
  then
    noctalia.log("TimezoneGrid: zone list load timed out, retrying")
    allZonesLoading = false
    allZonesLoadStartedMs = nil
    loadAllZones()
  end
  publish()
end

loadData()
detectDeviceTimezone()
publish()
