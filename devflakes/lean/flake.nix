{
  description = "A Nix-flake-based Lean 4 development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
            }
          )
        );
    in
    {
      # The lean4 package gives the compiler, the standard library, and the
      # lake build tool. Lake also serves the language server: `lake serve` is
      # the command nvim runs for a Lean buffer.
      #
      # This flake pins the Lean version. A project that carries a
      # lean-toolchain file for another version does not get that version here,
      # and .olean files built elsewhere (a Mathlib cache, for example) only
      # load when their version matches. Run `lean --version` to see which
      # version the shell provides.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.lean4
            pkgs.just
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
