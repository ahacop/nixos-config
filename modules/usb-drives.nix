# USB drives such as the Kobo: udisks2 on the system, and udiskie, which
# mounts a drive when it is plugged in and shows it in the bar tray.
{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.usb-drives = {
    home-manager.sharedModules = [ homeManager.usb-drives ];

    # Mounts USB drives such as the Kobo. udiskie below mounts them under
    # /run/media/$USER on plug-in, where epubsync looks for the device.
    services.udisks2.enable = true;
  };

  flake.modules.homeManager.usb-drives =
    { pkgs, ... }:
    {
      # Mounts a plugged-in USB drive under /run/media/$USER, where epubsync
      # looks for the Kobo. To eject, pick the device from the udiskie icon in
      # the bar tray, choose it under the `/eject` launcher prefix, or run
      # `udiskie-umount --detach /run/media/$USER/KOBOeReader`.
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        # The tray icon shows only while a removable device is present. Its
        # menu has Unmount, Eject and Detach entries per device.
        tray = "auto";
      };

      # Makes the udiskie unit pass --appindicator, so its tray icon is a
      # StatusNotifierItem that Noctalia's tray widget can show. The default
      # is an X11 status icon, which is invisible under Wayland.
      xsession.preferStatusNotifierItems = true;

      # Puts udiskie-umount and udiskie-info on the PATH. The daemon is
      # services.udiskie above.
      home.packages = [ pkgs.udiskie ];
    };
}
