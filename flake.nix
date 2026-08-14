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

    # aoc-cli, erwindb and opdsview each declare their own rust-overlay. They all
    # follow this one so the lock holds a single copy, and so a single update
    # here moves all three off any rust-overlay that trips nixpkgs deprecation
    # warnings during evaluation.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aoc-cli = {
      url = "github:ahacop/aoc-cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    erwindb = {
      url = "github:ahacop/erwindb";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    opdsview = {
      url = "github:ahacop/opdsview";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
      system = "aarch64-linux";
      # Single source of truth for the LLM agent CLIs pulled from the numtide
      # llm-agents flake. Consumed by home.nix (to install them) and, via the
      # llmAgentBins output below, by the Makefile (to check versions) — so the
      # list lives in exactly one place.
      llmAgentNames = [
        "ccusage"
        "claude-code"
        "codex"
        "crit"
        "hunk"
        "pi"
      ];
      # The llm-agents.nix package set for our system, resolved once and shared
      # by the llmAgents output (for the Makefile) and home.nix (the installed
      # CLIs, passed in via extraSpecialArgs) so the flake owns all the wiring.
      llmAgentPkgs = inputs.llm-agents.packages.${system};
      llmAgentPackages = map (n: llmAgentPkgs.${n}) llmAgentNames;
    in
    {
      # Installed llm-agents CLIs as an attrset of package name -> main-program
      # (binary) name, e.g. { claude-code = "claude"; ... }, derived from
      # llmAgentNames via each package's meta.mainProgram. `make check-versions`
      # reads this to map packages to binaries and to know which packages to
      # look up upstream, so the tool list only lives in llmAgentNames above.
      llmAgents = builtins.listToAttrs (
        map (n: {
          name = n;
          value = llmAgentPkgs.${n}.meta.mainProgram or n;
        }) llmAgentNames
      );

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
        prolog = {
          path = ./devflakes/prolog;
          description = "Prolog dev shell (SWI-Prolog + GUI, prolog_ls, just)";
        };
        standardebooks = {
          path = ./devflakes/standardebooks;
          description = "Standard Ebooks (.envrc → use flake github:ahacop/standardebooks-nix)";
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
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs llmAgentPackages; };
              users.${user}.imports = [
                ./hosts/default/home.nix
                inputs.nixvim.homeModules.nixvim
                inputs.niri.homeModules.niri
                inputs.niri.homeModules.stylix
                inputs.walker.homeManagerModules.default
              ];
            };
          }
        ];
      };
    };
}
