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

  nur = import inputs.nur {
    inherit pkgs;
    nurpkgs = pkgs;
  };

  just-completions = pkgs.runCommand "just-zsh-completions" { } ''
    mkdir -p $out
    JUST_COMPLETE=zsh ${pkgs.just}/bin/just > $out/_just
  '';

  websters-1913-stardict = pkgs.stdenv.mkDerivation {
    pname = "websters-1913-stardict";
    version = "2.4.2";

    src = pkgs.fetchFromGitHub {
      owner = "ahacop";
      repo = "websters-dict-1913-stardict";
      rev = "7f9c6d6725eb1b0d8545a6f74904610fa2a2c71e";
      sha256 = "sha256-/g7Tm0tQzf7pkA6EzTMxOrh3FCr8CLxgRVsAp/ZxFpU=";
    };

    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.gzip
    ];

    installPhase = ''
      mkdir -p $out/share/stardict/dic
      tar -xzf stardict-dictd-web1913-2.4.2.tgz -C $out/share/stardict/dic
    '';
  };
in
{
  stylix.targets.firefox.profileNames = [ "default" ];
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

    firefox = {
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

    ghostty = {
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
        define = "sdcv";
        germ = "dict -d fd-deu-eng";
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

        # StarDict dictionary path (set unconditionally for subshells)
        export STARDICT_DATA_DIR="${websters-1913-stardict}/share/stardict/dic"

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

    # Noctalia is the whole shell layer: bar, launcher, notification daemon,
    # control center, clipboard history, OSDs and lock screen in one process.
    # It replaces waybar, mako, walker and cliphist, so none of those are
    # installed. Colors, fonts and opacity arrive from stylix via
    # `stylix.targets.noctalia`, which writes a custom palette and points the
    # theme at it — the scheme itself stays set in configuration.nix.
    #
    # `settings` is an attrset rendered to TOML. `checkConfig` (on by default)
    # runs `noctalia config validate` over the result during the build, so a
    # bad key or widget name fails `make test` rather than at login.
    noctalia = {
      enable = true;
      systemd.enable = false; # Started directly by niri spawn-at-startup

      settings = {
        # Panels and menus fade in and out by default, which reads as lag.
        shell.animation.enabled = false;

        # Noctalia draws a wallpaper of its own, falling back to the image
        # bundled in its package. With it off, the niri layout background-color
        # set below is what shows behind the windows. A wallpaper picked in the
        # Noctalia UI is written to ~/.local/state/noctalia/settings.toml, and
        # that file takes precedence over this one, so setting a path here
        # would not survive the first pick.
        wallpaper.enabled = false;

        # This VM has no wifi radio and no bluetooth adapter. VMware bridges
        # the Mac's connection and passes through an emulated ethernet NIC, so
        # the network and bluetooth surfaces have nothing to list. Hide the two
        # control center tabs, drop their quick shortcuts, and stop their OSDs.
        # Throughput still shows in the bar via the sysmon widgets below.
        control_center = {
          hidden_tabs = [
            "network"
            "bluetooth"
          ];
          shortcuts = [
            { type = "caffeine"; }
            { type = "nightlight"; }
            { type = "notification"; }
            { type = "power_profile"; }
          ];
        };

        osd.kinds = {
          wifi = false;
          bluetooth = false;
        };

        plugins.enabled = [
          "ahacop/timezone-grid"
          "goodroot/noctwhspr"
        ];

        bar = {
          order = [ "default" ];
          default = {
            position = "bottom";
            enabled = true;
            thickness = 35;

            # A plain bar edge to edge. The defaults float it: margin_ends
            # insets it 100px at each end, and radius rounds the corners.
            margin_ends = 0;
            radius = 0;
            shadow = false;
            start = [
              "launcher"
              "workspaces"
              "active_window"
            ];
            center = [ ];
            # The old waybar right side, minus battery: this VM has no
            # /sys/class/power_supply entry, so a battery readout is blank.
            end = [
              "netrx"
              "nettx"
              "disk"
              "ram"
              "cpu"
              # hyprwhspr state: a red dot while it records, a microphone
              # when it is ready. Left click toggles a recording, right click
              # restarts the service.
              "goodroot/noctwhspr:status"
              "volume"
              "tray"
              "notifications"
              "clipboard"
              "clock"
              "control_center"
            ];
          };
        };

        # Named widget instances referenced by the bar sections above. Several
        # are the one `sysmon` widget pinned to a different stat.
        widget = {
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
          };
          disk = {
            type = "sysmon";
            stat = "disk_used_pct";
            path = "/";
          };
          # enp2s0 is the bridged VMware interface set up in configuration.nix.
          netrx = {
            type = "sysmon";
            stat = "net_rx";
            interface = "enp2s0";
            network_speed_compact = true;
          };
          nettx = {
            type = "sysmon";
            stat = "net_tx";
            interface = "enp2s0";
            network_speed_compact = true;
          };
          clock = {
            type = "clock";
            format = "{:%Y-%m-%d %H:%M}";
            tooltip_format = "{:%A, %B %d, %Y}";
            actions.right = "panel-toggle ahacop/timezone-grid:panel";
          };
        };

        shell.launcher = {
          provider_prefix = "/";

          # A flat command palette reached with `/cmd`, or from the global
          # search because `global` is set. `command` prints the choices, one
          # per line; `exec` receives the picked line as {selection} and runs
          # detached, with no terminal attached.
          dmenu.entry.cmd = {
            label = "Commands";
            prefix = "/cmd";
            glyph = "terminal";
            global = true;
            command = "printf '%s\\n' 'Display: 1920x1080' 'Display: 7680x3200' 'Dictate: toggle'";
            exec = ''case "{selection}" in "Display: 1920x1080") niri msg output Virtual-1 mode 1920x1080@60.000 ;; "Display: 7680x3200") niri msg output Virtual-1 mode 7680x3200@60.000 ;; "Dictate: toggle") hyprwhspr record toggle ;; esac'';
          };

          # Removable drives to eject, reached with `/eject` or from the
          # global search. Each choice is a mount path such as
          # /run/media/ahacop/KOBOeReader. Picking one unmounts the drive
          # and powers it off, the same as `udiskie-umount --detach`.
          dmenu.entry.eject = {
            label = "Eject";
            prefix = "/eject";
            glyph = "usb";
            global = true;
            command = "${pkgs.udiskie}/bin/udiskie-info -a -f is_mounted -f is_external -o '{mount_path}'";
            exec = ''${pkgs.udiskie}/bin/udiskie-umount --detach "{selection}" && ${pkgs.libnotify}/bin/notify-send "Ejected {selection}"'';
          };
        };
      };
    };
  };

  xdg.enable = true;

  # Noctalia scans this directory for plugins that come from neither the
  # official nor the community repo.
  xdg.dataFile."noctalia/plugins/timezone-grid".source = ./../../plugins/timezone-grid;

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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
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
        sdcv
        udiskie # puts udiskie-umount and udiskie-info on the PATH; the daemon is services.udiskie above
        vale
        websters-1913-stardict
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
