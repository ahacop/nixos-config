{
  # `nix fmt` runs nixfmt, the same formatter nvim applies on save through
  # none-ls in home.nix, so both produce the same layout.
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt;
    };
}
