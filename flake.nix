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
  in {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit user;
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
            };
          }
        ];
      };
    };
  };
}
