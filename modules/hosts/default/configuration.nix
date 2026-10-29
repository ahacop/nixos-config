# System settings for this VM that no feature file in modules/ holds.
{ inputs, config, ... }:
let
  inherit (config) user;
in
{
  flake.modules.nixos.configuration =
    { lib, pkgs, ... }:
    {
      imports = [
        # Include the results of the hardware scan.
        ./_hardware-configuration.nix
      ];

      environment.localBinInPath = true;

      documentation.dev.enable = true;

      users.users.${user} = {
        isNormalUser = true;
        home = "/home/${user}";
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        initialPassword = "password";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBV/HHQ0w3gMEOnwVvGUCnFJa8qlUCCAuLn26sNzRzk8 ahacop"
        ];
      };

      boot = {
        # From the nixpkgs-kernel input in flake.nix, which `make pin-kernel` can fix
        # to one nixpkgs rev.
        kernelPackages =
          inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_latest;
        loader = {
          # Use the systemd-boot EFI boot loader.
          systemd-boot.enable = true;
          systemd-boot.configurationLimit = 10;
          efi.canTouchEfiVariables = true;

          # VMware, Parallels both only support this being 0 otherwise you see
          # "error switching console mode" on boot.
          systemd-boot.consoleMode = "0";
        };

        tmp.cleanOnBoot = true;

        # Setup qemu so we can run x86_64 binaries
        binfmt.emulatedSystems = [ "x86_64-linux" ];
      };

      nix = {
        package = pkgs.nixVersions.latest;

        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Do not keep the build-time inputs of live outputs. That would hold
          # rustc, clang and rust-docs for every program built from source, and
          # nothing here runs them. nix-direnv roots each dev shell on its own,
          # with the shell's toolchain in that root, so shells still survive
          # `make clean`.
          keep-outputs = false;
          keep-derivations = true;
          substituters = [
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
            "https://ahacop.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            "ahacop.cachix.org-1:DNW02GubEpEM6HsOgAwIPDj81nPOuGxmCp4dvKzJOq0="
          ];
        };
      };

      # Define your hostname.
      networking.hostName = "default";

      # Set your time zone.
      time.timeZone = "Europe/Berlin";

      security.sudo.wheelNeedsPassword = false;

      # Virtualization settings
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      # Enable greetd with tuigreet
      services.greetd = {
        enable = true;
        settings = {
          default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --user-menu --cmd niri-session";
        };
      };

      # XDG desktop portal for Wayland
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        # Use GTK portal for everything (no GNOME dependencies)
        config.common.default = [ "gtk" ];
      };

      services = {
        # Enable the OpenSSH daemon.
        openssh = {
          enable = true;
          settings.PasswordAuthentication = true;
          settings.PermitRootLogin = "no";
        };
      };

      nixpkgs.config.allowUnfree = true;
      environment = {
        sessionVariables = {
          # Where `nh os switch` finds this flake when run without a path.
          NH_FLAKE = "/home/${user}/nixos-config";
        };

        # List packages installed in system profile. To search, run:
        # $ nix search wget
        systemPackages = with pkgs; [
          _1password-cli
          aspell
          aspellDicts.en
          bat
          bc
          bind.dnsutils # dig, nslookup, etc.
          btop
          cachix
          coreutils
          curl
          duf
          dust
          entr
          fd
          ffmpeg
          file
          git
          gnumake
          iproute2
          mesa-demos
          gnupg
          heroku
          htop
          hunspell
          jpegoptim
          jq
          just
          killall
          litemdview
          lsof
          man-pages
          man-pages-posix
          ncdu
          netcat
          fastfetch
          nb
          nh
          nix-output-monitor
          nmap
          nvd
          p7zip
          pandoc
          pciutils
          pinentry-curses
          procps
          ripgrep
          rsync
          socat # used by nb
          sox
          sqlite
          strace
          tcpdump
          tmux
          unzip
          usbutils
          w3m
          watch
          wdiff
          which
          wl-clipboard
          wget
          xxd
          yt-dlp
          zip
          chromium
          gum

          asciinema
          dysk
          fzf
          nodejs
          silicon
          tig
          tldr
          tree
        ];
      };

      programs = {
        zsh.enable = true;
        ssh = {
          startAgent = true;
        };
      };

      # Disable GNOME's SSH agent to avoid conflict
      services.gnome.gnome-keyring.enable = lib.mkForce false;

      # Enable sound with PipeWire
      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        jack.enable = true;
      };

      # Keep about three days of system logs. Journald writes roughly 13M a day
      # here and rotates in files of one eighth of SystemMaxUse, so 100M leaves
      # room for the retention window to be the limit that actually applies.
      services.journald.settings.Journal = {
        SystemMaxUse = "100M";
        MaxRetentionSec = "3day";
      };

      # The desktop modules turn speech-dispatcher on by default. Nothing here
      # uses it, and it pulls in espeak-ng and the mbrola voices, about 2.3G.
      services.speechd.enable = false;

      # The NixOS release this machine was first installed with. It sets the
      # defaults for stateful data such as database formats. Do not change it on
      # upgrades.
      system.stateVersion = "24.05";
    };
}
