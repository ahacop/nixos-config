# SSH: the daemon and the key that may log in, the agent, and the client
# config. The base imports this for every host.
{ config, ... }:
let
  inherit (config) user;
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.ssh =
    { lib, ... }:
    {
      home-manager.sharedModules = [ homeManager.ssh ];

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
        settings.PermitRootLogin = "no";
      };

      users.users.${user}.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBV/HHQ0w3gMEOnwVvGUCnFJa8qlUCCAuLn26sNzRzk8 ahacop"
      ];

      programs.ssh.startAgent = true;

      # Disable GNOME's SSH agent to avoid conflict
      services.gnome.gnome-keyring.enable = lib.mkForce false;
    };

  flake.modules.homeManager.ssh = {
    home.file.".ssh/config".source = ../config/sshconfig;
  };
}
