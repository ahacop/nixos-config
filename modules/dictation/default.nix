# Dictation: speak, and the transcript is typed into the focused window.
# Mod+Backslash or the top mouse thumb button starts and stops a recording.
# The Noctalia bar shows the state through the noctwhspr widget, which the
# bar settings in modules/noctalia place.
{
  flake.modules.nixos.dictation = {
    # Mouse thumb buttons for dictation. The top thumb button (BTN_EXTRA)
    # presses Mod+Backslash, which niri binds to `hyprwhspr record toggle`.
    # The bottom thumb button (BTN_SIDE) presses Enter. Both buttons lose
    # their browser forward and back jobs. 0e0f:0003 is the virtual mouse
    # that VMware Fusion gives the VM; the m: prefix makes keyd treat it as
    # a mouse. keyd marks mouse support as experimental, so if the pointer
    # misbehaves, `sudo systemctl stop keyd` gives the mouse back.
    services.keyd = {
      enable = true;
      keyboards.mouse = {
        ids = [ "m:0e0f:0003" ];
        settings.main = {
          mouse2 = "M-backslash";
          mouse1 = "enter";
        };
      };
    };
  };

  flake.modules.homeManager.dictation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hyprwhspr = import ./_package.nix { inherit pkgs lib; };
    in
    {
      # The CLI, for `hyprwhspr status` and `hyprwhspr record toggle`. The
      # daemon is systemd.user.services.hyprwhspr below.
      home.packages = [ hyprwhspr ];

      # Starts or stops a hyprwhspr recording. hyprwhspr's own shortcuts
      # are off (external_bindings in its config.json), so niri owns the
      # key and the CLI passes the toggle to the running service.
      programs.niri.settings.binds."Mod+Backslash" = {
        action = config.lib.niri.actions.spawn "hyprwhspr" "record" "toggle";
        repeat = false;
      };

      xdg.dataFile."noctalia/plugins/noctwhspr".source = "${hyprwhspr}/share/noctalia/plugins/noctwhspr";

      # hyprwhspr reads only the keys that differ from its defaults. It writes
      # this file only when it migrates a legacy key, and none of these keys
      # is legacy, so the read-only link that home-manager makes is safe.
      xdg.configFile."hyprwhspr/config.json".text = builtins.toJSON {
        transcription_backend = "onnx-asr";
        onnx_asr_model = "nemo-parakeet-tdt-0.6b-v3";
        # niri binds Mod+Backslash to `hyprwhspr record toggle`. With this key
        # set, hyprwhspr does not read /dev/input, so the user needs no input
        # group.
        external_bindings = true;
        recording_mode = "toggle";
        # No start and stop sounds. In this VMware VM, any sound that plays
        # while the microphone is open stops the microphone for a few seconds,
        # so the start sound would cut off the first words.
        audio_feedback = false;
      };

      # The dictation daemon. It keeps the model in memory, listens for
      # `hyprwhspr record toggle`, and pastes the transcript into the focused
      # window with wl-copy and wtype. It picks Ctrl+Shift+V for terminals from
      # `niri msg focused-window`. While it records, it shows an overlay through
      # gtk4-layer-shell.
      systemd.user.services.hyprwhspr = {
        Unit = {
          Description = "hyprwhspr speech-to-text";
          Documentation = [ "https://github.com/goodroot/hyprwhspr" ];
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "pipewire.service"
            "wireplumber.service"
          ];
          Wants = [
            "pipewire.service"
            "wireplumber.service"
          ];
        };
        Service = {
          Type = "simple";
          ExecStart = lib.getExe hyprwhspr;
          Environment = [ "PYTHONUNBUFFERED=1" ];
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
