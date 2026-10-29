# Firefox: the default profile, its add-ons from NUR, and the defaults that
# open web pages in it.
{ inputs, ... }:
{
  flake.modules.homeManager.firefox =
    { config, pkgs, ... }:
    let
      nur = import inputs.nur {
        inherit pkgs;
        nurpkgs = pkgs;
      };
    in
    {
      stylix.targets.firefox.profileNames = [ "default" ];

      programs.firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        profiles.default = {
          isDefault = true;
          search = {
            default = "ddg";
            force = true;
          };
          extensions.packages = with nur.repos.rycee.firefox-addons; [
            clearurls
            facebook-container
            ublock-origin
            vimium
          ];
          settings = {
            "extensions.autoDisableScopes" = 0;
            # Override inherited Wayland DPR (niri output scale = 1.5) so more
            # content fits at Firefox 100% zoom. Lower = smaller (1.0 ≈ standard DPI).
            "layout.css.devicePixelRatio" = "1.25";
            # Video decode: software only (VMware GPU has no VA-API)
            "media.ffmpeg.vaapi.enabled" = false;
            "media.ffvpx.enabled" = true;
            "media.av1.enabled" = false; # AV1 software decode is very CPU heavy
            "media.hardware-video-decoding.enabled" = false;
            # WebRender: use GPU acceleration (OpenGL 4.3 is available)
            "gfx.webrender.all" = true;
            "gfx.webrender.compositor" = true;
            "layers.acceleration.force-enabled" = true;
            # Wayland native
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            # Smooth scrolling
            "general.smoothScroll" = true;
            # Disable bloat
            "extensions.pocket.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          };
        };
      };

      xdg.mimeApps.defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
      };
    };
}
