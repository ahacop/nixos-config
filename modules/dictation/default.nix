# Dictation: speak, and the transcript is pasted into the focused window.
# Mod+Backslash or the top mouse thumb button starts and stops a recording.
{ config, inputs, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.dictation = {
    home-manager.sharedModules = [ homeManager.dictation ];

    # Mouse thumb buttons for dictation. The top thumb button (BTN_EXTRA)
    # presses Mod+Backslash, which niri binds to `hex dictation toggle`.
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
    { config, ... }:
    {
      imports = [ inputs.hex.homeManagerModules.hex ];

      programs.hex = {
        enable = true;
        autostart = true;
        model = "parakeet_unified_en";
        installModel = true;
        settings = {
          shortcut_mode = "toggle";
          sound_effects = false;
          paste_with_shift = true;
          transcription_device = "cpu";
        };
      };

      xdg.dataFile."hex/dot-scope.json".text = builtins.toJSON {
        processing = "sweep";
        processing_width = 60;
      };

      programs.niri.settings.binds."Mod+Backslash" = {
        action = config.lib.niri.actions.spawn "hex" "dictation" "toggle";
        repeat = false;
      };
    };
}
