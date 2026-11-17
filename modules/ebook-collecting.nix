# Collecting ebooks: the Calibre library, opdsview for browsing OPDS
# catalogs, and epub-sync, which copies books to the Kobo. The usb-drives
# feature mounts the Kobo where epub-sync looks for it.
{ inputs, ... }:
{
  flake.modules.homeManager.ebook-collecting =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      home.packages = [
        (pkgs.calibre.override { speechSupport = false; })
        inputs.opdsview.packages.${system}.default
        inputs.epub-sync.packages.${system}.default
      ];
    };
}
