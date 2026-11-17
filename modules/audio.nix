# Sound through PipeWire. The base imports this for every host.
{
  flake.modules.nixos.audio = {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      jack.enable = true;
    };
  };
}
