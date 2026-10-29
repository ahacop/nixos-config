# The one VM. `make switch` and `make vm/switch` build it as
# nixosConfigurations.default.
{ inputs, config, ... }:
let
  user = "ahacop";
in
{
  flake.nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs user; };
    modules = [
      ../../hosts/default/configuration.nix
      inputs.stylix.nixosModules.stylix
      inputs.clipway.nixosModules.default
      inputs.home-manager.nixosModules.default
      config.flake.modules.nixos.dictation
      config.flake.modules.nixos.niri
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs user;
            inherit (config) llmAgentPackages;
          };
          users.${user}.imports = [
            ../../hosts/default/home.nix
            config.flake.modules.homeManager.dictation
            config.flake.modules.homeManager.nixvim
            config.flake.modules.homeManager.niri
            config.flake.modules.homeManager.noctalia
          ];
        };
      }
    ];
  };
}
