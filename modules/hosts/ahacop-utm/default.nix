# The personal VM under UTM: the ahacop profile on utm-guest.
{ inputs, config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.ahacop-utm = {
    imports = [
      nixos.ahacop
      nixos.utm-guest
    ];

    # The Makefile builds the configuration with this host's name, so the
    # hostname and the name of the nixosConfiguration must match.
    networking.hostName = "ahacop-utm";
  };

  flake.nixosConfigurations.ahacop-utm = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.ahacop-utm ];
  };
}
