{config, ...}: {
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./vm-shared.nix
  ];

  networking.interfaces.enp0s1.useDHCP = true;

  # Qemu
  services.spice-vdagentd.enable = true;

  # For now, we need this since hardware acceleration does not work.
  environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
