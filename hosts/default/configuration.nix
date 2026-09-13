{
  config,
  lib,
  inputs,
  pkgs,
  user,
  ...
}:
let
  turboPascal = {
    base00 = "0000aa"; # Background (Blue)
    base01 = "0000cc"; # Lighter Background (Darker Blue)
    base02 = "0000ff"; # Selection Background (Light Blue)
    base03 = "5555ff"; # Comments, Invisibles, Line Highlighting (Lighter Cyan)
    base04 = "cccccc"; # Dark Foreground (Light Grey)
    base05 = "ffffff"; # Default Foreground, Caret, Delimiters, Operators (White)
    base06 = "ffff00"; # Light Foreground (Yellow for Keywords)
    base07 = "ff0000"; # Light Background (Red for Errors)
    base08 = "00ff00"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Green for Strings)
    base09 = "ffaa00"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Orange)
    base0A = "ffff55"; # Classes, Markup Bold, Search Text Background (Light Yellow)
    base0B = "55ff55"; # Strings, Inherited Class, Markup Code (Light Green)
    base0C = "55ffff"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Light Cyan)
    base0D = "5555ff"; # Functions, Methods, Attribute IDs, Headings (Light Blue)
    base0E = "ff55ff"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Pink)
    base0F = "d70000"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Lighter Red)
  };
  greenVT100 = {
    base00 = "001100"; # Background (Very Dark Green)
    base01 = "002200"; # Lighter Background (Dark Green)
    base02 = "003300"; # Selection Background (Dark Green)
    base03 = "004400"; # Comments, Invisibles, Line Highlighting (Medium Dark Green)
    base04 = "005500"; # Dark Foreground (Medium Green)
    base05 = "00aa00"; # Default Foreground, Caret, Delimiters, Operators (Bright Green)
    base06 = "00cc00"; # Light Foreground (Lighter Green)
    base07 = "00ff00"; # Light Background (Very Light Green)
    base08 = "00aa00"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Bright Green)
    base09 = "00aa00"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Bright Green)
    base0A = "00aa00"; # Classes, Markup Bold, Search Text Background (Bright Green)
    base0B = "00aa00"; # Strings, Inherited Class, Markup Code (Bright Green)
    base0C = "00aa00"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Bright Green)
    base0D = "00aa00"; # Functions, Methods, Attribute IDs, Headings (Bright Green)
    base0E = "00aa00"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Bright Green)
    base0F = "00aa00"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Bright Green)
  };
  blackAndWhite = {
    base00 = "000000"; # Background (Black)
    base01 = "1a1a1a"; # Lighter Background (Very Dark Grey)
    base02 = "333333"; # Selection Background (Dark Grey)
    base03 = "4d4d4d"; # Comments, Invisibles, Line Highlighting (Medium Dark Grey)
    base04 = "666666"; # Dark Foreground (Medium Grey)
    base05 = "b3b3b3"; # Default Foreground, Caret, Delimiters, Operators (Light Grey)
    base06 = "cccccc"; # Light Foreground (Lighter Grey)
    base07 = "ffffff"; # Light Background (White)
    base08 = "b3b3b3"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Light Grey)
    base09 = "b3b3b3"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Light Grey)
    base0A = "b3b3b3"; # Classes, Markup Bold, Search Text Background (Light Grey)
    base0B = "b3b3b3"; # Strings, Inherited Class, Markup Code (Light Grey)
    base0C = "b3b3b3"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Light Grey)
    base0D = "b3b3b3"; # Functions, Methods, Attribute IDs, Headings (Light Grey)
    base0E = "b3b3b3"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Light Grey)
    base0F = "b3b3b3"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Light Grey)
  };
  amberVT100 = {
    base00 = "110000";
    base01 = "220000";
    base02 = "330000";
    base03 = "440000";
    base04 = "550000";
    base05 = "aa5500";
    base06 = "cc5500";
    base07 = "ff5500";
    base08 = "aa5500";
    base09 = "aa5500";
    base0A = "aa5500";
    base0B = "aa5500";
    base0C = "aa5500";
    base0D = "aa5500";
    base0E = "aa5500";
    base0F = "aa5500";
  };
  ibmVGA = {
    package = pkgs.ultimate-oldschool-pc-font-pack;
    name = "PxPlus IBM VGA 9x14";
  };

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
  stylix = {
    enable = true;
    image = config.lib.stylix.pixel "base00";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";

    # The scheme above is dark, and targets that branch on polarity need to be
    # told. Left at the default "either", stylix hands noctalia
    # `theme.mode = "light"` while writing only a dark custom palette, so the
    # shell looks for a light palette that was never generated.
    polarity = "dark";

    # Stylix still sets the removed `services.kmscon.fonts` option; kmscon
    # isn't used here, so disable the target until stylix catches up.
    targets.kmscon.enable = false;

    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.intel-one-mono;
        name = "Intel One Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  environment.localBinInPath = true;

  documentation.dev.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    extraGroups = [
      "docker"
      "wheel"
    ];
    shell = pkgs.zsh;
    initialPassword = "password";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBV/HHQ0w3gMEOnwVvGUCnFJa8qlUCCAuLn26sNzRzk8 ahacop"
    ];
  };

  boot = {
    # Use the latest kernel from nixpkgs
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;

      # VMware, Parallels both only support this being 0 otherwise you see
      # "error switching console mode" on boot.
      systemd-boot.consoleMode = "0";
    };
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

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
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

  # Hardware 3D acceleration for VMware. This installs the mesa drivers,
  # vmwgfx among them, under /run/opengl-driver, where the GL and Vulkan
  # loaders look for them.
  hardware.graphics = {
    enable = true;
    enable32Bit = false; # only available on x86
  };

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Enable Niri window manager
  programs.niri.enable = true;

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

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  services = {
    # Enable desktop portal for Wayland applications
    dbus.enable = true;

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

  users.mutableUsers = true;

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    packages = with pkgs; [
      dejavu_fonts
      fira-code
      font-awesome
      ibm-plex
      inconsolata
      intel-one-mono
      meslo-lgs-nf
      nerd-fonts.jetbrains-mono
      nerd-fonts.terminess-ttf
      noto-fonts
      noto-fonts-color-emoji
      source-sans
      source-serif
      ultimate-oldschool-pc-font-pack
    ];
  };

  nixpkgs.config.allowUnfree = true;
  environment = {
    sessionVariables = {
      # Where `nh os switch` finds this flake when run without a path.
      NH_FLAKE = "/home/${user}/nixos-config";
      # Force Mesa to use the VMware SVGA driver for hardware acceleration
      LIBGL_ALWAYS_SOFTWARE = "0";
      MESA_LOADER_DRIVER_OVERRIDE = "vmwgfx";
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
      (writeShellScriptBin "thes" ''
        if [ -z "$1" ]; then
          echo "Usage: thes <word>" >&2
          exit 1
        fi
        word="$1"
        result=$(${pkgs.gnugrep}/bin/grep -i "^$word," ${moby-thesaurus}/share/moby/mthesaur.txt | head -1)
        if [ -z "$result" ]; then
          echo "No synonyms found for: $word" >&2
          exit 1
        fi
        # Print header then synonyms in columns
        echo "$result" | cut -d',' -f1
        echo "---"
        echo "$result" | cut -d',' -f2- | tr ',' '\n' | ${pkgs.util-linux}/bin/column
      '')
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
      (writeShellScriptBin "get-dir-sound" ''
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
        HASH=$(echo -n "$DIR_NAME" | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)
        # Convert first 8 hex chars to decimal and modulo by number of sounds
        INDEX=$(( 0x''${HASH:0:8} % ''${#SOUNDS[@]} ))
        echo "''${SOUNDS[$INDEX]}"
      '')

      # Copy latest screenshot(s) from Desktop to current directory
      (writeShellScriptBin "copy-screenshot" ''
        set -euo pipefail

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
        mapfile -t screenshots < <(${pkgs.findutils}/bin/find "$DESKTOP_PATH" -maxdepth 1 -type f -name "Screenshot *.png" -printf '%T@ %p\n' | ${pkgs.coreutils}/bin/sort -rn | ${pkgs.coreutils}/bin/head -n "$NUM_SCREENSHOTS" | ${pkgs.coreutils}/bin/cut -d' ' -f2-)

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
          filename=$(${pkgs.coreutils}/bin/basename "$screenshot")
          ${pkgs.coreutils}/bin/cp -v "$screenshot" "./$filename"
        done

        echo "Copied ''${#screenshots[@]} screenshot(s) to current directory"
      '')

      # System utilities moved from home.nix
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

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Interface is this on M1
  networking.interfaces.enp2s0.useDHCP = true;

  # open-vm-tools: vmtoolsd for host integration, plus the vmhgfs-fuse helper
  # for the /host mount below. No X server is configured, so the module picks
  # the headless package, which leaves out vmware-user and the vmblock mount.
  # Both are X11-only and do nothing under niri. Clipboard sharing goes
  # through the /host file instead (sf/st in the launcher).
  virtualisation.vmware.guest.enable = true;

  # The /host HGFS mount uses `auto_unmount`, so the libfuse3 `vmhgfs-fuse`
  # daemon needs `fusermount3` (fuse3) at mount time, and `mount` needs
  # `mount.fuse` (fuse2) to handle the fuse.<helper> fstype. Nothing pulls
  # them in transitively. Without them the mount fails at boot and the
  # machine drops into emergency mode.
  system.fsPackages = [
    pkgs.fuse
    pkgs.fuse3
  ];

  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # Enable sound with PipeWire
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
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

  # Set volume to 60% on boot
  systemd.user.services.set-volume = {
    description = "Set audio volume to 60%";
    wantedBy = [ "default.target" ];
    after = [
      "pipewire.service"
      "pipewire-pulse.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ 60%";
      RemainAfterExit = true;
    };
  };

  # The NixOS release this machine was first installed with. It sets the
  # defaults for stateful data such as database formats. Do not change it on
  # upgrades.
  system.stateVersion = "24.05";
}
