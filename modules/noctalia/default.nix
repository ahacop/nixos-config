{
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      # Noctalia is the whole shell layer: bar, launcher, notification daemon,
      # control center, clipboard history, OSDs and lock screen in one process.
      # It replaces waybar, mako, walker and cliphist, so none of those are
      # installed. Colors, fonts and opacity arrive from stylix via
      # `stylix.targets.noctalia`, which writes a custom palette and points the
      # theme at it — the scheme itself stays set in configuration.nix.
      #
      # `settings` is an attrset rendered to TOML. `checkConfig` (on by default)
      # runs `noctalia config validate` over the result during the build, so a
      # bad key or widget name fails `make test` rather than at login.
      programs.noctalia = {
        enable = true;
        systemd.enable = false; # Started directly by niri spawn-at-startup

        settings = {
          # Panels and menus fade in and out by default, which reads as lag.
          shell.animation.enabled = false;

          # Noctalia draws a wallpaper of its own, falling back to the image
          # bundled in its package. With it off, the niri layout
          # background-color set in modules/niri is what shows behind the
          # windows. A wallpaper picked in the Noctalia UI is written to
          # ~/.local/state/noctalia/settings.toml, and that file takes
          # precedence over this one, so setting a path here would not survive
          # the first pick.
          wallpaper.enabled = false;

          # This VM has no wifi radio and no bluetooth adapter. VMware bridges
          # the Mac's connection and passes through an emulated ethernet NIC, so
          # the network and bluetooth surfaces have nothing to list. Hide the two
          # control center tabs, drop their quick shortcuts, and stop their OSDs.
          # Throughput still shows in the bar via the sysmon widgets below.
          control_center = {
            hidden_tabs = [
              "network"
              "bluetooth"
            ];
            shortcuts = [
              { type = "caffeine"; }
              { type = "nightlight"; }
              { type = "notification"; }
              { type = "power_profile"; }
            ];
          };

          osd.kinds = {
            wifi = false;
            bluetooth = false;
          };

          plugins.enabled = [
            "ahacop/timezone-grid"
            "goodroot/noctwhspr"
          ];

          bar = {
            order = [ "default" ];
            default = {
              position = "bottom";
              enabled = true;
              thickness = 35;

              # A plain bar edge to edge. The defaults float it: margin_ends
              # insets it 100px at each end, and radius rounds the corners.
              margin_ends = 0;
              radius = 0;
              shadow = false;
              start = [
                "launcher"
                "workspaces"
                "active_window"
              ];
              center = [ ];
              # The old waybar right side, minus battery: this VM has no
              # /sys/class/power_supply entry, so a battery readout is blank.
              end = [
                "netrx"
                "nettx"
                "disk"
                "ram"
                "cpu"
                # hyprwhspr state: a red dot while it records, a microphone
                # when it is ready. Left click toggles a recording, right click
                # restarts the service.
                "goodroot/noctwhspr:status"
                "volume"
                "tray"
                "notifications"
                "clipboard"
                "clock"
                "control_center"
              ];
            };
          };

          # Named widget instances referenced by the bar sections above. Several
          # are the one `sysmon` widget pinned to a different stat.
          widget = {
            cpu = {
              type = "sysmon";
              stat = "cpu_usage";
            };
            ram = {
              type = "sysmon";
              stat = "ram_used";
            };
            disk = {
              type = "sysmon";
              stat = "disk_used_pct";
              path = "/";
            };
            # enp2s0 is the bridged VMware interface set up in configuration.nix.
            netrx = {
              type = "sysmon";
              stat = "net_rx";
              interface = "enp2s0";
              network_speed_compact = true;
            };
            nettx = {
              type = "sysmon";
              stat = "net_tx";
              interface = "enp2s0";
              network_speed_compact = true;
            };
            clock = {
              type = "clock";
              format = "{:%Y-%m-%d %H:%M}";
              tooltip_format = "{:%A, %B %d, %Y}";
              actions.right = "panel-toggle ahacop/timezone-grid:panel";
            };
          };

          shell.launcher = {
            provider_prefix = "/";

            # A flat command palette reached with `/cmd`, or from the global
            # search because `global` is set. `command` prints the choices, one
            # per line; `exec` receives the picked line as {selection} and runs
            # detached, with no terminal attached.
            dmenu.entry.cmd = {
              label = "Commands";
              prefix = "/cmd";
              glyph = "terminal";
              global = true;
              command = "printf '%s\\n' 'Display: 1920x1080' 'Display: 7680x3200' 'Dictate: toggle'";
              exec = ''case "{selection}" in "Display: 1920x1080") niri msg output Virtual-1 mode 1920x1080@60.000 ;; "Display: 7680x3200") niri msg output Virtual-1 mode 7680x3200@60.000 ;; "Dictate: toggle") hyprwhspr record toggle ;; esac'';
            };

            # Removable drives to eject, reached with `/eject` or from the
            # global search. Each choice is a mount path such as
            # /run/media/ahacop/KOBOeReader. Picking one unmounts the drive
            # and powers it off, the same as `udiskie-umount --detach`.
            dmenu.entry.eject = {
              label = "Eject";
              prefix = "/eject";
              glyph = "usb";
              global = true;
              command = "${pkgs.udiskie}/bin/udiskie-info -a -f is_mounted -f is_external -o '{mount_path}'";
              exec = ''${pkgs.udiskie}/bin/udiskie-umount --detach "{selection}" && ${pkgs.libnotify}/bin/notify-send "Ejected {selection}"'';
            };
          };
        };
      };

      # Noctalia scans this directory for plugins that come from neither the
      # official nor the community repo.
      xdg.dataFile."noctalia/plugins/timezone-grid".source = ../../plugins/timezone-grid;
    };
}
