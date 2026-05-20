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

    mw-cli = {
      url = "github:ahacop/mw-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aoc-cli = {
      url = "github:ahacop/aoc-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    erwindb = {
      url = "github:ahacop/erwindb";
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

    clipboard-txt-watcher = {
      url = "github:ahacop/clipboard-txt-watcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-overlay = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crit = {
      url = "github:tomasz-tomczyk/crit";
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
    in
    {
      templates = {
        ruby = {
          path = ./devflakes/ruby;
          description = "Ruby dev shell (pinned ruby + gem build deps)";
        };
        rails = {
          path = ./devflakes/rails;
          description = "Rails dev shell (ruby + postgres, node, vips, flyctl, etc.)";
        };
        rust = {
          path = ./devflakes/rust;
          description = "Rust dev shell (stable toolchain + clippy/rustfmt/rust-analyzer)";
        };
      };

      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs user; };
        modules = [
          ./hosts/default/configuration.nix
          inputs.stylix.nixosModules.stylix
          home-manager.nixosModules.default
          {
            nixpkgs.overlays = [
              inputs.niri.overlays.niri
              inputs.claude-code-overlay.overlays.default
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.${user}.imports = [
                ./hosts/default/home.nix
                inputs.nixvim.homeModules.nixvim
                inputs.niri.homeModules.niri
                inputs.niri.homeModules.stylix
                inputs.walker.homeManagerModules.default
                inputs.clipboard-txt-watcher.homeManagerModules.default
                inputs.hunk.homeManagerModules.default
              ];
            };
          }
        ];
      };
    };
}
