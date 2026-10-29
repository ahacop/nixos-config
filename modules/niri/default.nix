# Niri, the compositor: the system session, the user config with every key
# bind, and nirisnap for screenshots.
{ inputs, ... }:
{
  flake.modules.nixos.niri = {
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    # Enable Niri window manager
    programs.niri.enable = true;
  };

  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nirisnap = import ./_nirisnap.nix { inherit pkgs lib; };
    in
    {
      imports = [
        inputs.niri.homeModules.niri
        inputs.niri.homeModules.stylix
      ];

      home.packages = [ nirisnap ];

      # The home-manager niri module builds a niri of its own solely to run
      # `niri validate` over the config generated below. Point it at the package
      # the system actually runs so the config is checked against the compositor
      # that reads it, and only one niri gets built.
      programs.niri.package = pkgs.niri;

      programs.niri.settings = {
        # Environment variables
        environment = {
          QT_QPA_PLATFORM = "wayland";
          MOZ_ENABLE_WAYLAND = "1";
          NIXOS_OZONE_WL = "1";
        };

        # Output configuration
        outputs."Virtual-1" = {
          scale = 1.5;
        };

        input = {
          keyboard = {
            xkb = {
              layout = "us";
            };
            repeat-delay = 400;
            repeat-rate = 30;
            track-layout = "window";
          };

          touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
            click-method = "clickfinger";
          };

          mouse = {
            accel-speed = 0.0;
            accel-profile = "flat";
          };

          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "10%";
          };

          workspace-auto-back-and-forth = true;
        };

        cursor = {
          hide-when-typing = true;
        };

        # Layout configuration
        layout = {
          gaps = 0;

          # The desktop background: everything niri does not cover with a window
          # is painted this color. Noctalia's wallpaper is off, so nothing draws
          # on top of it.
          background-color = config.lib.stylix.colors.withHashtag.base00;
        };

        animations = {
          enable = true;
        };

        # niri --session exports WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP to
        # systemd and D-Bus on its own, so nothing here has to.
        spawn-at-startup = [
          { command = [ "noctalia" ]; }
        ];

        window-rules = [
          {
            matches = [
              {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              }
            ];
            open-floating = true;
          }

          # Dialogs and popups - floating by default
          {
            matches = [
              { title = "^Open File$"; }
              { title = "^Save File$"; }
              { title = "^Save As$"; }
            ];
            open-floating = true;
          }
        ];

        binds = with config.lib.niri.actions; {
          "Mod+Shift+Slash".action = show-hotkey-overlay;

          "Mod+Return".action = spawn "ghostty";

          # Noctalia surfaces. Every one is a toggle, so the same key closes it.
          "Mod+D".action = spawn-sh "noctalia msg panel-toggle launcher";
          "Mod+Space".action = spawn-sh "noctalia msg panel-toggle control-center";
          "Mod+Shift+C".action = spawn-sh "noctalia msg panel-toggle clipboard";
          "Mod+Shift+Comma".action = spawn-sh "noctalia msg settings-toggle";
          "Mod+Tab".action = spawn-sh "noctalia msg window-switcher";
          "Mod+Shift+Escape".action = spawn-sh "noctalia msg session lock";

          "XF86AudioRaiseVolume" = {
            action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            allow-when-locked = true;
          };
          "XF86AudioMicMute" = {
            action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            allow-when-locked = true;
          };

          "Mod+O" = {
            action = toggle-overview;
            repeat = false;
          };

          "Mod+W" = {
            action = close-window;
            repeat = false;
          };

          "Mod+Left".action = focus-column-left;
          "Mod+Down".action = focus-window-down;
          "Mod+Up".action = focus-window-up;
          "Mod+Right".action = focus-column-right;
          "Mod+H".action = focus-column-left;
          "Mod+J".action = focus-window-down;
          "Mod+K".action = focus-window-up;
          "Mod+L".action = focus-column-right;

          "Mod+Ctrl+Left".action = move-column-left;
          "Mod+Ctrl+Down".action = move-window-down;
          "Mod+Ctrl+Up".action = move-window-up;
          "Mod+Ctrl+Right".action = move-column-right;
          "Mod+Ctrl+H".action = move-column-left;
          "Mod+Ctrl+J".action = move-window-down;
          "Mod+Ctrl+K".action = move-window-up;
          "Mod+Ctrl+L".action = move-column-right;

          "Mod+Home".action = focus-column-first;
          "Mod+End".action = focus-column-last;
          "Mod+Ctrl+Home".action = move-column-to-first;
          "Mod+Ctrl+End".action = move-column-to-last;

          "Mod+Shift+Left".action = focus-monitor-left;
          "Mod+Shift+Down".action = focus-monitor-down;
          "Mod+Shift+Up".action = focus-monitor-up;
          "Mod+Shift+Right".action = focus-monitor-right;
          "Mod+Shift+H".action = focus-monitor-left;
          "Mod+Shift+J".action = focus-monitor-down;
          "Mod+Shift+K".action = focus-monitor-up;
          "Mod+Shift+L".action = focus-monitor-right;

          "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
          "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
          "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
          "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
          "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
          "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
          "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
          "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

          "Mod+BracketLeft".action = consume-or-expel-window-left;
          "Mod+BracketRight".action = consume-or-expel-window-right;

          "Mod+Comma".action = consume-window-into-column;
          "Mod+Period".action = expel-window-from-column;

          "Mod+R".action = switch-preset-column-width;
          "Mod+Shift+R".action = switch-preset-window-height;
          "Mod+Ctrl+R".action = reset-window-height;
          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;

          "Mod+Ctrl+F".action = expand-column-to-available-width;

          "Mod+C".action = center-column;
          "Mod+Ctrl+C".action = center-visible-columns;

          "Mod+Minus".action = set-column-width "-10%";
          "Mod+Equal".action = set-column-width "+10%";

          "Mod+Shift+Minus".action = set-window-height "-10%";
          "Mod+Shift+Equal".action = set-window-height "+10%";

          "Mod+V".action = toggle-window-floating;
          "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

          "Mod+Shift+W".action = toggle-column-tabbed-display;

          "Mod+Escape" = {
            action = toggle-keyboard-shortcuts-inhibit;
            allow-inhibiting = false;
          };

          "Mod+Shift+X".action = quit;

          # nirisnap has no window mode, so window capture stays on niri's
          # built-in screenshot action.
          "Mod+P".action = spawn "nirisnap";
          "Mod+Ctrl+P".action = spawn [
            "nirisnap"
            "--capture-fullscreen"
          ];
          "Mod+Alt+P".action.screenshot-window = [ ];

          "Mod+Shift+P".action = power-off-monitors;
        };
      };
    };
}
