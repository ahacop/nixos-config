# The TryHackMe client-work profile: common plus nix-ld. The VMware host
# client-vm and the UTM host tryhackme-utm both run it.
{ config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.tryhackme = {
    imports = [
      nixos.common
      nixos.nix-ld
    ];

    # The NixOS release this machine was first installed with. It sets the
    # defaults for stateful data such as database formats. Do not change it on
    # upgrades.
    system.stateVersion = "26.11";

    home-manager.users.${user}.imports = [ homeManager.tryhackme ];
  };

  flake.modules.homeManager.tryhackme = {
    imports = [ homeManager.common ];

    # The release home-manager was first used with on this machine. Do not
    # change it on upgrades.
    home.stateVersion = "26.11";

    git.signingKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGZFrPt/m+IiEpwHAp/qpWmyPJVE5NcVlGpK3euexyx"
    ];
  };
}
