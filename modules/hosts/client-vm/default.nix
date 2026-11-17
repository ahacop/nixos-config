# The VM for client work. It starts with the same features as the
# personal VM (modules/hosts/default). To leave something out here, move it
# out of the shared base into a feature or into the other host's module; this
# file only adds.
{ inputs, config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.client-vm = {
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
    networking.hostName = "client-vm";

    # The NixOS release this machine was first installed with. It sets the
    # defaults for stateful data such as database formats. Do not change it on
    # upgrades.
    system.stateVersion = "26.11";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user}.imports = [ homeManager.client-vm ];
    };
  };

  flake.modules.homeManager.client-vm = {
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
    ];

    # The release home-manager was first used with on this machine. Do not
    # change it on upgrades.
    home.stateVersion = "26.11";
  };

  flake.nixosConfigurations.client-vm = inputs.nixpkgs.lib.nixosSystem {
    modules = [ nixos.client-vm ];
  };
}
