{
  config,
  lib,
  inputs,
  pkgs,
  user,
  ...
}:
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
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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

  networking = {
    # Define your hostname.
    hostName = "default";

    # networkd runs DHCP only on enp2s0, set below.
    useDHCP = false;

    # DHCP is done by systemd-networkd, not by dhcpcd, so that resolved below
    # gets every DNS server a network hands out. networkd keeps one list per
    # link holding the servers from all protocols, and resolved reads it
    # directly.
    #
    # dhcpcd instead reports to resolved one protocol at a time (enp2s0.dhcp,
    # enp2s0.ra), and resolved reads each report as the link's whole list, so
    # only the protocol that renewed last survives. A router handing out both
    # an IPv4 and an IPv6 resolver keeps just one of them. Drop the IPv4 one
    # and containers can resolve nothing, since they have no IPv6 address, and
    # `docker build` fails. The machine keeps working, because it has IPv6 and
    # FallbackDNS.
    #
    # Setting this turns dhcpcd off on its own.
    useNetworkd = true;

    # Interface is this on M1
    interfaces.enp2s0.useDHCP = true;

    # The firewall is off so anything listening in the VM is reachable without
    # opening ports one at a time. The VM is bridged onto the local network, so
    # that means every host on that network, not just the Mac running it.
    firewall.enable = false;
  };

  # Don't block boot or a rebuild waiting for a DHCP lease.
  systemd.network.wait-online.enable = false;

  # DNS. This VM roams between networks, so resolution goes through
  # systemd-resolved rather than a plain resolv.conf written from DHCP.
  #
  # - networkd hands every DHCP-provided resolver to resolved as this link's
  #   DNS. The VM is bridged, so those are the resolvers the local router hands
  #   out, and names that only the local network knows still resolve.
  # - Those resolvers vary in quality. A forwarder that answers an EDNS0 query
  #   with a broken packet takes glibc down with it, because glibc reads the
  #   broken answer as "no such name" and never tries another server. resolved
  #   probes each server and turns EDNS0 off per-server by itself, so one bad
  #   resolver does not cost us the others, and we do not have to disable EDNS0
  #   for the whole system.
  # - FallbackDNS is only used when a network hands out no DNS at all, so a
  #   network with no resolver still resolves names instead of going dark.
  # - resolv.conf points at the local stub at 127.0.0.53, which is always up, so
  #   the machine can always rebuild even when a network's DNS is misbehaving.
  #
  # We do not set networking.nameservers on purpose. Under resolved that becomes
  # a global DNS server and would compete with the link's own resolvers.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      # Router and hotspot forwarders often can't do DNSSEC. Leave validation
      # off so it does not break resolution behind them.
      DNSSEC = false;
    };
  };

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

    # mDNS/Bonjour so we can resolve the Mac host (and other peers) via *.local
    # without depending on the router's DNS or a fixed IP.
    avahi = {
      enable = true;
      nssmdns4 = true;
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
      xxd
      yt-dlp
      zip
      chromium
      gum

      # macOS notification bridge.
      (writeShellScriptBin "notify-macos" ''
        export MACOS_HOST_IP="''${MACOS_HOST_IP:-chunky-peanut-butter.local}"
        exec ${
          inputs.macos-notifier-bridge.packages.${pkgs.stdenv.hostPlatform.system}.notify-macos
        }/bin/notify-macos "$@"
      '')
      # Get macOS system sound based on current directory
      (writeShellApplication {
        name = "get-dir-sound";
        runtimeInputs = [ coreutils ];
        text = ''
          # Get the current directory name
          DIR_NAME=$(basename "$PWD")

          # List of available macOS system sounds
          SOUNDS=(
            "Basso"
            "Blow"
            "Bottle"
            "Frog"
            "Funk"
            "Glass"
            "Hero"
            "Morse"
            "Ping"
            "Pop"
            "Purr"
            "Sosumi"
            "Submarine"
            "Tink"
          )

          # Hash the directory name and map to a sound
          HASH=$(echo -n "$DIR_NAME" | sha256sum | cut -d' ' -f1)
          # Convert first 8 hex chars to decimal and modulo by number of sounds
          INDEX=$(( 0x''${HASH:0:8} % ''${#SOUNDS[@]} ))
          echo "''${SOUNDS[$INDEX]}"
        '';
      })

      # Copy latest screenshot(s) from Desktop to current directory
      (writeShellApplication {
        name = "copy-screenshot";
        runtimeInputs = [
          coreutils
          findutils
        ];
        text = ''
          DESKTOP_PATH="/host/ahacop/Desktop"
          NUM_SCREENSHOTS="''${1:-1}"

          # Validate the argument is a positive integer
          if ! [[ "$NUM_SCREENSHOTS" =~ ^[0-9]+$ ]] || [ "$NUM_SCREENSHOTS" -lt 1 ]; then
            echo "Error: Argument must be a positive integer" >&2
            echo "Usage: copy-screenshot [N]" >&2
            exit 1
          fi

          # Check if Desktop directory exists
          if [ ! -d "$DESKTOP_PATH" ]; then
            echo "Error: Desktop directory not found at $DESKTOP_PATH" >&2
            exit 1
          fi

          # Find screenshots and sort by modification time (newest first)
          # Screenshot filenames look like: "Screenshot 2025-11-30 at 5.31.47 PM.png"
          mapfile -t screenshots < <(find "$DESKTOP_PATH" -maxdepth 1 -type f -name "Screenshot *.png" -printf '%T@ %p\n' | sort -rn | head -n "$NUM_SCREENSHOTS" | cut -d' ' -f2-)

          # Check if any screenshots were found
          if [ ''${#screenshots[@]} -eq 0 ]; then
            echo "No screenshots found in $DESKTOP_PATH" >&2
            exit 1
          fi

          # Check if we found fewer screenshots than requested
          if [ ''${#screenshots[@]} -lt "$NUM_SCREENSHOTS" ]; then
            echo "Warning: Only found ''${#screenshots[@]} screenshot(s), requested $NUM_SCREENSHOTS" >&2
          fi

          # Copy each screenshot to current directory
          for screenshot in "''${screenshots[@]}"; do
            filename=$(basename "$screenshot")
            cp -v "$screenshot" "./$filename"
          done

          echo "Copied ''${#screenshots[@]} screenshot(s) to current directory"
        '';
      })

      asciinema
      dysk
      fzf
      nodejs
      (pkgs.python3Packages.buildPythonApplication rec {
        pname = "pgxnclient";
        version = "1.3.2";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-sDQ+BEuNAET/S+WF7M4BR7EAfbeuixJ0O/IidYpOx9k=";
        };

        postPatch = ''
          # Fix the setup.py to remove pytest-runner requirement
          substituteInPlace setup.py \
            --replace "setup_requires = ['pytest-runner']" "" \
            --replace "setup_requires" "# setup_requires"
        '';

        build-system = with pkgs.python3Packages; [
          setuptools
          wheel
        ];

        dependencies = with pkgs.python3Packages; [
          six
        ];

        meta = with lib; {
          description = "Command line client for the PostgreSQL Extension Network";
          homepage = "https://pgxn.org/";
          license = licenses.bsd3;
        };
      })
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

  # Mounts USB drives such as the Kobo. udiskie in home.nix mounts them
  # under /run/media/$USER on plug-in, where epubsync looks for the device.
  services.udisks2.enable = true;

  # The NixOS release this machine was first installed with. It sets the
  # defaults for stateful data such as database formats. Do not change it on
  # upgrades.
  system.stateVersion = "24.05";
}
