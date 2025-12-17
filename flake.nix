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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    beads = {
      url = "github:steveyegge/beads/v0.30.2";
      inputs.nixpkgs.follows = "nixpkgs";
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
      bduiVersionInfo = builtins.fromJSON (builtins.readFile ./bdui-version.json);

      # Custom bdui derivation (TUI for beads issue tracker)
      bdui-latest =
        pkgs:
        let
          version = bduiVersionInfo.version;

          src = pkgs.fetchFromGitHub {
            owner = "assimelha";
            repo = "bdui";
            rev = "v${version}";
            inherit (bduiVersionInfo) hash;
          };

          # Fixed-output derivation to fetch bun dependencies
          bunDeps = pkgs.stdenv.mkDerivation {
            pname = "bdui-bun-deps";
            inherit version src;

            nativeBuildInputs = [ pkgs.bun pkgs.cacert ];

            buildPhase = ''
              export HOME=$TMPDIR
              export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
              bun install --frozen-lockfile
            '';

            installPhase = ''
              mkdir -p $out
              cp -r node_modules $out/
            '';

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = bduiVersionInfo.depsHash;
          };
        in
        pkgs.stdenv.mkDerivation {
          pname = "bdui";
          inherit version src;

          nativeBuildInputs = [ pkgs.bun pkgs.makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/bdui
            cp -r ./* $out/lib/bdui/
            cp -r ${bunDeps}/node_modules $out/lib/bdui/
            mkdir -p $out/bin
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/bdui \
              --add-flags "run $out/lib/bdui/src/index.tsx"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A beautiful TUI visualizer for the bd (beads) issue tracker";
            homepage = "https://github.com/assimelha/bdui";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.linux;
          };
        };

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
            inherit bdui-latest;
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
                  inherit bdui-latest;
                  inherit inputs;
                };
              };
            }
          ];
        };
      };
    };
}
