{
  description = "A Nix-flake-based Ruby development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-ruby,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ nixpkgs-ruby.overlays.default ];
            }
          )
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pkgs."ruby-4.0.4"
            bundler
            gnumake
            libyaml
            openssl
            pkg-config
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
