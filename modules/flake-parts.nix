{ inputs, ... }:
{
  # Adds the flake.modules.<class>.<name> option. A feature file puts its
  # NixOS part in flake.modules.nixos.<name> and its home-manager part in
  # flake.modules.homeManager.<name>, and a host file picks features by name.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "aarch64-linux" ];
}
