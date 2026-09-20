--!nonstrict
-- Timezone Grid panel — the device row pinned on top, then one row per
-- comparison city. Every row carries the same 24 columns of one local day in
-- the device zone, so a column is the same instant in every row and the eye
-- reads across. A column whose local hour is 00 prints the date instead of
-- the hour, which is where a city's day changes.
--
-- The grid is a fixed 24 columns of a fixed panel width, so every width here
-- is explicit: flexGrow competing with fixed-width siblings in the same row
-- does not reliably claim its share, which leaves the columns of one row out
-- of step with the next.
--
-- A row's children add up to ROW_WIDTH below. The panel width in plugin.toml
-- is ROW_WIDTH plus the space the host takes around the rows: 27px on each
-- side (the host's own panel inset, the 8px column padding and the scroll
-- viewport's 4px padding) and a 14px scrollbar gutter once the list is taller
-- than the viewport. The panel cannot size itself to its content: the host
-- owns the size, and the manifest takes a number or "fill" for the whole
-- output. A row that gets less than ROW_WIDTH does not shrink its children;
-- it draws the last one, the remove button, past its own edge, where the
-- card clips it.
--
-- The pointer outlines the column it is over in every row at once, and a
-- click holds that outline in place until the same column is clicked again.
-- One outline that spans the rows is not possible: each row is its own card,
-- so the column is drawn as one outline per cell.
--
-- A second view is a searchable IANA-zone picker for adding a city.

local DRAG_TYPE = "timezone-grid-city"

local COLUMNS = 24
local CELL_GAP = 2
local CELL_HEIGHT = 38
-- The height of a row's contents. Each hour cell sits in a column of this
-- height that carries the pointer handlers, so the band the pointer can be in
-- and still name a column runs the full height of the row card. The value is
-- a little above the height of the four lines in the info block, which is what
-- otherwise sets the height of a row.
local ROW_HEIGHT = 56
-- The height of the band between two row cards. The band holds the drop zone
-- that a dragged row lands in, and the same 24 columns the rows carry.
local BAND_HEIGHT = 8
-- The width the title and the buttons each take in the header. It holds both,
-- and it is what centres the date between them.
local HEADER_SIDE_WIDTH = 170
local STRIP_WIDTH = 720
local GRIP_WIDTH = 16
local INFO_WIDTH = 152
local ACTIONS_WIDTH = 30
local ROW_GAP = 6
local ROW_PADDING_H = 6
local ROW_WIDTH = ROW_PADDING_H * 2 + GRIP_WIDTH + INFO_WIDTH + STRIP_WIDTH + ACTIONS_WIDTH + ROW_GAP * 3
-- Where the hour columns start inside a row, for the ruler above the grid.
local STRIP_INSET = ROW_PADDING_H + GRIP_WIDTH + ROW_GAP + INFO_WIDTH + ROW_GAP

local rows = {}
local cities = {}
local deviceTz = ""
local allZones = {}
local allZonesLoaded = false

local view = "list" -- "list" | "picker"
local query = ""
local queryKey = 0

-- The column under the pointer, and the column a click holds. Both are column
-- indexes from 0 to 23, or nil when there is no such column.
local hoveredColumn = nil
local pinnedColumn = nil

-- ---------------------------------------------------------------------
-- The day window
-- ---------------------------------------------------------------------
local function deviceZone()
	return deviceTz ~= "" and deviceTz or nil
end

local function secondsNow()
	return math.floor(noctalia.nowMs() / 1000)
end

-- The epoch of 00:00 local time in `zone`, on the day that holds `probe`.
local function localMidnight(zone, probe)
	local raw = noctalia.formatTime("%H|%M|%S", probe, zone)
	local hh, mm, ss = raw:match("(%d+)|(%d+)|(%d+)")
	if hh == nil then
		return probe
	end
	return probe - (tonumber(hh) * 3600 + tonumber(mm) * 60 + tonumber(ss))
end

-- Midnight of today, in the device zone.
local function windowStart()
	return localMidnight(deviceZone(), secondsNow())
end

-- The column that holds the current hour, or nil when the hour falls outside
-- the 24 columns. A day that gains an hour has 25 local hours, so the last of
-- them has no column.
local function nowColumn(start)
	local column = math.floor((secondsNow() - start) / 3600)
	if column < 0 or column >= COLUMNS then
		return nil
	end
	return column
end

local function gridContext()
	local highlightWork = noctalia.getConfig("highlight_work_hours")
	if highlightWork == nil then
		highlightWork = true
	end
	local start = windowStart()
	return {
		start = start,
		nowColumn = nowColumn(start),
		cellWidth = (STRIP_WIDTH - (COLUMNS - 1) * CELL_GAP) / COLUMNS,
		use24h = (noctalia.getConfig("time_format") or "24h") == "24h",
		highlightWork = highlightWork,
		workStart = noctalia.getConfig("work_hour_start") or 9,
		workEnd = noctalia.getConfig("work_hour_end") or 18,
		hoveredColumn = hoveredColumn,
		pinnedColumn = pinnedColumn,
	}
end

-- ---------------------------------------------------------------------
-- Cells
-- ---------------------------------------------------------------------
local function cellInfo(zone, epoch)
	local raw = noctalia.formatTime("%H|%b|%d", epoch, zone)
	local hour, month, day = raw:match("(%d+)|([^|]+)|(%d+)")
	if hour == nil then
		return nil
	end
	return { hour = tonumber(hour), month = month, day = day }
end

-- One formatTime call per cell is 24 calls a row, and the pointer moving from
-- one column to the next redraws every row. The hours a zone shows in the
-- current day window therefore live in a cache. A new window empties it.
local hourCache = {}
local hourCacheStart = nil

local function zoneHours(zone, start)
	if hourCacheStart ~= start then
		hourCache = {}
		hourCacheStart = start
	end
	-- `zone` is nil while the device zone is unknown, and a table takes no nil
	-- key, so the empty string stands for the host's own zone.
	local cacheKey = zone or ""
	local hours = hourCache[cacheKey]
	if hours ~= nil then
		return hours
	end
	hours = {}
	for index = 0, COLUMNS - 1 do
		-- `false`, not nil, or a zone the host cannot format is looked up
		-- again on every redraw.
		hours[index] = cellInfo(zone, start + index * 3600) or false
	end
	hourCache[cacheKey] = hours
	return hours
end

-- ---------------------------------------------------------------------
-- The highlighted column
-- ---------------------------------------------------------------------
-- The host sends the hover state as the string "true" or "false". Every Lua
-- string is true in a condition, so the value is compared, not tested.
local function isEntered(state)
	return state == true or state == "true"
end

-- Only the entry into a cell counts. A cell reports that the pointer left it
-- as soon as the pointer crosses into the gap between two row cards, and a
-- column cleared there blinks out on the way from one row to the next. The
-- outline therefore stays on the last cell the pointer entered.
local function trackColumn(index, state)
	if not isEntered(state) or hoveredColumn == index then
		return
	end
	hoveredColumn = index
	render()
end

-- The grid as a whole drops the outline. A container reports no leave while
-- the pointer moves onto its own children, so it reports one leave, when the
-- pointer goes off the grid.
local function clearColumn(state)
	if isEntered(state) or hoveredColumn == nil then
		return
	end
	hoveredColumn = nil
	render()
end

local function pinColumn(index)
	if pinnedColumn == index then
		pinnedColumn = nil
	else
		pinnedColumn = index
	end
	render()
end

-- The cell the eye reads, without the pointer handlers. `hourCell` puts it in
-- the taller column that has them.
local function hourBox(index, context, rowKey, hours)
	local props = {
		key = rowKey .. "-cell-" .. tostring(index),
		width = context.cellWidth,
		height = CELL_HEIGHT,
		align = "center",
		justify = "center",
		gap = 0,
		radius = 3,
	}
	-- The outline is drawn inside the cell, so a highlighted column keeps the
	-- width of every other column and the grid does not move. Both border
	-- props are set on every cell: the host keeps the last value of a prop
	-- that a later tree leaves out, and a cell that loses its outline that way
	-- keeps drawing it.
	props.border = "on_surface"
	props.borderWidth = 0
	if index == context.pinnedColumn then
		props.borderWidth = 2
	elseif index == context.hoveredColumn then
		props.border = "on_surface/0.45"
		props.borderWidth = 2
	end

	local info = hours[index]
	if info == false then
		props.fill = "surface/0.70"
		return ui.column(props, { ui.label({ text = "\u{2026}", fontSize = 10, color = "on_surface_variant" }) })
	end

	local isNow = index == context.nowColumn
	local top, sub, topColor, subColor, weight

	if info.hour == 0 then
		-- The city's date changes in this column; name the day, not the hour.
		props.fill = "tertiary/0.30"
		top = info.month:upper()
		sub = info.day
		topColor = "tertiary"
		subColor = "tertiary"
		weight = "bold"
	else
		local isNight = info.hour < 6 or info.hour >= 22
		local isWork = context.highlightWork and info.hour >= context.workStart and info.hour < context.workEnd
		if isWork then
			props.fill = "on_surface/0.10"
			topColor = "on_surface"
		elseif isNight then
			props.fill = "surface/0.70"
			topColor = "on_surface_variant/0.55"
		else
			props.fill = "on_surface/0.03"
			topColor = "on_surface_variant"
		end

		if context.use24h then
			top = string.format("%02d", info.hour)
			sub = ""
		else
			local hour12 = info.hour % 12
			if hour12 == 0 then
				hour12 = 12
			end
			top = tostring(hour12)
			sub = info.hour < 12 and "am" or "pm"
		end
		subColor = topColor
		weight = "normal"
	end

	if isNow then
		props.fill = "primary/0.28"
		topColor = "primary"
		subColor = "primary"
		weight = "bold"
	end

	local lines = {
		ui.label({ text = top, fontSize = 11, color = topColor, fontWeight = weight, textAlign = "center" }),
	}
	if sub ~= "" then
		table.insert(lines, ui.label({ text = sub, fontSize = 8, color = subColor, textAlign = "center" }))
	end
	return ui.column(props, lines)
end

local function hourCell(index, context, rowKey, hours)
	return ui.column({
		key = rowKey .. "-hit-" .. tostring(index),
		width = context.cellWidth,
		height = ROW_HEIGHT,
		align = "center",
		justify = "center",
		gap = 0,
		onClick = function()
			pinColumn(index)
		end,
		onHover = function(state)
			trackColumn(index, state)
		end,
	}, { hourBox(index, context, rowKey, hours) })
end

local function hourStrip(zone, context, rowKey)
	local hours = zoneHours(zone, context.start)
	local cells = {}
	for index = 0, COLUMNS - 1 do
		table.insert(cells, hourCell(index, context, rowKey, hours))
	end
	return ui.row({ key = rowKey .. "-strip", width = STRIP_WIDTH, height = ROW_HEIGHT, gap = CELL_GAP }, cells)
end

-- A 4px tick strip above the grid. It gives the current hour a head that the
-- per-row fills cannot draw on their own, because the gaps between row cards
-- break the column into separate blocks.
local function ruler(context)
	local hours = zoneHours(deviceZone(), context.start)
	local ticks = {}
	for index = 0, COLUMNS - 1 do
		local info = hours[index]
		local fill = "outline/0.35"
		if index == context.nowColumn then
			fill = "primary"
		elseif index == context.pinnedColumn or index == context.hoveredColumn then
			fill = "on_surface"
		elseif
			info ~= false
			and context.highlightWork
			and info.hour >= context.workStart
			and info.hour < context.workEnd
		then
			fill = "on_surface/0.30"
		end
		table.insert(
			ticks,
			ui.box({
				key = "tick-" .. tostring(index),
				width = context.cellWidth,
				height = 4,
				radius = 2,
				fill = fill,
			})
		)
	end
	-- An empty fixed-width box rather than a left pad: the row layout props
	-- carry paddingH, which would inset both ends and pull the ticks out of
	-- step with the cells below them. The box draws a default fill when it has
	-- none of its own, so `opacity` hides it and leaves its width behind. Both
	-- the row and the box state their height, or the row claims a share of the
	-- panel's spare vertical space and floats the ticks away from the grid.
	return ui.row({ gap = 0, height = 4, align = "center" }, {
		ui.box({ width = STRIP_INSET, height = 4, opacity = 0 }),
		ui.row({ width = STRIP_WIDTH, height = 4, gap = CELL_GAP }, ticks),
	})
end

-- The space between two row cards, filled with the same 24 columns the rows
-- carry. Without it the pointer names no column there, and the outline stays
-- on the column it last read while the pointer crosses to another row.
local function columnBand(key, context)
	local targets = {}
	for index = 0, COLUMNS - 1 do
		table.insert(
			targets,
			ui.column({
				key = key .. "-band-" .. tostring(index),
				width = context.cellWidth,
				height = BAND_HEIGHT,
				onClick = function()
					pinColumn(index)
				end,
				onHover = function(state)
					trackColumn(index, state)
				end,
			}, {
				-- A container holds the size it asks for only while it has a
				-- child, and a box with no fill of its own draws one, so the
				-- child is a box that opacity hides.
				ui.box({ width = context.cellWidth, height = BAND_HEIGHT, opacity = 0 }),
			})
		)
	end
	return ui.row({ key = key .. "-band", gap = 0, height = BAND_HEIGHT, align = "center" }, {
		ui.box({ width = STRIP_INSET, height = BAND_HEIGHT, opacity = 0 }),
		ui.row({ width = STRIP_WIDTH, height = BAND_HEIGHT, gap = CELL_GAP }, targets),
	})
end

-- ---------------------------------------------------------------------
-- Drag and drop (comparison rows only)
-- ---------------------------------------------------------------------
local function insertionZone(index, context)
	return ui.dropZone({
		key = "gap-" .. tostring(index),
		accepts = { DRAG_TYPE },
		value = tostring(index),
		onDrop = "onZoneDropped",
		height = BAND_HEIGHT,
		radius = 4,
		expandOnDrag = true,
		hitSlop = 20,
	}, { columnBand("zone-" .. tostring(index), context) })
end

function onZoneDropped(payload, value)
	local insertAt = tonumber(value)
	if type(payload) ~= "string" or payload == "" or insertAt == nil then
		return
	end
	noctalia.state.set("timezone_grid.cmd", { op = "reorder", tz = payload, index = insertAt })
end

-- ---------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------
local function cityRow(row, context)
	local isDevice = row.isDevice

	-- The device row has no grip and no remove button, but the slots that hold
	-- them still have to take up the same width, or its hour columns sit left of
	-- every other row's and the grid stops lining up. A container asked to be a
	-- fixed width holds that width only while it has something in it, so the
	-- device row builds the same nodes and hides them with `opacity`, which
	-- leaves the layout alone.
	local grip
	if isDevice then
		grip = ui.column({
			width = GRIP_WIDTH,
			height = 20,
			align = "center",
			justify = "center",
			opacity = 0,
		}, {
			ui.glyph({ name = "menu-2", size = 12, color = "on_surface_variant" }),
		})
	else
		grip = ui.dragSource({
			key = "grip-" .. row.tz,
			dragType = DRAG_TYPE,
			payload = row.tz,
			previewAncestor = 1,
			liftFromLayout = true,
			width = GRIP_WIDTH,
			height = 20,
			align = "center",
			justify = "center",
			tooltip = noctalia.tr("row.drag-tooltip"),
		}, {
			ui.glyph({ name = "menu-2", size = 12, color = "on_surface_variant" }),
		})
	end

	local info = ui.column({ width = INFO_WIDTH, gap = 1, justify = "center" }, {
		ui.row({ gap = 5, align = "center", justify = "start" }, {
			ui.label({ text = row.label, fontSize = 13, fontWeight = "bold", maxLines = 1 }),
			ui.label({ text = row.abbrev or "", fontSize = 8, color = "on_surface_variant", maxLines = 1 }),
		}),
		ui.label({ text = row.tz, fontSize = 9, color = "on_surface_variant", maxLines = 1 }),
		ui.row({ gap = 5, align = "center", justify = "start" }, {
			ui.label({
				text = row.timeText or "--:--",
				fontSize = 17,
				fontWeight = "bold",
				color = isDevice and "primary" or "on_surface",
			}),
			ui.label({ text = row.deltaText or "", fontSize = 9, color = "on_surface_variant" }),
		}),
		ui.label({ text = row.dateText or "", fontSize = 9, color = "on_surface_variant", maxLines = 1 }),
	})

	local removeButton = {
		key = "remove-" .. row.key,
		glyph = "trash",
		glyphSize = 14,
		variant = "ghost",
		width = 26,
		height = 26,
		paddingH = 0,
		paddingV = 0,
	}
	if isDevice then
		removeButton.enabled = false
		removeButton.opacity = 0
	else
		removeButton.tooltip = noctalia.tr("row.remove")
		removeButton.onClick = function()
			noctalia.state.set("timezone_grid.cmd", { op = "remove", tz = row.tz })
		end
	end
	local actions = { ui.button(removeButton) }

	return ui.row({
		key = "row-" .. row.key,
		width = ROW_WIDTH,
		gap = ROW_GAP,
		align = "center",
		justify = "start",
		paddingV = 0,
		paddingH = ROW_PADDING_H,
		fill = isDevice and "surface_variant/0.45" or "surface_variant/0.25",
		radius = 7,
	}, {
		grip,
		info,
		hourStrip(row.tz, context, row.key),
		ui.row({ width = ACTIONS_WIDTH, gap = 0, align = "center", justify = "center" }, actions),
	})
end

local function rowFor(tz)
	for _, row in ipairs(rows) do
		if row.tz == tz then
			return row
		end
	end
	return nil
end

-- ---------------------------------------------------------------------
-- List view
-- ---------------------------------------------------------------------
local function header(context)
	local windowDate = deviceTz ~= "" and noctalia.formatTime("%a, %b %d", context.start + 43200, deviceZone())
		or noctalia.tr("panel.detecting")

	-- The title and the buttons take the same width on both sides, so the date
	-- between them sits in the middle of the bar. A side that claimed its width
	-- from what the other two leave would put the date off centre.
	return ui.row({ align = "center", justify = "space_between" }, {
		ui.row({ width = HEADER_SIDE_WIDTH, gap = 8, align = "center", justify = "start" }, {
			ui.glyph({ name = "world", size = 20, color = "primary" }),
			ui.label({ text = noctalia.tr("panel.title"), fontSize = 14, fontWeight = "bold" }),
		}),
		ui.label({ text = windowDate, fontSize = 11, fontWeight = "bold" }),
		ui.row({ width = HEADER_SIDE_WIDTH, gap = 4, align = "center", justify = "end" }, {
			ui.button({
				glyph = "plus",
				variant = "ghost",
				controlSize = "sm",
				tooltip = noctalia.tr("panel.add"),
				enabled = #cities < 6,
				onClick = function()
					openPicker()
				end,
			}),
			ui.button({
				glyph = "settings",
				variant = "ghost",
				controlSize = "sm",
				tooltip = noctalia.tr("panel.open-settings"),
				onClick = function()
					noctalia.openSettings()
				end,
			}),
			ui.button({
				glyph = "close",
				variant = "ghost",
				controlSize = "sm",
				onClick = function()
					panel.close()
				end,
			}),
		}),
	})
end

local function legendSwatch(fill, key)
	return ui.row({ gap = 4, align = "center", justify = "start" }, {
		ui.box({ width = 10, height = 10, radius = 2, fill = fill }),
		ui.label({ text = noctalia.tr(key), fontSize = 9, color = "on_surface_variant" }),
	})
end

local function footer(context)
	local items = {}
	if context.highlightWork then
		table.insert(
			items,
			ui.row({ gap = 4, align = "center", justify = "start" }, {
				ui.box({ width = 10, height = 10, radius = 2, fill = "on_surface/0.10" }),
				ui.label({
					text = string.format("%02d:00\u{2013}%02d:00", context.workStart, context.workEnd),
					fontSize = 9,
					color = "on_surface_variant",
				}),
			})
		)
	end
	return ui.row({ gap = 12, align = "center", justify = "start" }, {
		ui.row({ gap = 12, align = "center", justify = "start" }, items),
		legendSwatch("surface/0.70", "legend.night"),
		legendSwatch("tertiary/0.30", "legend.date-change"),
	})
end

local function listView()
	local context = gridContext()
	local body = { header(context), ui.separator({}) }

	if rows[1] == nil then
		table.insert(
			body,
			ui.column({ flexGrow = 1, justify = "center", align = "center" }, {
				ui.label({ text = noctalia.tr("panel.detecting"), fontSize = 11, color = "on_surface_variant" }),
			})
		)
		return ui.column({ flexGrow = 1, gap = 6, padding = 8, justify = "start" }, body)
	end

	-- The ruler and every row, device row included, are children of the same
	-- viewport. A viewport insets its children by an amount the plugin API does
	-- not name, so anything laid out beside it rather than inside it sits a few
	-- pixels off and the hour columns no longer line up down the grid.
	-- The rows sit against each other with no gap between them. The band each
	-- pair of rows is separated by is a node of its own, so the pointer reads a
	-- column there as well.
	local list = { ruler(context), columnBand("ruler", context), cityRow(rows[1], context) }
	for index, entry in ipairs(cities) do
		local row = rowFor(entry.tz)
		if row ~= nil and not row.isDevice then
			table.insert(list, insertionZone(index, context))
			table.insert(list, cityRow(row, context))
		end
	end
	if #cities > 0 then
		table.insert(list, insertionZone(#cities + 1, context))
	else
		table.insert(
			list,
			ui.column({ paddingV = 8 }, {
				ui.label({
					text = noctalia.tr("panel.empty"),
					fontSize = 11,
					color = "on_surface_variant",
				}),
			})
		)
	end

	-- The rows go in a column of their own inside the viewport. A short list
	-- left as the viewport's own children sits in the middle of it, which opens
	-- a blank band under the device row.
	table.insert(
		body,
		ui.scroll({ flexGrow = 1, padding = 0, align = "stretch" }, {
			ui.column({
				key = "grid",
				gap = 0,
				align = "stretch",
				justify = "start",
				onHover = clearColumn,
			}, list),
		})
	)

	table.insert(body, footer(context))
	return ui.column({ flexGrow = 1, gap = 6, padding = 8, justify = "start" }, body)
end

-- ---------------------------------------------------------------------
-- Picker view
-- ---------------------------------------------------------------------
local function shortLabel(zone)
	local city = zone:match(".*/(.*)$")
	if city ~= nil then
		return (city:gsub("_", " "))
	end
	return zone
end

local function filteredZones()
	local needle = noctalia.string.trim(query):lower()
	local matches = {}
	for _, zone in ipairs(allZones) do
		if needle == "" or zone:lower():find(needle, 1, true) ~= nil then
			table.insert(matches, zone)
			if #matches >= 100 then
				break
			end
		end
	end
	return matches
end

local function pick(tz)
	noctalia.state.set("timezone_grid.cmd", { op = "add", tz = tz, label = shortLabel(tz) })
	view = "list"
	render()
end

function onPickerSubmit(_value)
	local matches = filteredZones()
	if #matches == 1 then
		pick(matches[1])
	end
end

local function pickerView()
	local body = {
		ui.row({ gap = 6, align = "center", justify = "start" }, {
			ui.button({
				glyph = "arrow-left",
				variant = "ghost",
				controlSize = "sm",
				tooltip = noctalia.tr("picker.back"),
				onClick = function()
					view = "list"
					render()
				end,
			}),
			ui.label({ text = noctalia.tr("picker.title"), fontSize = 13, fontWeight = "bold", flexGrow = 1 }),
		}),
		ui.input({
			key = "search-" .. tostring(queryKey),
			value = query,
			placeholder = noctalia.tr("picker.search-placeholder"),
			submitOnEnter = true,
			focus = true,
			onChange = function(value)
				query = value
				render()
			end,
			onSubmit = "onPickerSubmit",
		}),
	}

	if not allZonesLoaded then
		table.insert(
			body,
			ui.label({ text = noctalia.tr("picker.loading"), fontSize = 10, color = "on_surface_variant" })
		)
	end

	local matches = filteredZones()
	if allZonesLoaded and #matches == 0 then
		table.insert(
			body,
			ui.label({ text = noctalia.tr("picker.empty"), fontSize = 11, color = "on_surface_variant" })
		)
	else
		local buttons = {}
		for _, zone in ipairs(matches) do
			table.insert(
				buttons,
				ui.button({
					key = "zone-" .. zone,
					text = (zone:gsub("_", " ")),
					glyph = "plus",
					variant = "ghost",
					contentAlign = "start",
					onClick = function()
						pick(zone)
					end,
				})
			)
		end
		table.insert(body, ui.scroll({ flexGrow = 1, gap = 2, align = "stretch", justify = "start" }, buttons))
	end

	return ui.column({ flexGrow = 1, gap = 6, padding = 8, justify = "start" }, body)
end

-- ---------------------------------------------------------------------
-- Render
-- ---------------------------------------------------------------------
function render()
	if view == "picker" then
		panel.render(pickerView())
	else
		panel.render(listView())
	end
end

function openPicker()
	view = "picker"
	query = ""
	queryKey += 1
	if not allZonesLoaded then
		noctalia.state.set("timezone_grid.cmd", { op = "load_zones" })
	end
	render()
end

function onOpen(_context)
	view = "list"
	render()
end

noctalia.state.watch("timezone_grid.rows", function(value)
	rows = type(value) == "table" and value or {}
	render()
end)

noctalia.state.watch("timezone_grid.cities", function(value)
	cities = type(value) == "table" and value or {}
	render()
end)

noctalia.state.watch("timezone_grid.device_tz", function(value)
	deviceTz = type(value) == "string" and value or ""
	render()
end)

noctalia.state.watch("timezone_grid.all_zones", function(value)
	allZones = type(value) == "table" and value or {}
	render()
end)

noctalia.state.watch("timezone_grid.all_zones_loaded", function(value)
	allZonesLoaded = value == true
	render()
end)
