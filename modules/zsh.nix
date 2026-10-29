# zsh, the login shell.
{
  flake.modules.homeManager.zsh =
    { config, pkgs, ... }:
    let
      just-completions = pkgs.runCommand "just-zsh-completions" { } ''
        mkdir -p $out
        JUST_COMPLETE=zsh ${pkgs.just}/bin/just > $out/_just
      '';
    in
    {
      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        defaultKeymap = "emacs";
        enableCompletion = true;
        completionInit = "autoload -U compinit && compinit -i";
        autosuggestion.enable = true;
        plugins = [
          {
            name = "zsh-completion-sync";
            src = "${pkgs.zsh-completion-sync}/share/zsh-completion-sync";
          }
        ];
        shellAliases = {
          cc = "claude";
          br = "bin/rubocop -A";
          bt = "bin/rails test";
          bs = "bin/rails test:system";
          bc = "bin/rails c";
          be = "bundle exec";
          bo = "bundle outdated";
          clean-boot-generations = "sudo /run/current-system/bin/switch-to-configuration boot";
          ga = "git aa";
          gc = "git ci -p";
          gca = "git ci -p --amend";
          gl = "git log";
          gp = "git push";
          gv = "open_modified_and_untracked_in_vim";
          gvh = "open_changed_from_head_in_vim";
          gvv = "edit_diff_files_in_vim";
          ls = "eza";
          show-git-remote-authors = "git for-each-ref --format=' %(authorname) %09 %(refname)' --sort=authorname | grep remote";
          showtodos = "git grep -l TODO | xargs -n1 git blame --show-email -f | grep TODO  | sed -E 's/[[:blank:]]+/ /g' | sort -k 4";
          res-low = "niri msg output Virtual-1 mode 1920x1080@60.000";
          res-default = "niri msg output Virtual-1 mode 7680x3200@60.000";
          se-new = "nix run github:ahacop/standardebooks-nix -- new";
          se-init = "nix run github:ahacop/standardebooks-nix -- init";
        };
        initContent = ''
          # Tell zsh-completion-sync to pass -i to compinit (ignore insecure directories)
          zstyle ':completion-sync:compinit' arguments -i

          # Static just completions (the default source <(...) wrapper breaks with direnv)
          source ${just-completions}/_just

          ${builtins.readFile ../config/zshrc}

          ${builtins.readFile ../config/functions}

          # Tmux window renaming hooks
          if [[ -n "$TMUX" ]]; then
            # Function to rename tmux window
            tmux_rename_window() {
              if [[ -n "$1" ]]; then
                tmux rename-window "$1" 2>/dev/null
              fi
            }

            # Hook that runs before command execution
            preexec() {
              local cmd="$1"
              local cmd_name="''${cmd%% *}"

              # Skip renaming for job control commands
              if [[ "$cmd_name" =~ ^(fg|bg|jobs)$ ]]; then
                return
              fi

              # Check if it's a make command and extract the target
              if [[ "$cmd" =~ ^make[[:space:]]+([^[:space:]]+) ]]; then
                tmux_rename_window "m:''${match[1]}"
              elif [[ "$cmd" =~ ^claude ]]; then
                tmux_rename_window "claude:''${PWD##*/}"
              elif [[ "$cmd" =~ ^nvim ]]; then
                tmux_rename_window "nvim:''${PWD##*/}"
              else
                # For other commands, just show the command name
                tmux_rename_window "$cmd_name"
              fi
            }

            # Hook that runs after command execution (when back at prompt)
            precmd() {
              # Reset to directory name when back at prompt
              tmux_rename_window "''${PWD##*/}"
            }
          fi
        '';
      };
    };
}
