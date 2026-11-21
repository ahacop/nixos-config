# Facts about the emulator a VM runs under. Common imports this, each guest
# feature (vmware-guest, utm-guest) sets every option, and the features that
# depend on the emulator read them instead of naming VMware or UTM. A
# home-manager part reads them as osConfig.guest.
{
  flake.modules.nixos.guest =
    { lib, ... }:
    {
      options.guest = {
        networkInterface = lib.mkOption {
          type = lib.types.str;
          example = "enp2s0";
          description = "Name of the emulated network interface that gets DHCP.";
        };

        mouseId = lib.mkOption {
          type = lib.types.str;
          example = "0e0f:0003";
          description = "USB vendor:product of the emulator's virtual mouse, as keyd matches it.";
        };

        display = {
          scale = lib.mkOption {
            type = lib.types.float;
            example = 1.5;
            description = "niri's scale for the emulator's display.";
          };

          mode = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  width = lib.mkOption { type = lib.types.int; };
                  height = lib.mkOption { type = lib.types.int; };
                };
              }
            );
            default = null;
            description = ''
              A fixed resolution for the display, for an emulator that can't
              resize it to fit its window. Null lets niri take the preferred
              mode, which follows the window when the emulator resizes it.
            '';
          };
        };

        openGL43 = lib.mkOption {
          type = lib.types.bool;
          description = ''
            Whether the guest GPU offers desktop OpenGL 4.3 or newer. Ghostty
            needs it, and falls back to software rendering when it is missing.
          '';
        };
      };
    };
}
