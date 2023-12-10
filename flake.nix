{
  description = "NixOS systems and tools by ahacop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    darwin,
    ...
  } @ inputs: let
    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
    };

    user = "ahacop";
  in {
    nixosConfigurations = {
      vm-aarch64 = mkSystem "vm-aarch64" {
        system = "aarch64-linux";
        inherit user;
      };

      vm-aarch64-prl = mkSystem "vm-aarch64-prl" {
        system = "aarch64-linux";
        inherit user;
      };

      vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
        system = "aarch64-linux";
        inherit user;
      };

      vm-intel = mkSystem "vm-intel" {
        system = "x86_64-linux";
        inherit user;
      };
    };

    darwinConfigurations.macbook-pro-m1 = mkSystem "macbook-pro-m1" {
      system = "aarch64-darwin";
      inherit user;
      darwin = true;
    };
  };
}
