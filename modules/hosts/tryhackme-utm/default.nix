# The TryHackMe client-work VM under UTM: the tryhackme profile on utm-guest.
{ inputs, config, ... }:
let
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.tryhackme-utm = {
    imports = [
      nixos.tryhackme
      nixos.utm-guest
    ];

    # The Makefile builds the configuration with this host's name, so the
    # hostname and the name of the nixosConfiguration must match.
    networking.hostName = "tryhackme-utm";
  };

  flake.nixosConfigurations.tryhackme-utm = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.tryhackme-utm ];
  };
}
