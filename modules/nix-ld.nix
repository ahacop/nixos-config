# nix-ld: runs prebuilt Linux binaries that expect a standard dynamic loader
# and /lib, such as the browsers `npx playwright install` downloads. Without
# it, /lib/ld-linux-aarch64.so.1 is a stub that refuses them. The libraries
# below are the ones Playwright's Chromium and headless shell load.
{
  flake.modules.nixos.nix-ld =
    { pkgs, ... }:
    {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          glib
          nss
          nspr
          dbus.lib
          expat
          cups.lib
          alsa-lib
          systemd
          libdrm
          libgbm
          mesa
          libxkbcommon
          atk
          at-spi2-atk
          at-spi2-core
          gtk3
          pango
          cairo
          freetype
          fontconfig
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxcb
        ];
      };
    };
}
