# The personal profile: common plus USB drives and the ebook tools. The
# VMware host default and the UTM host ahacop-utm both run it.
{ config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.ahacop = {
    imports = [
      nixos.common
      nixos.usb-drives
    ];

    # The NixOS release this machine was first installed with. It sets the
    # defaults for stateful data such as database formats. Do not change it on
    # upgrades.
    system.stateVersion = "24.05";

    home-manager.users.${user}.imports = [ homeManager.ahacop ];
  };

  flake.modules.homeManager.ahacop = {
    imports = [
      homeManager.common
      homeManager.ebook-collecting
      homeManager.ebook-production
    ];

    # The release home-manager was first used with on this machine. Do not
    # change it on upgrades.
    home.stateVersion = "24.05";

    git.signingKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBV/HHQ0w3gMEOnwVvGUCnFJa8qlUCCAuLn26sNzRzk8"
    ];
  };
}
