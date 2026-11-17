# The command-line tools for working on and administering these machines:
# processes, disks, the network, archives, media, man pages, the nix helpers
# and the everyday shell utilities. The base imports this for every host.
{ config, ... }:
let
  inherit (config) user;
in
{
  flake.modules.nixos.cli-tools =
    { pkgs, ... }:
    {
      documentation.dev.enable = true;

      # Where `nh os switch` finds this flake when run without a path.
      environment.sessionVariables.NH_FLAKE = "/home/${user}/nixos-config";

      # tmux and wl-clipboard are system packages on purpose: the tig binding
      # in modules/git.nix calls them by their /run/current-system/sw paths.
      environment.systemPackages = with pkgs; [
        _1password-cli
        bat
        bc
        bind.dnsutils # dig, nslookup, etc.
        btop
        cachix
        coreutils
        curl
        devenv
        duckdb
        duf
        dust
        dysk
        entr
        fastfetch
        fd
        ffmpeg
        file
        fzf
        git
        gnumake
        gnupg
        gum
        htop
        iproute2
        jpegoptim
        jq
        just
        killall
        lsof
        man-pages
        man-pages-posix
        mesa-demos
        ncdu
        netcat
        nh
        nix-output-monitor
        nmap
        nodejs
        nvd
        p7zip
        pciutils
        pinentry-curses
        procps
        ripgrep
        rsync
        sox
        sqlite
        strace
        tcpdump
        tig
        tldr
        tmux
        tree
        unzip
        usbutils
        w3m
        watch
        wdiff
        wget
        which
        wl-clipboard
        xxd
        zip
      ];
    };
}
