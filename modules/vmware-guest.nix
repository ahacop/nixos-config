# Running as a VMware Fusion guest on the Mac: GL through the VMware SVGA
# driver, open-vm-tools, clipboard sync with the Mac, and the Mac's shared
# folders at /host.
{ inputs, ... }:
{
  flake.modules.nixos.vmware-guest =
    { config, pkgs, ... }:
    {
      imports = [ inputs.clipway.nixosModules.default ];

      # Hardware 3D acceleration for VMware. This installs the mesa drivers,
      # vmwgfx among them, under /run/opengl-driver, where the GL and Vulkan
      # loaders look for them.
      hardware.graphics.enable = true;

      environment.sessionVariables = {
        # Force Mesa to use the VMware SVGA driver for hardware acceleration
        LIBGL_ALWAYS_SOFTWARE = "0";
        MESA_LOADER_DRIVER_OVERRIDE = "vmwgfx";
      };

      # clipway's vmtoolsd -n vmusr starts GTK on X11 and exits with "cannot
      # open display" when DISPLAY is not set. niri starts xwayland-satellite
      # on demand when it is on PATH, and sets DISPLAY.
      environment.systemPackages = [ pkgs.xwayland-satellite ];

      # open-vm-tools: vmtoolsd for host integration, plus the vmhgfs-fuse binary
      # that the host-share service below uses to mount /host. No X server is
      # configured, so the module picks the headless package, which leaves out
      # vmware-user and the vmblock mount. Both are X11-only and do nothing under
      # niri.
      virtualisation.vmware.guest.enable = true;

      # clipway: host/guest clipboard sync under niri. It patches open-vm-tools
      # with a Wayland backend and runs `vmtoolsd -n vmusr` as a user service.
      # niri.service binds graphical-session.target, so the daemon starts with
      # the session. It syncs plain text only. If the clipboard does not sync,
      # set `virtualisation.vmware.guest.headless = false`.
      services.clipway = {
        enable = true;
        target = "graphical-session.target";
      };

      # Mounts the Mac's VMware shared folders at /host. A systemd service runs
      # `vmhgfs-fuse` directly in the foreground, so the mount needs no mount
      # helper. A fileSystems entry of type fuse.<helper> needs the fuse 2
      # `mount.fuse` helper, and nixpkgs no longer has fuse 2. A failed mount
      # here only fails this service, so boot continues.
      #
      # `auto_unmount` makes libfuse3 call the setuid `fusermount3` wrapper, which
      # removes the mount if the daemon dies. Without it a crash leaves a dead
      # mount at /host, and the restart cannot mount over it. `programs.fuse`
      # installs that wrapper at /run/wrappers/bin/fusermount3.
      programs.fuse.enable = true;
      systemd.services.host-share = {
        description = "VMware shared folders at /host";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /host";
          ExecStart = "${config.virtualisation.vmware.guest.package}/bin/vmhgfs-fuse .host:/ /host -f -o allow_other,auto_unmount,uid=1000,gid=100,umask=22";
          ExecStop = "${pkgs.util-linux}/bin/umount /host";
          Restart = "on-failure";
        };
      };
    };
}
