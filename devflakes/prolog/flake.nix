{
  description = "A Nix-flake-based Prolog development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
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
            }
          )
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          # The lsp_server pack provides a Language Server (completion,
          # go-to-definition, hover docs, diagnostics). It depends only on
          # standard SWI libraries, so it needs no extra packs alongside it.
          #
          # nixpkgs splits the JSON library out as an extension reachable only
          # as library(http/json), so the pack's bare library(json) imports
          # fail to resolve. Rewrite them to the prefixed path; both predicates
          # the pack uses (json_read_dict/3, atom_json_dict/3) live there.
          lspServerSrc = pkgs.runCommandLocal "lsp_server-3.16.3-patched" { } ''
            cp -r ${
              pkgs.fetchFromGitHub {
                owner = "jamesnvc";
                repo = "lsp_server";
                tag = "v3.16.3";
                hash = "sha256-u33P5bERXKn3rK/9fdir4naxzFHzjQzi43DGtaLVTnM=";
              }
            } $out
            chmod -R u+w $out
            substituteInPlace $out/prolog/lsp_server.pl $out/prolog/lsp_parser.pl \
              --replace-fail 'library(json)' 'library(http/json)'
          '';

          # withGui pulls in XPCE, SWI-Prolog's native GUI toolkit, providing
          # the swipl-win graphical console, PceEmacs, the source-level
          # debugger and the graphical profiler/tracer. extraPacks bakes the
          # LSP server into the build so `swipl` finds it without a network
          # install step.
          swiProlog = pkgs.swi-prolog.override {
            withGui = true;
            extraPacks = [ "'file://${lspServerSrc}'" ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              swiProlog
              pkgs.just
            ];
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
