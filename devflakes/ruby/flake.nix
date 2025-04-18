{
  description = "A Nix-flake-based Ruby development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-ruby,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # for ngrok
          overlays = [
            nixpkgs-ruby.overlays.default
          ];
        };
        isAarch64Linux = system == "aarch64-linux";
        mkScript = name: text: pkgs.writeShellScriptBin name text;

        # Define your scripts/aliases as executables
        scripts = [
          (mkScript "tigris-dev" ''aws s3api --profile tigris-changebot-monolith-development --bucket changebot-monolith-development --endpoint-url https://fly.storage.tigris.dev "$@"'')
          (mkScript "tigris-staging" ''aws s3api --profile tigris-changebot-monolith-staging --bucket changebot-monolith-staging --endpoint-url https://fly.storage.tigris.dev "$@"'')
          (mkScript "tigris-prod" ''aws s3api --profile tigris-changebot-monolith-production --bucket changebot-monolith-production --endpoint-url https://fly.storage.tigris.dev "$@"'')
          (mkScript "shad" ''bunx --bun shadcn@latest add "$@"'')
        ];
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              bun
              cf-terraforming
              clang
              cmake
              curl
              docker
              docker-compose
              flyctl
              geckodriver
              gmp
              gnumake
              hivemind
              libpcap
              libxml2
              libxslt
              libyaml
              ngrok
              nodejs
              openssl
              pkg-config
              pkgs."ruby-3.4.3"
              postgresql_17
              protobuf
              readline
              sqlite
              tailwindcss_4
              terraform
              vips
              watchman
            ]
            ++ scripts;

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.vips}/lib:$LD_LIBRARY_PATH
            VIPS_LIB_PATH=$(ldd $(which vips) | grep libvips.so | awk '{print $3}' | xargs dirname)
            export LD_LIBRARY_PATH=$VIPS_LIB_PATH:$LD_LIBRARY_PATH
            export TAILWINDCSS_INSTALL_DIR="${pkgs.tailwindcss_4}/bin"
          '';
        };
      }
    );
}
