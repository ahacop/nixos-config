_: {
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  inherit (pkgs.stdenv) isLinux;
in {
  xdg.enable = true;
  xdg.configFile = {
    "i3/config".text = builtins.readFile ./i3;
  };
  home = {
    stateVersion = "23.11";

    shellAliases =
      {
        clean-boot-generations = "sudo /run/current-system/bin/switch-to-configuration boot";
        g = "git";
        gvm = "vi -p $(git diff master --name-only)";
        gst = "git status";
        fpass = "faktory_server_password";
        strip = "sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g;s,\r$,,g'";
        gos = "git diff-tree --no-commit-id --name-only -r";
        vi = "nvim";
        vim = "nvim";
        vimdiff = "nvim -d";
        ls = "ls -GF";
        be = "bundle exec";
        gc = "git ci -p";
        gca = "git ci -p --amend";
        ga = "git aa";
        gf = "git fetch";
        gl = "git log";
        retag = "git ls-files | xargs ctags";
        gv = "open_modified_and_untracked_in_vim";
        gvh = "open_changed_from_head_in_vim";
        gvv = "vi -p $(git diff master --name-only)";
        tat = "tmux attach -t `basename $PWD` || tmux new-session -As \"$(basename \"$PWD\" | tr . -)\"";
        germ = "dict -d fd-deu-eng";
        memsql_staging_tunnel = "ssh -L 9000:0.0.0.0:9000 -N -v bm-staging-memsql";
        memsql_production_tunnel = "ssh -L 9000:0.0.0.0:9000 -N -v bm-production-memsql";
        memsql_studio_production_tunnel = "ssh -L 8080:0.0.0.0:8080 -N -v bm-production-memsql";
        showtodos = "git grep -l TODO | xargs -n1 git blame --show-email -f | grep TODO  | sed -E 's/[[:blank:]]+/ /g' | sort -k 4";
        show-git-remote-authors = "git for-each-ref --format=' %(authorname) %09 %(refname)' --sort=authorname | grep remote";
        k = "kubectl";
      }
      // (
        if isLinux
        then {
          pbcopy = "xclip";
          pbpaste = "xclip -o";
        }
        else {}
      );

    file = {
      ".ssh/config".source = ./config/sshconfig;
    };

    packages = with pkgs;
      [
        asciinema
        bat
        fd
        htop
        jq
        ripgrep
        tree
        watch
        firefox
        zsh-powerlevel10k
        tig
        awscli2
        k9s
        kubectl
      ]
      ++ (lib.optionals isDarwin [
        # This is automatically setup on Linux
        cachix
        # tailscale
      ])
      ++ (lib.optionals isLinux [
        rofi
        valgrind
        zathura
        xfce.xfce4-terminal
      ]);

    #---------------------------------------------------------------------
    # Env vars and dotfiles
    #---------------------------------------------------------------------

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "less -FirSwX";
    };

    # Make cursor not tiny on HiDPI screens
    pointerCursor = lib.mkIf isLinux {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
      size = 128;
      x11.enable = true;
    };
  };
  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      tmux = {
        enableShellIntegration = true;
      };
    };
    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      autocd = false;
      cdpath = ["~/.local/share/src"];
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "p10k.zsh";
        }
      ];
      initExtra = builtins.readFile ./config/functions;
    };

    fish = {
      enable = true;
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };

    gpg.enable = !isDarwin;

    bash = {
      enable = true;
      historyControl = ["ignoredups" "ignorespace"];
    };

    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
        ];
      };
    };

    git = {
      enable = true;
      userName = "Ara Hacopian";
      userEmail = "ara@hacopian.de";
      lfs.enable = true;
      signing = {
        key = "D03AB28E58D8DDEE";
        signByDefault = true;
      };
      aliases = {
        cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
        prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        root = "rev-parse --show-toplevel";
        aa = "add --all";
        amend = "commit --amend";
        br = "branch";
        ci = "commit";
        co = "checkout";
        dc = "diff --cached";
        df = "diff";
        dh1 = "diff HEAD~1";
        di = "diff";
        ds = "diff --stat";
        fa = "fetch --all";
        ff = "merge --ff-only";
        lg = "log -p";
        noff = "merge --no-ff";
        pom = "push origin master";
        pullff = "pull --ff-only";
        st = "status";
        div = "divergence";

        gn = "goodness";
        gnc = "goodness --cached";

        # Fancy logging.
        #   h  = head
        #   hp = head with patch
        #   r  = recent commits, only current branch
        #   ra = recent commits, all reachable refs
        #   l  = all commits, only current branch
        #   la = all commits, all reachable refs
        head = "!git l -1";
        h = "!git head";
        hp = "!. ~/.githelpers && show_git_head";
        r = "!git l -30";
        ra = "!git r --all";
        l = "!. ~/.githelpers && pretty_git_log";
        la = "!git l --all";
        today = "log --since=midnight --author='ahacop' --oneline";
        yesterday = "log --since=midnight.yesterday --until=midnight --author='ahacop' --oneline";
      };
      extraConfig = {
        branch.autosetuprebase = "always";
        color.ui = true;
        core = {
          askPass = ""; # needs to be empty to use terminal for ask pass
          editor = "nvim";
        };
        credential.helper = "store"; # want to make this more secure
        init.defaultBranch = "main";
        github.user = "ahacop";
        push.default = "tracking";
        rebase.autoStash = true;
      };
    };

    tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        sensible
        yank
        prefix-highlight
        {
          plugin = power-theme;
          extraConfig = ''
            set -g @tmux_power_theme 'gold'
          '';
        }
        {
          plugin = resurrect; # Used by tmux-continuum

          # Use XDG data directory
          # https://github.com/tmux-plugins/tmux-resurrect/issues/348
          extraConfig = ''
            set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-pane-contents-area 'visible'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5' # minutes
          '';
        }
      ];
      terminal = "screen-256color";
      prefix = "C-x";
      escapeTime = 10;
      historyLimit = 50000;
      extraConfig = ''
        # Remove Vim mode delays
        set -g focus-events on

        # Enable full mouse support
        set -g mouse on

        # -----------------------------------------------------------------------------
        # Key bindings
        # -----------------------------------------------------------------------------

        # Unbind default keys
        unbind C-b

        # Move around panes with vim-like bindings (h,j,k,l)
        bind-key -n M-k select-pane -U
        bind-key -n M-h select-pane -L
        bind-key -n M-j select-pane -D
        bind-key -n M-l select-pane -R

        # Smart pane switching with awareness of Vim splits.
        # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l

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

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        bind-key C-x last-window
      '';
    };

    alacritty = {
      enable = true;
      settings = {
        cursor = {
          style = "Block";
        };

        window = {
          opacity = 1.0;
          padding = {
            x = 24;
            y = 24;
          };
        };

        font = {
          normal = {
            family = "MesloLGS NF";
            style = "Regular";
          };
          size = lib.mkMerge [
            (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 16)
            (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 16)
          ];
        };

        dynamic_padding = true;
        decorations = "full";
        title = "Terminal";
        class = {
          instance = "Alacritty";
          general = "Alacritty";
        };

        colors = {
          primary = {
            background = "0x1f2528";
            foreground = "0xc0c5ce";
          };

          normal = {
            black = "0x1f2528";
            red = "0xec5f67";
            green = "0x99c794";
            yellow = "0xfac863";
            blue = "0x6699cc";
            magenta = "0xc594c5";
            cyan = "0x5fb3b3";
            white = "0xc0c5ce";
          };

          bright = {
            black = "0x65737e";
            red = "0xec5f67";
            green = "0x99c794";
            yellow = "0xfac863";
            blue = "0x6699cc";
            magenta = "0xc594c5";
            cyan = "0x5fb3b3";
            white = "0xd8dee9";
          };
        };
      };
    };

    kitty = {
      enable = true;
    };

    i3status = {
      enable = isLinux;

      general = {
        colors = true;
        color_good = "#8C9440";
        color_bad = "#A54242";
        color_degraded = "#DE935F";
      };

      modules = {
        ipv6.enable = false;
        "wireless _first_".enable = false;
        "battery all".enable = false;
      };
    };
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentryFlavor = "tty";

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };
  services.ssh-agent = {
    enable = true;
  };
}
