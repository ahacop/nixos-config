# Ghostty, the terminal.
{
  flake.modules.homeManager.ghostty =
    { config, ... }:
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;
        # The systemd user service ghostty 1.3.1 ships exits immediately when it
        # can't become the primary instance (notify handshake never completes),
        # so it just fails. Single-instance mode below covers warm launches: the
        # first window owns the D-Bus name and later launches fork into it.
        systemd.enable = false;
        settings = {
          cursor-style = "block";
          font-size = 18;
          font-family = "Intel One Mono";
          window-decoration = "none";
          # Reuse the running process for new windows instead of cold-starting a
          # fresh GTK app on every Mod+Return.
          gtk-single-instance = true;
          # Ghostty has no setting for the height of the tab bar, so restyle
          # the libadwaita widget that draws it. See tabbar.css below.
          gtk-custom-css = "${config.xdg.configHome}/ghostty/tabbar.css";
          keybind = [
            "ctrl+equal=increase_font_size:1"
            "ctrl+minus=decrease_font_size:1"
            "ctrl+zero=reset_font_size"
            "shift+enter=text:\\x0a"
            # Ghostty binds next/previous tab but nothing to reorder them.
            # ctrl+shift+page_up/page_down, the browser keys for this, are
            # already jump_to_prompt.
            "ctrl+shift+alt+arrow_left=move_tab:-1"
            "ctrl+shift+alt+arrow_right=move_tab:1"

            # Tabs get the vim keys and left/right splits get the arrows that
            # Ghostty gives tabs by default, because tabs are used far more
            # than splits. ctrl+shift+j takes over from write_screen_file:paste.
            "ctrl+shift+h=previous_tab"
            "ctrl+shift+l=next_tab"
            "ctrl+shift+arrow_left=goto_split:left"
            "ctrl+shift+arrow_right=goto_split:right"
            "ctrl+shift+j=goto_split:down"
            "ctrl+shift+k=goto_split:up"

            # alt+<digit> is goto_tab:N by default and does nothing here, so
            # release the keys and let the program in the terminal have them.
            "alt+one=unbind"
            "alt+two=unbind"
            "alt+three=unbind"
            "alt+four=unbind"
            "alt+five=unbind"
            "alt+six=unbind"
            "alt+seven=unbind"
            "alt+eight=unbind"
            "alt+nine=unbind"

            # A modal scroll mode for the back buffer, with vim keys. Entered
            # with ctrl+shift+space, left with escape or q. Only moves the
            # view: Ghostty has no action that starts a selection from the
            # keyboard, so there is no v or y here. Use the mouse to copy.
            #
            # catch_all=ignore swallows every key the table does not bind.
            # Without it an unbound key reaches the shell, so a stray j lands
            # in the command line.
            "ctrl+shift+space=activate_key_table:scroll"
            "scroll/j=scroll_page_lines:1"
            "scroll/k=scroll_page_lines:-1"
            "scroll/d=scroll_page_fractional:0.5"
            "scroll/u=scroll_page_fractional:-0.5"
            "scroll/ctrl+f=scroll_page_down"
            "scroll/ctrl+b=scroll_page_up"
            "scroll/g>g=scroll_to_top"
            "scroll/shift+g=scroll_to_bottom"
            # Hop whole commands, using the shell integration prompt marks.
            "scroll/shift+left_bracket=jump_to_prompt:-1"
            "scroll/shift+right_bracket=jump_to_prompt:1"
            "scroll/slash=start_search"
            "scroll/escape=deactivate_key_table"
            "scroll/q=deactivate_key_table"
            "scroll/catch_all=ignore"
          ];
          bell-features = "system, attention";
        };
      };

      xdg.configFile."ghostty/tabbar.css".text = ''
        tabbar tabbox {
          min-height: 0;
          padding-top: 0;
          padding-bottom: 0;
        }

        tabbar tab {
          min-height: 0;
          padding-top: 0;
          padding-bottom: 0;
          font-size: 0.85em;
        }

        tabbar tab button.image-button {
          min-height: 12px;
          min-width: 12px;
        }

        tabbar .start-action,
        tabbar .end-action {
          padding-top: 0;
          padding-bottom: 0;
        }

        tabbar .box {
          min-height: 0;
          padding: 0;
        }
      '';
    };
}
