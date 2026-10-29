# tmux.
{
  flake.modules.homeManager.tmux =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        mouse = true;
        plugins = with pkgs.tmuxPlugins; [
          prefix-highlight
          sensible
          yank
        ];

        extraConfig = ''
          # Start windows and panes at 1, not 0
          set -g base-index 1
          set -g pane-base-index 1
          set-window-option -g pane-base-index 1
          set-option -g renumber-windows on

          # set vi-mode
          set-window-option -g mode-keys vi

          # keybindings
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

          # prefix ] pastes the Wayland clipboard, which clipway keeps in sync
          # with the Mac. It loads the clipboard into the tmux buffer first, so
          # text copied on the host pastes the same as text yanked in tmux.
          bind-key ] run-shell "wl-paste -n | tmux load-buffer - ; tmux paste-buffer -p"

          bind '"' split-window -v -c "#{pane_current_path}"
          bind % split-window -h -c "#{pane_current_path}"
          bind-key c new-window -c '#{pane_current_path}'

          bind-key C-x last-window

          # Move current window one position left
          bind-key < swap-window -t -1

          # Move current window one position right
          bind-key > swap-window -t +1

          # Allow window renaming by shell hooks
          set-option -g allow-rename on
          set-window-option -g automatic-rename off
        '';
      };
    };
}
