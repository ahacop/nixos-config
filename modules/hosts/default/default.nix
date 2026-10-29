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
      config.flake.modules.nixos.dictation
      config.flake.modules.nixos.niri
      config.flake.modules.nixos.dictionary
      config.flake.modules.nixos.printing
      config.flake.modules.nixos.vmware-guest
      config.flake.modules.nixos.theme
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user}.imports = [
            config.flake.modules.homeManager.home
            config.flake.modules.homeManager.dictation
            config.flake.modules.homeManager.nixvim
            config.flake.modules.homeManager.niri
            config.flake.modules.homeManager.noctalia
            config.flake.modules.homeManager.firefox
            config.flake.modules.homeManager.ghostty
            config.flake.modules.homeManager.dictionary
            config.flake.modules.homeManager.zsh
            config.flake.modules.homeManager.git
            config.flake.modules.homeManager.tmux
            config.flake.modules.homeManager.theme
            config.flake.modules.homeManager.llm-agents
          ];
        };
      }
    ];
  };
}
