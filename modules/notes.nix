# Notes with nb. socat runs the local web server behind `nb browse`.
{
  flake.modules.nixos.notes =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nb
        socat
      ];
    };
}
