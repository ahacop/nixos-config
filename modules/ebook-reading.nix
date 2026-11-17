# Reading ebooks: Foliate, and epub files open in it.
{
  flake.modules.homeManager.ebook-reading =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.foliate ];

      xdg.mimeApps.defaultApplications."application/epub+zip" = [
        "com.github.johnfactotum.Foliate.desktop"
      ];
    };
}
