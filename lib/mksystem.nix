# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{
  nixpkgs,
  inputs,
}: name: {
  system,
  user,
  darwin ? false,
}: let
  # The config files for this system.
  machineConfig = ../machines/${name}.nix;
  userOSConfig =
    ../users/${user}/${
      if darwin
      then "darwin"
      else "nixos"
    }.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # NixOS vs nix-darwin functionst
  systemFunc =
    if darwin
    then inputs.darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  home-manager =
    if darwin
    then inputs.home-manager.darwinModules
    else inputs.home-manager.nixosModules;
in
  systemFunc rec {
    inherit system;

    modules = [
      machineConfig
      userOSConfig
      home-manager.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [
              userHMConfig
              inputs.nixvim.homeManagerModules.nixvim
            ];
          };
        };
      }

      # We expose some extra arguments so that our modules can parameterize
      # better based on these values.
      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = name;
          currentSystemUser = user;
          inherit inputs;
        };
      }
    ];
  }
