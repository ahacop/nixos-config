# The TryHackMe client-work VM under VMware Fusion: the tryhackme profile on vmware-guest.
{ inputs, config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.client-vm = {
    imports = [
      nixos.tryhackme
      nixos.vmware-guest
    ];

    # The Makefile builds the configuration with this host's name, so the
    # hostname and the name of the nixosConfiguration must match.
    networking.hostName = "client-vm";
  };

  flake.nixosConfigurations.client-vm = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.client-vm ];
  };
}
