# User settings that every host gets and that no feature file in modules/
# holds. Settings for one host only go in that host's module in modules/hosts/.
{ inputs, ... }:
{
  flake.modules.homeManager.home =
    { pkgs, ... }:
    {
      programs = {
        yazi = {
          enable = true;
          enableZshIntegration = true;
          shellWrapperName = "y";
        };

        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };

        eza = {
          enable = true;
          enableZshIntegration = true;
          icons = "auto";
          git = true;
        };

        skim = {
          enable = true;
          enableZshIntegration = true;
        };

        starship = {
          enable = true;
          enableZshIntegration = true;

          settings = {
            command_timeout = 500;
            add_newline = false;
            # Only the modules named here run, in this order. Every language,
            # cloud and status module starship ships is left out.
            format = "$username$hostname$directory$git_branch$git_commit$git_state$git_status$package$cmd_duration$character";
          };
        };

        gpg.enable = true;
        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
      };

      xdg.enable = true;

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        };
      };

      home = {
        file = {
          ".ssh/config".source = ../../config/sshconfig;
        };

        packages = with pkgs; [
          devenv
          duckdb
          glow
          inputs.erwindb.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.mw-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
          mermaid-cli
          vale
          zathura
        ];
        sessionVariables = {
          PAGER = "less";
          # Read by every less invocation, not only the ones started through
          # PAGER. -X keeps the output on screen after less exits.
          LESS = "-FirSwX";
          # Ollama runs on the Mac host. Resolved via mDNS (avahi enabled in
          # configuration.nix) so it survives the host's IP changing.
          OLLAMA_HOST = "http://chunky-peanut-butter.local:11434";
        };
      };
    };
}
