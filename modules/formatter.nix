{
  # `nix fmt` with no arguments formats every Nix file in the repo. It runs
  # nixfmt through treefmt. nvim applies the same nixfmt on save through
  # none-ls in modules/nixvim, so both produce the same layout.
  #
  # hardware-configuration.nix is left as nixos-generate-config wrote it, so
  # it can be compared with the file that a new install generates.
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree.override {
        settings.global.excludes = [ "modules/hosts/default/_hardware-configuration.nix" ];
      };
    };
}
