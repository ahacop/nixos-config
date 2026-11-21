# Running as a UTM (QEMU) guest on the Mac: GL through virtio-gpu with virgl,
# the QEMU guest agent, and the SPICE agent for display resizing and
# clipboard. The UTM VM needs its display set to virtio-gpu-gl-pci.
{
  flake.modules.nixos.utm-guest =
    { pkgs, ... }:
    {
      # Hardware 3D acceleration through virgl. Mesa picks the virtio_gpu
      # driver on its own, so unlike vmware-guest nothing overrides the
      # loader.
      hardware.graphics.enable = true;

      guest = {
        # The virtio NIC comes up as enp0s1.
        networkInterface = "enp0s1";
        # QEMU's USB tablet and USB mouse share this ID. Only the mouse, which
        # UTM uses while it captures input, has the thumb buttons.
        mouseId = "0627:0001";
        # virgl tops out at OpenGL 4.1 with UTM's Apple Core OpenGL backend
        # and 2.1 with ANGLE, below the 4.3 Ghostty needs.
        openGL43 = false;
      };

      # Lets UTM shut the guest down cleanly and query its state.
      services.qemuGuest.enable = true;

      # SPICE agent: resizes the display to the UTM window and syncs the
      # clipboard with the Mac.
      services.spice-vdagentd.enable = true;

      # niri starts xwayland-satellite on demand when it is on PATH.
      environment.systemPackages = [ pkgs.xwayland-satellite ];
    };
}
