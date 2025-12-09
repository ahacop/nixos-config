{
  description = "NixOS systems and tools by ahacop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    macos-notifier-bridge = {
      url = "github:ahacop/macos-notifier-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pgbox = {
      url = "github:ahacop/pgbox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mw-cli = {
      url = "github:ahacop/mw-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant = {
      url = "github:abenz1267/elephant";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      user = "ahacop";

      # Load Claude version info
      claudeVersionInfo = builtins.fromJSON (builtins.readFile ./claude-version.json);

      # Custom Claude derivation
      claude-code-latest =
        pkgs:
        pkgs.stdenv.mkDerivation rec {
          pname = "claude-code";
          inherit (claudeVersionInfo) version;

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
            inherit (claudeVersionInfo) sha256;
          };

          buildInputs = [ pkgs.nodejs ];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
            cp -r ./* $out/lib/node_modules/@anthropic-ai/claude-code/
            mkdir -p $out/bin
            ln -s $out/lib/node_modules/@anthropic-ai/claude-code/cli.js $out/bin/claude
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Claude Code - agentic coding tool";
            homepage = "https://github.com/anthropics/claude-code";
            license = licenses.unfree;
            maintainers = [ ];
            platforms = platforms.all;
          };
        };
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            inherit user;
            inherit claude-code-latest;
          };
          modules = [
            inputs.stylix.nixosModules.stylix
            ./hosts/default/configuration.nix
            {
              nixpkgs.overlays = [ inputs.niri.overlays.niri ];
            }
            home-manager.nixosModules.default
            {
              home-manager = {
                useUserPackages = true;
                users.ahacop = {
                  imports = [
                    ./hosts/default/home.nix
                    inputs.nixvim.homeModules.nixvim
                    inputs.niri.homeModules.niri
                    inputs.niri.homeModules.stylix
                    inputs.walker.homeManagerModules.default
                  ];
                };
                extraSpecialArgs = {
                  inherit claude-code-latest;
                  inherit inputs;
                };
              };
            }
          ];
        };
      };
    };
}
