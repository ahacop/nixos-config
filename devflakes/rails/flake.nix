{
  description = "A Nix-flake-based Rails development environment";

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
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "cloudflared"
                  "terraform"
                ];
              overlays = [ nixpkgs-ruby.overlays.default ];
            }
          )
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          rubyPkg = pkgs."ruby-4.0.4";
          mkScript = name: text: pkgs.writeShellScriptBin name text;
          scripts = [
            (mkScript "shad" ''bunx --bun shadcn@latest add "$@"'')
          ];
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                adr-tools
                bun
                cf-terraforming
                checkmake
                chromium
                chromedriver
                cloudflared
                cmake
                curl
                docker
                docker-compose
                flyctl
                gcc
                gmp
                gnumake
                hadolint
                hivemind
                just
                libxml2
                libxslt
                libyaml
                nodejs_24
                openssl
                pkg-config
                rubyPkg
                postgresql_18
                readline
                tailwindcss_4
                terraform
                trivy
                vips
              ]
              ++ scripts;

            shellHook = ''
              export PATH="${pkgs.lib.makeBinPath scripts}:$PATH"
              export LD_LIBRARY_PATH="${
                pkgs.lib.makeLibraryPath [
                  pkgs.vips
                  pkgs.gcc.cc.lib
                ]
              }:$LD_LIBRARY_PATH"
              export TAILWINDCSS_INSTALL_DIR="${pkgs.tailwindcss_4}/bin"
            '';
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
