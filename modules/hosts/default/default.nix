# The personal VM under VMware Fusion: the ahacop profile on vmware-guest.
{ inputs, config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.default = {
    imports = [
      nixos.ahacop
      nixos.vmware-guest
    ];

    # The Makefile builds the configuration with this host's name, so the
    # hostname and the name of the nixosConfiguration must match.
    networking.hostName = "default";
  };

  flake.nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.default ];
  };
}
