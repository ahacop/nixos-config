# Timezone Grid

A Noctalia panel that compares cities on a 24-hour grid, in the shape
[worldtimebuddy.com](https://worldtimebuddy.com) uses.

The device timezone is the first row. Each city below it gets its own row.
Every row carries the same 24 columns, and each column is one hour of one
local day in the device zone. A column is therefore the same instant in every
row, so you read a meeting time straight down the grid.

- Work hours are shaded. The range is a setting; 09:00–18:00 by default.
- Hours from 22:00 to 06:00 are darkened.
- A column whose local hour is 00 prints the date instead of the hour. That is
  where the city's day changes.
- The current hour is filled with the accent color and gets a tick on the
  ruler above the grid.
- The column under the pointer is outlined in every row at once. A click on a
  cell holds that outline in place, so one instant stays marked down the grid
  while the pointer moves away. A click on the held column removes the
  outline.

## Using it

The panel opens through its entry id:

```sh
noctalia msg panel-toggle ahacop/timezone-grid:panel
```

Bind that to a bar widget gesture to reach it, for example from the clock:

```toml
[bar.default.clock.actions]
right = "panel-toggle ahacop/timezone-grid:panel"
```

Press `+` to add a city, drag a row by its grip to reorder it, and press the
trash icon to remove it. Click an hour to hold its column outlined, and click
it again to drop the outline. The grid holds six cities plus the device row.

## IPC

```sh
noctalia msg plugin ahacop/timezone-grid:service all add Asia/Tokyo
noctalia msg plugin ahacop/timezone-grid:service all remove Asia/Tokyo
noctalia msg plugin ahacop/timezone-grid:service all list
```

## What it needs

`timedatectl`, to read the device timezone and to list the IANA zones for the
picker. The plugin never changes the device timezone, so it needs no
privileged helper.

## Daylight saving

The grid is 24 fixed columns starting at local midnight. A day that gains or
loses an hour has 23 or 25 local hours, so on those two days a year the last
column is an hour off from the end of the day. Each cell still prints the hour
that zone really has at that instant, and the date-change column still lands
where the date changes.
