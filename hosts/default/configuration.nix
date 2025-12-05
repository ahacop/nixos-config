# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  inputs,
  pkgs,
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
in
{
  stylix = {
    enable = true;
    image = config.lib.stylix.pixel "base00";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";

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

      sizes = {
        terminal = 24;
      };
    };
  };

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/vmware-guest.nix
  ];

  environment.localBinInPath = true;

  documentation.dev.enable = true;

  users.users.ahacop = {
    isNormalUser = true;
    home = "/home/ahacop";
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
    # use unstable nix so we can access flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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

    # Disable the firewall since we're in a VM and we want to make it
    # easy to visit stuff in here. We only use NAT networking anyways.
    firewall.enable = false;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # XDG desktop portal for applications like kitty
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  services = {
    # setup windowing environment
    displayManager.defaultSession = "none+i3";
    xserver = {
      enable = true;
      xkb.layout = "us";
      dpi = 110;

      displayManager = {
        lightdm.enable = true;

        # AARCH64: For now, on Apple Silicon, we must manually set the
        # display resolution. This is a known issue with VMware Fusion.
        sessionCommands = ''
          ${pkgs.xorg.xset}/bin/xset r rate 200 40
        '';
      };

      windowManager.i3 = {
        enable = true;
      };
    };

    # Enable desktop portal for applications like kitty
    dbus.enable = true;

    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
      settings.PermitRootLogin = "no";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    packages = with pkgs; [
      dejavu_fonts
      emacs-all-the-icons-fonts
      fira-code
      font-awesome
      ibm-plex
      inconsolata
      intel-one-mono
      jetbrains-mono
      meslo-lgs-nf
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.terminess-ttf
      ultimate-oldschool-pc-font-pack
    ];
  };

  nixpkgs.config.allowUnfree = true;
  environment = {
    sessionVariables = {
      FLAKE = "/home/ahacop/nixos-config";
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      _1password-cli
      aspell
      aspellDicts.en
      bat
      cachix
      coreutils
      dmenu
      fd
      feh
      ffmpeg
      git
      gnumake
      kitty
      mesa
      mesa-demos
      gnupg
      heroku
      htop
      hunspell
      i3
      i3status
      jpegoptim
      jq
      just
      killall
      man-pages
      man-pages-posix
      neofetch
      neovim
      nb
      nh
      nix-output-monitor
      nvd
      pandoc
      pinentry-curses
      ripgrep
      rxvt-unicode-unwrapped
      socat # used by nb
      sox
      sqlite
      tmux
      unzip
      w3m
      wget
      xclip
      xorg.xev
      xorg.xmodmap
      xsel
      xxd
      yt-dlp
      zip
      chromium
      fish
      gum
      (python313Packages.llm.withPlugins {
        llm-anthropic = true;
        llm-git = true;
        llm-templates-fabric = true;
        llm-sentence-transformers = true;
        llm-docs = true;
        llm-hacker-news = true;
        llm-fragments-github = true;
        llm-jq = true;
        llm-cmd = true;
        llm-tools-sqlite = true;
        llm-ollama = true;
        llm-gemini = true;
      })

      # For hypervisors that support auto-resizing, this script forces it.
      # I've noticed not everyone listens to the udev events so this is a hack.
      (writeShellScriptBin "xrandr-auto" ''
        xrandr --output Virtual-1 --auto
      '')

      # macOS notification bridge
      (writeShellScriptBin "notify-macos" ''
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

      # AI-powered git commit wrapper for Fish function
      (writeShellScriptBin "gc-ai" ''
        exec ${pkgs.fish}/bin/fish -c "gc-ai $*"
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

      gtkmm3
      # ] ++ lib.optionals (currentSystemName == "vm-aarch64") [
      #   # This is needed for the vmware user tools clipboard to work.
      #   # You can test if you don't need this by deleting this and seeing
      #   # if the clipboard sill works.
      #   gtkmm3
    ];
  };

  programs = {
    zsh.enable = true;
    ssh = {
      startAgent = true;
    };
  };

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking.interfaces.enp2s0.useDHCP = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

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

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with PipeWire
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
