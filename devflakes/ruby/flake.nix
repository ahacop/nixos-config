{
  description = "A Nix-flake-based Ruby development environment";

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
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ nixpkgs-ruby.overlays.default ];
            }
          )
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          rubyPkg = pkgs."ruby-4.0.5".override { docSupport = true; };
          mkScript = name: text: pkgs.writeShellScriptBin name text;
          gem-install-docs = mkScript "gem-install-docs" ''
            unset GEM_HOME
            gemdir=$(${rubyPkg}/bin/gem environment gemdir)
            echo "Generating ri docs for new gems..."
            ${rubyPkg}/bin/gem list --no-versions 2>/dev/null | while read -r name; do
              if ! ls "$gemdir/doc/$name"-* &>/dev/null; then
                ${rubyPkg}/bin/gem rdoc "$name" --ri --no-rdoc 2>/dev/null
              fi
            done
          '';
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bundler
              gem-install-docs
              gnumake
              libyaml
              openssl
              pkg-config
              rubyPkg
            ];
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
