# Containers: rootless Docker for the user. The base imports this for every
# host.
{
  flake.modules.nixos.containers = {
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
