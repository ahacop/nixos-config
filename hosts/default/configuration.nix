# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  stylix = {
    image = config.lib.stylix.pixel "base01";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";

    cursor = {size = 64;};

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
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {terminal = 24;};
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
    extraGroups = ["docker" "wheel"];
    shell = pkgs.zsh;
    initialPassword = "password";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBV/HHQ0w3gMEOnwVvGUCnFJa8qlUCCAuLn26sNzRzk8 ahacop"
    ];
  };

  boot = {
    # Be careful updating this.
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;

      # VMware, Parallels both only support this being 0 otherwise you see
      # "error switching console mode" on boot.
      systemd-boot.consoleMode = "0";
    };
  };

  nix = {
    # use unstable nix so we can access flakes
    package = pkgs.nixVersions.git;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      substituters = ["https://nix-community.cachix.org"];
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
  i18n = {defaultLocale = "en_US.UTF-8";};
  services = {
    # setup windowing environment
    displayManager.defaultSession = "none+i3";
    xserver = {
      enable = true;
      xkb.layout = "us";
      dpi = 220;

      displayManager = {
        lightdm.enable = true;

        # AARCH64: For now, on Apple Silicon, we must manually set the
        # display resolution. This is a known issue with VMware Fusion.
        sessionCommands = ''
          ${pkgs.xorg.xset}/bin/xset r rate 200 40
        '';
      };

      windowManager.i3 = {enable = true;};
    };

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
    fontconfig.defaultFonts.monospace = ["Intel One Mono"];
    fontDir.enable = true;
    enableGhostscriptFonts = true;

    packages = with pkgs; [
      dejavu_fonts
      emacs-all-the-icons-fonts
      fira-code
      font-awesome
      ibm-plex
      intel-one-mono
      inconsolata
      jetbrains-mono
      joypixels
      noto-fonts
      noto-fonts-emoji
      meslo-lgs-nf
    ];
  };

  environment = {
    sessionVariables = {FLAKE = "/home/ahacop/nixos-config";};

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      alacritty
      aspell
      aspellDicts.en
      bat
      cachix
      coreutils
      dmenu
      fd
      ffmpeg
      firefox
      git
      gnumake
      gnupg
      heroku
      htop
      hunspell
      i3
      i3status
      jpegoptim
      jq
      killall
      man-pages
      man-pages-posix
      neofetch
      neovim
      nh
      nix-output-monitor
      nvd
      pandoc
      pinentry
      ripgrep
      rxvt_unicode
      sqlite
      tmux
      unrar
      unzip
      wget
      xclip
      xorg.xev
      xorg.xmodmap
      xsel
      yt-dlp
      zip

      # For hypervisors that support auto-resizing, this script forces it.
      # I've noticed not everyone listens to the udev events so this is a hack.
      (writeShellScriptBin "xrandr-auto" ''
        xrandr --output Virtual-1 --auto
      '')

      gtkmm3
      # ] ++ lib.optionals (currentSystemName == "vm-aarch64") [
      #   # This is needed for the vmware user tools clipboard to work.
      #   # You can test if you don't need this by deleting this and seeing
      #   # if the clipboard sill works.
      #   gtkmm3

      (pkgs.emacsWithPackagesFromUsePackage {
        # Your Emacs config file. Org mode babel files are also
        # supported.
        # NB: Config files cannot contain unicode characters, since
        #     they're being parsed in nix, which lacks unicode
        #     support.
        config = ./emacs.org;

        # Whether to include your config as a default init file.
        # If being bool, the value of config is used.
        # Its value can also be a derivation like this if you want to do some
        # substitution:
        #   defaultInitFile = pkgs.substituteAll {
        #     name = "default.el";
        #     src = ./emacs.el;
        #     inherit (config.xdg) configHome dataHome;
        #   };
        defaultInitFile = true;

        # Package is optional, defaults to pkgs.emacs
        # package = pkgs.emacs-unstable;

        # By default emacsWithPackagesFromUsePackage will only pull in
        # packages with `:ensure`, `:ensure t` or `:ensure <package name>`.
        # Setting `alwaysEnsure` to `true` emulates `use-package-always-ensure`
        # and pulls in all use-package references not explicitly disabled via
        # `:ensure nil` or `:disabled`.
        # Note that this is NOT recommended unless you've actually set
        # `use-package-always-ensure` to `t` in your config.
        alwaysEnsure = false;

        # For Org mode babel files, by default only code blocks with
        # `:tangle yes` are considered. Setting `alwaysTangle` to `true`
        # will include all code blocks missing the `:tangle` argument,
        # defaulting it to `yes`.
        # Note that this is NOT recommended unless you have something like
        # `#+PROPERTY: header-args:emacs-lisp :tangle yes` in your config,
        # which defaults `:tangle` to `yes`.
        alwaysTangle = true;

        # Optionally provide extra packages not in the configuration file.
        # extraEmacsPackages = epkgs: [
        #   epkgs.cask
        # ];

        # Optionally override derivations.
        # override = final: prev: {
        #   weechat = prev.melpaPackages.weechat.overrideAttrs (old: {
        #     patches = [./weechat-el.patch];
        #   });
        # };
      })
    ];
  };

  programs = {
    zsh.enable = true;
    ssh = {startAgent = true;};
  };

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = ["virtualisation/vmware-guest.nix"];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;
  nixpkgs = {
    overlays = [inputs.emacs-overlay.overlays.default];
    config = {
      # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
      allowUnfree = true;
      allowUnsupportedSystem = true;
      joypixels.acceptLicense = true;
    };
  };

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

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

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
