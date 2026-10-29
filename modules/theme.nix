# Colors and fonts: stylix with the gruvbox scheme, the system fonts, and
# other base16 schemes and a font to switch to.
{ inputs, ... }:
{
  flake.modules.nixos.theme =
    { config, pkgs, ... }:
    let
      turboPascal = {
        base00 = "0000aa"; # Background (Blue)
        base01 = "0000cc"; # Lighter Background (Darker Blue)
        base02 = "0000ff"; # Selection Background (Light Blue)
        base03 = "5555ff"; # Comments, Invisibles, Line Highlighting (Lighter Cyan)
        base04 = "cccccc"; # Dark Foreground (Light Grey)
        base05 = "ffffff"; # Default Foreground, Caret, Delimiters, Operators (White)
        base06 = "ffff00"; # Light Foreground (Yellow for Keywords)
        base07 = "ff0000"; # Light Background (Red for Errors)
        base08 = "00ff00"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Green for Strings)
        base09 = "ffaa00"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Orange)
        base0A = "ffff55"; # Classes, Markup Bold, Search Text Background (Light Yellow)
        base0B = "55ff55"; # Strings, Inherited Class, Markup Code (Light Green)
        base0C = "55ffff"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Light Cyan)
        base0D = "5555ff"; # Functions, Methods, Attribute IDs, Headings (Light Blue)
        base0E = "ff55ff"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Pink)
        base0F = "d70000"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Lighter Red)
      };
      greenVT100 = {
        base00 = "001100"; # Background (Very Dark Green)
        base01 = "002200"; # Lighter Background (Dark Green)
        base02 = "003300"; # Selection Background (Dark Green)
        base03 = "004400"; # Comments, Invisibles, Line Highlighting (Medium Dark Green)
        base04 = "005500"; # Dark Foreground (Medium Green)
        base05 = "00aa00"; # Default Foreground, Caret, Delimiters, Operators (Bright Green)
        base06 = "00cc00"; # Light Foreground (Lighter Green)
        base07 = "00ff00"; # Light Background (Very Light Green)
        base08 = "00aa00"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Bright Green)
        base09 = "00aa00"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Bright Green)
        base0A = "00aa00"; # Classes, Markup Bold, Search Text Background (Bright Green)
        base0B = "00aa00"; # Strings, Inherited Class, Markup Code (Bright Green)
        base0C = "00aa00"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Bright Green)
        base0D = "00aa00"; # Functions, Methods, Attribute IDs, Headings (Bright Green)
        base0E = "00aa00"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Bright Green)
        base0F = "00aa00"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Bright Green)
      };
      blackAndWhite = {
        base00 = "000000"; # Background (Black)
        base01 = "1a1a1a"; # Lighter Background (Very Dark Grey)
        base02 = "333333"; # Selection Background (Dark Grey)
        base03 = "4d4d4d"; # Comments, Invisibles, Line Highlighting (Medium Dark Grey)
        base04 = "666666"; # Dark Foreground (Medium Grey)
        base05 = "b3b3b3"; # Default Foreground, Caret, Delimiters, Operators (Light Grey)
        base06 = "cccccc"; # Light Foreground (Lighter Grey)
        base07 = "ffffff"; # Light Background (White)
        base08 = "b3b3b3"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Inserted (Light Grey)
        base09 = "b3b3b3"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Light Grey)
        base0A = "b3b3b3"; # Classes, Markup Bold, Search Text Background (Light Grey)
        base0B = "b3b3b3"; # Strings, Inherited Class, Markup Code (Light Grey)
        base0C = "b3b3b3"; # Support, Regular Expressions, Escape Characters, Markup Quotes (Light Grey)
        base0D = "b3b3b3"; # Functions, Methods, Attribute IDs, Headings (Light Grey)
        base0E = "b3b3b3"; # Keywords, Storage, Selector, Markup Italic, Diff Changed (Light Grey)
        base0F = "b3b3b3"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Light Grey)
      };
      amberVT100 = {
        base00 = "110000";
        base01 = "220000";
        base02 = "330000";
        base03 = "440000";
        base04 = "550000";
        base05 = "aa5500";
        base06 = "cc5500";
        base07 = "ff5500";
        base08 = "aa5500";
        base09 = "aa5500";
        base0A = "aa5500";
        base0B = "aa5500";
        base0C = "aa5500";
        base0D = "aa5500";
        base0E = "aa5500";
        base0F = "aa5500";
      };
      ibmVGA = {
        package = pkgs.ultimate-oldschool-pc-font-pack;
        name = "PxPlus IBM VGA 9x14";
      };
    in
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        image = config.lib.stylix.pixel "base00";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";

        # The scheme above is dark, and targets that branch on polarity need to be
        # told. Left at the default "either", stylix hands noctalia
        # `theme.mode = "light"` while writing only a dark custom palette, so the
        # shell looks for a light palette that was never generated.
        polarity = "dark";

        # Stylix still sets the removed `services.kmscon.fonts` option; kmscon
        # isn't used here, so disable the target until stylix catches up.
        targets.kmscon.enable = false;

        fonts = {
          serif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Serif";
          };

          sansSerif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Sans";
          };

          monospace = {
            package = pkgs.intel-one-mono;
            name = "Intel One Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };

      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;

        packages = with pkgs; [
          dejavu_fonts
          fira-code
          font-awesome
          ibm-plex
          inconsolata
          intel-one-mono
          libertine
          libertinus
          meslo-lgs-nf
          nerd-fonts.jetbrains-mono
          nerd-fonts.terminess-ttf
          noto-fonts
          noto-fonts-color-emoji
          oldstandard
          sorts-mill-goudy
          source-sans
          source-serif
          tex-gyre.bonum
          ultimate-oldschool-pc-font-pack
        ];
      };
    };

  flake.modules.homeManager.theme = {
    # rofi is not enabled. The stylix rofi target still sets
    # `programs.rofi.font`, which home-manager renamed to
    # `programs.rofi.settings.font`, and that causes an evaluation warning.
    stylix.targets.rofi.enable = false;
  };
}
