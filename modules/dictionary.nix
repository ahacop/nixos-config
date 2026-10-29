# Dictionaries: sdcv with Webster's 1913 for `define`, the local dictd
# server for `germ`, WordNet, and `thes` with the Moby thesaurus.
{
  flake.modules.nixos.dictionary =
    { pkgs, ... }:
    let
      # Moby Thesaurus - 30,000+ root words, 2.5 million synonyms
      moby-thesaurus = pkgs.stdenv.mkDerivation {
        pname = "moby-thesaurus";
        version = "1.0";

        src = pkgs.fetchurl {
          url = "https://www.gutenberg.org/files/3202/files/mthesaur.txt";
          sha256 = "sha256-fJdCse2UQ1qJPAcZtCZyXtuKUkL4xSanVGG9bO4t/TI=";
        };

        dontUnpack = true;

        installPhase = ''
          mkdir -p $out/share/moby
          cp $src $out/share/moby/mthesaur.txt
        '';
      };
    in
    {
      # Local dictionary server
      services.dictd = {
        enable = true;
        DBs = with pkgs.dictdDBs; [
          wordnet
          wiktionary
          eng2deu
          deu2eng
        ];
      };

      environment.systemPackages = with pkgs; [
        wordnet

        # Thesaurus using Moby Thesaurus (30k+ words, 2.5M synonyms)
        (writeShellApplication {
          name = "thes";
          runtimeInputs = [
            coreutils
            gnugrep
            util-linux
          ];
          text = ''
            if [ -z "''${1:-}" ]; then
              echo "Usage: thes <word>" >&2
              exit 1
            fi
            word="$1"
            # grep exits with status 1 when no line matches.
            result=$(grep -i -m 1 "^$word," ${moby-thesaurus}/share/moby/mthesaur.txt || true)
            if [ -z "$result" ]; then
              echo "No synonyms found for: $word" >&2
              exit 1
            fi
            # Print header then synonyms in columns
            echo "$result" | cut -d',' -f1
            echo "---"
            echo "$result" | cut -d',' -f2- | tr ',' '\n' | column
          '';
        })
      ];
    };

  flake.modules.homeManager.dictionary =
    { pkgs, ... }:
    let
      websters-1913-stardict = pkgs.stdenv.mkDerivation {
        pname = "websters-1913-stardict";
        version = "2.4.2";

        src = pkgs.fetchFromGitHub {
          owner = "ahacop";
          repo = "websters-dict-1913-stardict";
          rev = "7f9c6d6725eb1b0d8545a6f74904610fa2a2c71e";
          sha256 = "sha256-/g7Tm0tQzf7pkA6EzTMxOrh3FCr8CLxgRVsAp/ZxFpU=";
        };

        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];

        installPhase = ''
          mkdir -p $out/share/stardict/dic
          tar -xzf stardict-dictd-web1913-2.4.2.tgz -C $out/share/stardict/dic
        '';
      };
    in
    {
      home.packages = [
        pkgs.sdcv
        websters-1913-stardict
      ];

      programs.zsh.shellAliases = {
        define = "sdcv";
        germ = "dict -d fd-deu-eng";
      };

      programs.zsh.initContent = ''
        # StarDict dictionary path (set unconditionally for subshells)
        export STARDICT_DATA_DIR="${websters-1913-stardict}/share/stardict/dic"
      '';
    };
}
