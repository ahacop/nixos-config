{
  description = "NixOS systems and tools by ahacop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Supplies the kernel only. configuration.nix reads linuxPackages_latest
    # from this input. It follows nixpkgs, so the kernel is the newest one in
    # nixos-unstable. `make pin-kernel` replaces the next line with a fixed
    # nixpkgs rev, and `make unpin-kernel` puts this line back.
    nixpkgs-kernel.follows = "nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

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

    # erwindb and opdsview each declare their own rust-overlay. They both follow
    # this one so the lock holds a single copy, and so a single update here
    # moves both off any rust-overlay that trips nixpkgs deprecation warnings
    # during evaluation.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # aoc-cli keeps its own nixpkgs and rust-overlay. Its CI builds against
    # aoc-cli's own lock and pushes the result to ahacop.cachix.org, so the
    # store path here matches the cached one and nothing compiles locally.
    aoc-cli.url = "github:ahacop/aoc-cli";

    # erwindb keeps its own nixpkgs so that its store path changes only when
    # erwindb's own lock changes. No binary cache has erwindb, so a store path
    # change means a local compile from source.
    erwindb = {
      url = "github:ahacop/erwindb";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    opdsview = {
      url = "github:ahacop/opdsview";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # epub-sync keeps its own nixpkgs for the same reason as aoc-cli: its CI
    # pushes builds of its own lock to ahacop.cachix.org.
    epub-sync.url = "github:ahacop/epub-sync";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # llm-agents keeps its own nixpkgs pin on purpose. Numtide builds and
    # caches every agent CLI (codex is compiled from source) against that pin,
    # so following our nixpkgs would change the store paths, miss
    # cache.numtide.com, and compile codex locally whenever our nixpkgs moves
    # past theirs.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Patches open-vm-tools with a Wayland clipboard backend and runs the
    # vmtoolsd user daemon, so copy and paste works between the Mac and niri.
    # It patches our own open-vm-tools, so it follows our nixpkgs.
    clipway = {
      url = "github:krisztianfekete/clipway";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Every .nix file under modules/ is a flake-parts module, and import-tree
  # loads all of them. A file whose path has a part that starts with "_" is
  # not loaded, so a module can keep plain Nix helper files beside it.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
