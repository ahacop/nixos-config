{
  description = "NixOS systems and tools by ahacop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pin to nixpkgs with working 6.15.2 kernel
    nixpkgs-6152.url = "github:nixos/nixpkgs/ee930f9755f58096ac6e8ca94a1887e0534e2d81";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-6152,
    home-manager,
    ...
  } @ inputs: let
    user = "ahacop";

    # Load Claude version info
    claudeVersionInfo = builtins.fromJSON (builtins.readFile ./claude-version.json);

    # Custom Claude derivation
    claude-code-latest = pkgs: pkgs.stdenv.mkDerivation rec {
      pname = "claude-code";
      version = claudeVersionInfo.version;

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        sha256 = claudeVersionInfo.sha256;
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
        maintainers = [];
        platforms = platforms.all;
      };
    };
  in {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit user;
          claude-code-latest = claude-code-latest;
        };
        modules = [
          inputs.stylix.nixosModules.stylix
          ./hosts/default/configuration.nix
          home-manager.nixosModules.default
          {
            home-manager = {
              useUserPackages = true;
              users.ahacop = {
                imports = [
                  ./hosts/default/home.nix
                  inputs.nixvim.homeManagerModules.nixvim
                ];
              };
              extraSpecialArgs = {
                claude-code-latest = claude-code-latest;
              };
            };
          }
        ];
      };
    };
  };
}
