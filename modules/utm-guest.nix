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

      # UTM gives the VM a virtio NIC that comes up as enp0s1.
      networking.interfaces.enp0s1.useDHCP = true;

      # Lets UTM shut the guest down cleanly and query its state.
      services.qemuGuest.enable = true;

      # SPICE agent: resizes the display to the UTM window and syncs the
      # clipboard with the Mac.
      services.spice-vdagentd.enable = true;

      # niri starts xwayland-satellite on demand when it is on PATH.
      environment.systemPackages = [ pkgs.xwayland-satellite ];
    };
}
