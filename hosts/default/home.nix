{
  config,
  lib,
  inputs,
  llmAgentPackages,
  pkgs,
  ...
}:
let
  # Identity for the git config below.
  fullName = "Ara Hacopian";
  primaryEmail = "ara@hacopian.de";
  workEmail = "ara@changebot.ai";

  just-completions = pkgs.runCommand "just-zsh-completions" { } ''
    mkdir -p $out
    JUST_COMPLETE=zsh ${pkgs.just}/bin/just > $out/_just
  '';
in
{
  # rofi is not enabled. The stylix rofi target still sets
  # `programs.rofi.font`, which home-manager renamed to
  # `programs.rofi.settings.font`, and that causes an evaluation warning.
  stylix.targets.rofi.enable = false;

  # Mounts a plugged-in USB drive under /run/media/$USER, where epubsync
  # looks for the Kobo. To eject, pick the device from the udiskie icon in
  # the bar tray, choose it under the `/eject` launcher prefix, or run
  # `udiskie-umount --detach /run/media/$USER/KOBOeReader`.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    # The tray icon shows only while a removable device is present. Its
    # menu has Unmount, Eject and Detach entries per device.
    tray = "auto";
  };

  # Makes the udiskie unit pass --appindicator, so its tray icon is a
  # StatusNotifierItem that Noctalia's tray widget can show. The default
  # is an X11 status icon, which is invisible under Wayland.
  xsession.preferStatusNotifierItems = true;

  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
    };

    skim = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        command_timeout = 500;
        add_newline = false;
        # Only the modules named here run, in this order. Every language,
        # cloud and status module starship ships is left out.
        format = "$username$hostname$directory$git_branch$git_commit$git_state$git_status$package$cmd_duration$character";
      };
    };

    zsh = {
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

        ${builtins.readFile ./../../config/zshrc}

        ${builtins.readFile ./../../config/functions}

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
    gpg.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = [ "https://github.com" ];
      };
    };

    git = {
      enable = true;
      signing.format = "openpgp";
      ignores = [
        ".envrc"
        ".direnv/"
        ".claude/"
      ];
      lfs.enable = true;
      includes = [
        {
          condition = "gitdir:~/code/changebot-ai/";
          contents = {
            user = {
              email = workEmail;
            };
          };
        }
      ];
      settings = {
        user = {
          name = fullName;
          email = primaryEmail;
        };
        alias = {
          aa = "add --all";
          amend = "commit --amend";
          br = "branch";
          ci = "commit";
          cleanup = "!git branch --merged | grep -vE '^\\*|^\\s*(main|master|develop)$' | xargs -n 1 -r git branch -d";
          co = "checkout";
          dc = "diff --cached";
          df = "diff";
          dh1 = "diff HEAD~1";
          di = "diff";
          ds = "diff --stat";
          fa = "fetch --all";
          ff = "merge --ff-only";
          h = "!git head"; # h  = head
          head = "!git l -1";
          hp = "!. ~/.githelpers && show_git_head"; # hp = head with patch
          l = "!. ~/.githelpers && pretty_git_log"; # l  = all commits, only current branch
          la = "!git l --all"; # la = all commits, all reachable refs
          lg = "log -p";
          noff = "merge --no-ff";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          pullff = "pull --ff-only";
          r = "!git l -30"; # r  = recent commits, only current branch
          ra = "!git r --all"; # ra = recent commits, all reachable refs
          root = "rev-parse --show-toplevel";
          st = "status";
          today = "log --since=midnight --author='${fullName}' --oneline";
          yesterday = "log --since=midnight.yesterday --until=midnight --author='${fullName}' --oneline";
          churn = "!f() { git log --all -M -C --name-only --format='format:' \"$@\" | sort | grep -v '^$' | uniq -c | sort -n; }; f";
        };
        branch = {
          autosetuprebase = "always";
          sort = "committerdate";
        };
        commit.verbose = true;
        color.ui = true;
        core = {
          askPass = ""; # needs to be empty to use terminal for ask pass
          editor = "nvim";
        };
        diff = {
          colorMoved = "default";
          algorithm = "histogram";
        };
        github.user = "ahacop";
        init.defaultBranch = "main";
        merge = {
          conflictStyle = "zdiff3";
          tool = "nvimdiff";
        };
        pull = {
          ff-only = true;
        };
        push = {
          default = "tracking";
          autoSetupRemote = true;
        };
        rebase = {
          autoSquash = true;
          autoStash = true;
        };
        rerere.enabled = true;
      };
    };

    tmux = {
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

  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
    };
  };

  home = {
    file = {
      ".githelpers".source = ./../../config/githelpers;
      ".ssh/config".source = ./../../config/sshconfig;
      ".tigrc".text = ''
        bind generic Y !sh -c 'commit=%(commit); echo $commit | /run/current-system/sw/bin/wl-copy -n & echo $commit | /run/current-system/sw/bin/tmux load-buffer -'
        set main-view = line-number:no id:yes date:custom,format="%Y-%m-%d %H:%M" author:full commit-title:yes,graph,refs,overflow=no
      '';
    };

    stateVersion = "24.05";

    packages =
      # LLM agent CLIs from the numtide llm-agents.nix flake, resolved in
      # modules/llm-agents.nix from the llmAgentNames single source of truth
      # and passed in via extraSpecialArgs.
      llmAgentPackages
      ++ (with pkgs; [
        (calibre.override { speechSupport = false; })
        circumflex
        devenv
        duckdb
        foliate
        glow
        inputs.aoc-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.erwindb.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.mw-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.opdsview.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.epub-sync.packages.${pkgs.stdenv.hostPlatform.system}.default
        mermaid-cli
        pomodoro
        presenterm
        udiskie # puts udiskie-umount and udiskie-info on the PATH; the daemon is services.udiskie above
        vale
        zathura
      ]);
    sessionVariables = {
      PAGER = "less";
      # Read by every less invocation, not only the ones started through
      # PAGER. -X keeps the output on screen after less exits.
      LESS = "-FirSwX";
      # Ollama runs on the Mac host. Resolved via mDNS (avahi enabled in
      # configuration.nix) so it survives the host's IP changing.
      OLLAMA_HOST = "http://chunky-peanut-butter.local:11434";
    };
  };
}
