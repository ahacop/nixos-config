{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  programs = {
    nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      globals = {mapleader = " ";};

      extraConfigVim = ''
        cnoremap %% <C-R>=expand('%:h').'/'<cr>
      '';

      keymaps = [
        {
          action.__raw = ''
            function()
              -- if there is an active search highlight and we are not in the quickfix
              local shouldClearHighlight = vim.api.nvim_buf_get_option(0, 'buftype') ~= 'quickfix' and vim.v.hlsearch ~= 0

              if shouldClearHighlight then
                -- Clear highlight
                vim.cmd('nohlsearch')
              else
                -- Perform the default <CR> action
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, true, true), 'n', true)
              end
            end
          '';
          key = "<CR>";
          mode = "n";
          options = {
            silent = true;
            desc = "Clear highlighted search";
          };
        }
        {
          action = "<cmd>TestFile HEADLESS=0<CR>";
          key = "<leader>tf";
          mode = "n";
          options = {desc = "TestFile";};
        }
        {
          action = "<cmd>TestNearest HEADLESS=0<CR>";
          key = "<leader>tt";
          mode = "n";
          options = {desc = "TestNearest";};
        }
        {
          action = "<cmd>TestSuite HEADLESS=0<CR>";
          key = "<leader>ts";
          mode = "n";
          options = {desc = "TestSuite";};
        }
        {
          action = "<cmd>TestFile HEADLESS=1<CR>";
          key = "<leader>thf";
          mode = "n";
          options = {desc = "TestFile (HEADLESS=1)";};
        }
        {
          action = "<cmd>TestNearest HEADLESS=1<CR>";
          key = "<leader>tht";
          mode = "n";
          options = {desc = "TestNearest HEADLESS=1";};
        }
        {
          action = "<cmd>TestSuite HEADLESS=1<CR>";
          key = "<leader>ths";
          mode = "n";
          options = {desc = "TestSuite HEADLESS=1";};
        }
        {
          action = "<cmd>TestVisit<CR>";
          key = "<leader>tv";
          mode = "n";
          options = {desc = "TestVisit";};
        }
      ];

      opts = {
        autoindent = true;
        clipboard = "unnamedplus";
        expandtab = true;
        ignorecase = true;
        incsearch = true;
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        signcolumn = "yes";
        smartcase = true;
        spell = true;
      };

      plugins = {
        undotree.enable = true;
        which-key.enable = true;
        treesitter.enable = true;
        markdown-preview.enable = true;
        telescope = {
          enable = true;
          keymaps = {
            "<leader>ff" = {
              action = "find_files";
              options = {desc = "Telescope find files";};
            };
            "<leader>fg" = {
              action = "live_grep";
              options = {desc = "Telescope live_grep";};
            };
            "<leader>fb" = {
              action = "buffers";
              options = {desc = "Telescope buffers";};
            };
            "<leader>fh" = {
              action = "help_tags";
              options = {desc = "Telescope help_tags";};
            };
            "<leader>fvcw" = {
              action = "git_commits";
              options = {desc = "Telescope git_commits";};
            };
            "<leader>fvcb" = {
              action = "git_bcommits";
              options = {desc = "Telescope git_bcommits";};
            };
            "<leader>fvb" = {
              action = "git_branches";
              options = {desc = "Telescope git_branches";};
            };
            "<leader>fvs" = {
              action = "git_status";
              options = {desc = "Telescope git_status";};
            };
            "<leader>fvx" = {
              action = "git_stash";
              options = {desc = "Telescope git_stash";};
            };
          };
        };

        gitblame.enable = true;
        fugitive.enable = true;
        neogit.enable = false;
        diffview.enable = true;
        endwise.enable = true;
        nvim-lightbulb.enable = true;
        gitsigns.enable = true;
        auto-session.enable = false;
        comment.enable = true;
        lualine.enable = true;
      };

      autoCmd = [
        {
          event = ["FileType"];
          pattern = ["gitcommit"];
          callback = {
            __raw = ''
              function()
                vim.opt.colorcolumn = "72"
              end
            '';
          };
        }
      ];

      extraPlugins = with pkgs.vimPlugins; [vim-test direnv-vim];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = true;
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
        add_newline = false;
        line_break.disabled = true;
      };
    };
    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      enableCompletion = true;
      autosuggestion.enable = true;
      shellAliases = {
        be = "bundle exec";
        clean-boot-generations = "sudo /run/current-system/bin/switch-to-configuration boot";
        ga = "git aa";
        gc = "git ci -p";
        gca = "git ci -p --amend";
        germ = "dict -d fd-deu-eng";
        gf = "git fetch";
        gl = "git log";
        gos = "git diff-tree --no-commit-id --name-only -r";
        gst = "git status";
        gv = "open_modified_and_untracked_in_vim";
        gvh = "open_changed_from_head_in_vim";
        gvm = "vi -p $(git diff main --name-only)";
        gvv = "vi -p $(git diff main --name-only)";
        ls = "ls -GF";
        pbcopy = "xclip";
        pbpaste = "xclip -o";
        retag = "git ls-files | xargs ctags";
        show-git-remote-authors = "git for-each-ref --format=' %(authorname) %09 %(refname)' --sort=authorname | grep remote";
        showtodos = "git grep -l TODO | xargs -n1 git blame --show-email -f | grep TODO  | sed -E 's/[[:blank:]]+/ /g' | sort -k 4";
        strip = "sed $'s,x1b\\[[0-9;]*[a-zA-Z],,g;s,\r$,,g'";
      };
      initExtra = ''
        ${builtins.readFile ./../../config/zshrc}

        ${builtins.readFile ./../../config/functions}
      '';
    };
    gpg.enable = true;
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = ["https://github.com"];
      };
    };

    git = {
      enable = true;
      difftastic = {enable = true;};
      userName = "Ara Hacopian";
      userEmail = "ara@hacopian.de";
      lfs.enable = true;
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
        branch = {
          autosetuprebase = "always";
          sort = "committerdate";
        };
        blame.ignoreRevsFile = ".git-blame-ignore-revs";
        commit.verbose = true;
        color.ui = true;
        core = {
          askPass = ""; # needs to be empty to use terminal for ask pass
          editor = "nvim";
        };
        credential.helper = "store"; # want to make this more secure
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
        pull = {ff-only = true;};
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
      prefix = "C-x";
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

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        bind-key C-x last-window
      '';
    };

    wezterm = {
      enable = true;
      enableZshIntegration = true;
    };

    alacritty = {
      enable = true;
      settings = {
        cursor = {style = "Block";};

        window = {
          decorations = "None";
          dynamic_title = true;
          padding = {
            x = 24;
            y = 24;
          };
        };
      };
    };

    i3status = {
      enable = true;
    };
  };

  home = {
    username = "ahacop";
    homeDirectory = "/home/ahacop";

    file = {
      ".githelpers".source = ./../../config/githelpers;
      ".ssh/config".source = ./../../config/sshconfig;
    };

    stateVersion = "24.05";

    packages = with pkgs; [
      _1password
      asciinema
      awscli2
      bat
      fd
      firefox
      fzf
      htop
      jq
      ripgrep
      silicon
      tig
      tldr
      tree
      rofi
    ];
    sessionVariables = {
      PAGER = "less -FirSwX";
    };
  };
}
