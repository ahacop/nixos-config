# Writing prose: spell checkers, vale for style, pandoc for converting,
# glow for reading Markdown, and mermaid-cli for diagrams.
{
  flake.modules.nixos.writing =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        aspell
        aspellDicts.en
        glow
        hunspell
        mermaid-cli
        pandoc
        vale
      ];
    };
}
