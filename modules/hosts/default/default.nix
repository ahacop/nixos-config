# The personal VM. A host is a named module like a feature: nixos.default
# imports the shared base and the features this VM gets and sets what only this
# VM has, and homeManager.default does the same for the user.
# nixosConfigurations.default is built from nixos.default alone.
{ inputs, config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.default = {
    imports = [
      nixos.configuration
      inputs.home-manager.nixosModules.default

      # Features with a NixOS part. A feature that also has a home-manager
      # part adds it to home-manager.sharedModules itself.
      nixos.dictation
      nixos.niri
      nixos.dictionary
      nixos.printing
      nixos.vmware-guest
      nixos.theme
      nixos.usb-drives
      nixos.networking
      nixos.mac-host
    ];

    # The Makefile builds the configuration with this host's name, so the
    # hostname and the name of the nixosConfiguration must match.
    networking.hostName = "default";

    # The NixOS release this machine was first installed with. It sets the
    # defaults for stateful data such as database formats. Do not change it on
    # upgrades.
    system.stateVersion = "24.05";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user}.imports = [ homeManager.default ];
    };
  };

  flake.modules.homeManager.default = {
    imports = [
      homeManager.home

      # Features with only a home-manager part.
      homeManager.nixvim
      homeManager.noctalia
      homeManager.firefox
      homeManager.ghostty
      homeManager.zsh
      homeManager.git
      homeManager.tmux
      homeManager.llm-agents
      homeManager.ebook-reading
      homeManager.ebook-collecting
      homeManager.ebook-production
    ];

    # The release home-manager was first used with on this machine. Do not
    # change it on upgrades.
    home.stateVersion = "24.05";
  };

  flake.nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.default ];
  };
}
