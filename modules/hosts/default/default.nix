# The one VM. `make switch` and `make vm/switch` build it as
# nixosConfigurations.default.
{ inputs, config, ... }:
let
  inherit (config) user;
in
{
  flake.nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.configuration
      inputs.home-manager.nixosModules.default

      # Features with a NixOS part. A feature that also has a home-manager
      # part adds it to home-manager.sharedModules itself.
      config.flake.modules.nixos.dictation
      config.flake.modules.nixos.niri
      config.flake.modules.nixos.dictionary
      config.flake.modules.nixos.printing
      config.flake.modules.nixos.vmware-guest
      config.flake.modules.nixos.theme
      config.flake.modules.nixos.usb-drives
      config.flake.modules.nixos.networking
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user}.imports = [
            config.flake.modules.homeManager.home

            # Features with only a home-manager part.
            config.flake.modules.homeManager.nixvim
            config.flake.modules.homeManager.noctalia
            config.flake.modules.homeManager.firefox
            config.flake.modules.homeManager.ghostty
            config.flake.modules.homeManager.zsh
            config.flake.modules.homeManager.git
            config.flake.modules.homeManager.tmux
            config.flake.modules.homeManager.llm-agents
          ];
        };
      }
    ];
  };
}
