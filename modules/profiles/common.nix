# What every VM gets, whichever profile and emulator it runs: the base, the
# features both profiles share, and the home-manager wiring. A profile imports
# this and adds its own features; a host imports a profile and a guest feature.
{ inputs, config, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  flake.modules.nixos.common = {
    imports = [
      nixos.configuration
      inputs.home-manager.nixosModules.default

      # The emulator facts. The host's guest feature sets them.
      nixos.guest

      # Features with a NixOS part. A feature that also has a home-manager
      # part adds it to home-manager.sharedModules itself.
      nixos.dictation
      nixos.niri
      nixos.dictionary
      nixos.printing
      nixos.theme
      nixos.networking
      nixos.mac-host
      nixos.writing
      nixos.notes
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  flake.modules.homeManager.common = {
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
    ];
  };
}
