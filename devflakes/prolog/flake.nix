{
  description = "A Nix-flake-based Prolog development environment";

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
      devShells = forAllSystems (
        pkgs:
        let
          # withGui pulls in XPCE, SWI-Prolog's native GUI toolkit, providing
          # the swipl-win graphical console, PceEmacs, the source-level
          # debugger and the graphical profiler/tracer.
          swiProlog = pkgs.swi-prolog.override { withGui = true; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              swiProlog
            ];
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
