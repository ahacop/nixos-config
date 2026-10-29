# User settings for this VM that no feature file in modules/ holds.
{ inputs, ... }:
{
  flake.modules.homeManager.home =
    { pkgs, ... }:
    {
      # Mounts a plugged-in USB drive under /run/media/$USER, where epubsync
      # looks for the Kobo. To eject, pick the device from the udiskie icon in
      # the bar tray, choose it under the `/eject` launcher prefix, or run
      # `udiskie-umount --detach /run/media/$USER/KOBOeReader`.
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        # The tray icon shows only while a removable device is present. Its
        # menu has Unmount, Eject and Detach entries per device.
        tray = "auto";
      };

      # Makes the udiskie unit pass --appindicator, so its tray icon is a
      # StatusNotifierItem that Noctalia's tray widget can show. The default
      # is an X11 status icon, which is invisible under Wayland.
      xsession.preferStatusNotifierItems = true;

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
          "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
        };
      };

      home = {
        file = {
          ".ssh/config".source = ../../../config/sshconfig;
        };

        stateVersion = "24.05";

        packages = with pkgs; [
          (calibre.override { speechSupport = false; })
          circumflex
          devenv
          duckdb
          foliate
          glow
          inputs.aoc-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.erwindb.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.mw-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.opdsview.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.epub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default
          mermaid-cli
          pomodoro
          presenterm
          udiskie # puts udiskie-umount and udiskie-info on the PATH; the daemon is services.udiskie above
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
