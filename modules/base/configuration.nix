# The system itself, which every host gets: boot, nix, the user, time and
# logging. It also imports the features every host gets. Settings for one
# host only go in that host's module in modules/hosts/.
{ inputs, config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) nixos;
in
{
  flake.modules.nixos.configuration =
    { pkgs, ... }:
    {
      imports = [
        # Include the results of the hardware scan.
        ./_hardware-configuration.nix

        nixos.audio
        nixos.cli-tools
        nixos.containers
        nixos.ssh
      ];

      environment.localBinInPath = true;

      users.users.${user} = {
        isNormalUser = true;
        home = "/home/${user}";
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        initialPassword = "password";
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

      # Set your time zone.
      time.timeZone = "Europe/Berlin";

      security.sudo.wheelNeedsPassword = false;

      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = [ pkgs.chromium ];

      programs.zsh.enable = true;

      # Keep about three days of system logs. Journald writes roughly 13M a day
      # here and rotates in files of one eighth of SystemMaxUse, so 100M leaves
      # room for the retention window to be the limit that actually applies.
      services.journald.settings.Journal = {
        SystemMaxUse = "100M";
        MaxRetentionSec = "3day";
      };

      services.sysstat.enable = true;

      # The desktop modules turn speech-dispatcher on by default. Nothing here
      # uses it, and it pulls in espeak-ng and the mbrola voices, about 2.3G.
      services.speechd.enable = false;
    };
}
