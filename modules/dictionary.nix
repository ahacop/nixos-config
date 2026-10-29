# Dictionaries: sdcv with Webster's 1913 for `define`, and the local dictd
# server for `germ`.
{
  flake.modules.nixos.dictionary =
    { pkgs, ... }:
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
