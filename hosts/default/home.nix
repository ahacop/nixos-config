{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  programs = {
    emacs = {
      enable = true;
      package = pkgs.emacsWithPackagesFromUsePackage {
        # Your Emacs config file. Org mode babel files are also
        # supported.
        # NB: Config files cannot contain unicode characters, since
        #     they're being parsed in nix, which lacks unicode
        #     support.
        config = ./emacs.org;

        # Whether to include your config as a default init file.
        # If being bool, the value of config is used.
        # Its value can also be a derivation like this if you want to do some
        # substitution:
        #   defaultInitFile = pkgs.substituteAll {
        #     name = "default.el";
        #     src = ./emacs.el;
        #     inherit (config.xdg) configHome dataHome;
        #   };
        defaultInitFile = true;

        # Package is optional, defaults to pkgs.emacs
        # package = pkgs.emacs-unstable;

        # By default emacsWithPackagesFromUsePackage will only pull in
        # packages with `:ensure`, `:ensure t` or `:ensure <package name>`.
        # Setting `alwaysEnsure` to `true` emulates `use-package-always-ensure`
        # and pulls in all use-package references not explicitly disabled via
        # `:ensure nil` or `:disabled`.
        # Note that this is NOT recommended unless you've actually set
        # `use-package-always-ensure` to `t` in your config.
        alwaysEnsure = false;

        # For Org mode babel files, by default only code blocks with
        # `:tangle yes` are considered. Setting `alwaysTangle` to `true`
        # will include all code blocks missing the `:tangle` argument,
        # defaulting it to `yes`.
        # Note that this is NOT recommended unless you have something like
        # `#+PROPERTY: header-args:emacs-lisp :tangle yes` in your config,
        # which defaults `:tangle` to `yes`.
        alwaysTangle = true;

        # Optionally provide extra packages not in the configuration file.
        extraEmacsPackages = epkgs:
          with epkgs; [
            all-the-icons
            diminish
            dumb-jump
            gcmh
            htmlize
            nix-mode
            no-littering
            melpaPackages.nov
            elpaPackages.org
            melpaPackages.org-bullets
            melpaPackages.evil-org
            melpaPackages.ox-hugo
            persist-state
            rfc-mode
            sdcv
            toc-org
            web-mode
            which-key
            zoom
          ];
        # Optionally override derivations.
        # override = final: prev: {
        #   weechat = prev.melpaPackages.weechat.overrideAttrs (old: {
        #     patches = [./weechat-el.patch];
        #   });
        # };
      };
    };

    nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withRuby = false;

      diagnostics.virtual_lines.only_current_line = true;

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
        {
          mode = ["n" "v"];
          key = "<leader>gh";
          action = "gitsigns";
          options = {
            silent = true;
            desc = "+hunks";
          };
        }
        {
          mode = "n";
          key = "<leader>ghb";
          action = ":Gitsigns blame_line<CR>";
          options = {
            silent = true;
            desc = "Blame line";
          };
        }
        {
          mode = "n";
          key = "<leader>ghd";
          action = ":Gitsigns diffthis<CR>";
          options = {
            silent = true;
            desc = "Diff This";
          };
        }
        {
          mode = "n";
          key = "<leader>ghR";
          action = ":Gitsigns reset_buffer<CR>";
          options = {
            silent = true;
            desc = "Reset Buffer";
          };
        }
        {
          mode = "n";
          key = "<leader>ghS";
          action = ":Gitsigns stage_buffer<CR>";
          options = {
            silent = true;
            desc = "Stage Buffer";
          };
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
        web-devicons.enable = true;
        cmp = {
          enable = true;
          settings = {
            autoEnableSources = true;
            # experimental = {ghost_text = true;};
            performance = {
              debounce = 60;
              fetchingTimeout = 200;
              maxViewEntries = 30;
            };
            # formatting = {fields = ["kind" "abbr" "menu"];};
            window = {
              completion = {border = "solid";};
              documentation = {border = "solid";};
            };
            sources = [
              {name = "nvim_lsp";}
              {name = "buffer";}
              {name = "path";}
              {
                name = "cmdline";
                option = {
                  ignore_cmds = [
                    "Man"
                    "!"
                  ];
                };
              }
            ];

            mapping = {
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<C-j>" = "cmp.mapping.select_next_item()";
              "<C-k>" = "cmp.mapping.select_prev_item()";
              "<C-e>" = "cmp.mapping.abort()";
              "<C-b>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
            };
          };
        };
        gitlinker = {
          enable = true;
          callbacks = {"github.com" = "get_github_type_url";};
        };
        lspkind = {
          enable = false;
          symbolMap = {Copilot = "";};
          extraOptions = {
            maxwidth = 50;
            ellipsis_char = "...";
          };
        };
        gitsigns = {
          enable = true;
          settings = {
            trouble = true;
            current_line_blame = false;
            signs = {
              add = {text = "│";};
              change = {text = "│";};
              delete = {text = "_";};
              topdelete = {text = "‾";};
              changedelete = {text = "~";};
              untracked = {text = "│";};
            };
          };
        };
        conform-nvim = {
          enable = false;
          settings = {
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 500;
            };
            notify_on_error = true;
            formatters_by_ft = {
              html = [["prettierd" "prettier"]];
              css = [["prettierd" "prettier"]];
              javascript = [["prettierd" "prettier"]];
              lua = ["stylua"];
              nix = ["alejandra"];
              markdown = [["prettierd" "prettier"]];
              yaml = ["yamllint" "yamlfmt"];
            };
          };
        };
        undotree.enable = true;
        which-key.enable = true;
        treesitter = {
          enable = true;
          nixGrammars = true;
          settings.indent.enable = false;
          folding = false;
        };
        treesitter-context = {
          enable = true;
          settings = {max_lines = 2;};
        };
        rainbow-delimiters.enable = true;
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

        fugitive.enable = true;
        neogit.enable = false;
        diffview.enable = true;
        endwise.enable = true;
        nvim-lightbulb.enable = true;
        auto-session.enable = false;
        comment.enable = true;
        lualine.enable = true;

        lsp = {
          enable = true;
          servers = {
            # gopls.enable = true;
            # nixd.enable = true;
            bashls.enable = true;
            cssls.enable = true;
            elixirls.enable = true;
            eslint = {enable = true;};
            gleam.enable = true;
            html = {enable = true;};
            lua_ls = {enable = true;};
            marksman = {enable = true;};
            nil_ls = {enable = true;};
            ruby_lsp = {
              enable = true;
              package = null;
            };
            tailwindcss.enable = true;
            terraformls = {enable = true;};
            ts_ls = {enable = false;};
            yamlls = {enable = true;};
          };
          keymaps.lspBuf = {
            "gd" = "definition";
            "gD" = "references";
            "gy" = "type_definition";
            "gi" = "implementation";
            "K" = "hover";
          };
        };
        lsp-lines = {
          enable = true;
        };
        rustaceanvim.enable = true;
        trouble.enable = true;
        fidget = {
          enable = true;
          progress = {
            suppressOnInsert = true;
            ignoreDoneAlready = true;
            pollRate = 0.5;
          };
        };

        git-worktree = {
          enable = true;
          enableTelescope = true;
        };

        lsp-format.enable = true;

        none-ls = {
          enable = true;
          enableLspFormat = true;
          settings.update_in_insert = false;
          sources = {
            code_actions = {
              gitsigns.enable = true;
              statix.enable = true;
            };
            diagnostics = {
              statix.enable = true;
              yamllint.enable = true;
              # golangci_lint.enable = true;
            };
            formatting = {
              alejandra.enable = true;
              prettier = {
                enable = true;
                disableTsServerFormatter = true;
              };
              stylua.enable = true;
              yamlfmt.enable = true;
              gleam_format.enable = true;
              # gofmt.enable = true;
              # goimports.enable = true;
              markdownlint.enable = true;
              shellharden.enable = true;
              shfmt.enable = true;
            };
          };
        };
      };

      autoGroups = {
        custom_term_open = {
          clear = true;
        };
      };

      autoCmd = [
        {
          event = ["TermOpen"];
          group = "custom_term_open";
          callback = {
            __raw = ''
              function()
                vim.opt.number = false
                vim.opt.relativenumber = false
              end
            '';
          };
        }
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
        line_break.disabled = true;

        aws.disabled = true;
        battery.disabled = true;
        c.disabled = true;
        cmake.disabled = true;
        cobol.disabled = true;
        conda.disabled = true;
        crystal.disabled = true;
        daml.disabled = true;
        dart.disabled = true;
        deno.disabled = true;
        direnv.disabled = true;
        docker_context.disabled = true;
        dotnet.disabled = true;
        elixir.disabled = true;
        elm.disabled = true;
        env_var.disabled = true;
        erlang.disabled = true;
        fennel.disabled = true;
        fossil_branch.disabled = true;
        fossil_metrics.disabled = true;
        gcloud.disabled = true;
        gleam.disabled = true;
        golang.disabled = true;
        gradle.disabled = true;
        guix_shell.disabled = true;
        haskell.disabled = true;
        haxe.disabled = true;
        helm.disabled = true;
        hg_branch.disabled = true;
        java.disabled = true;
        jobs.disabled = true;
        julia.disabled = true;
        kotlin.disabled = true;
        kubernetes.disabled = true;
        localip.disabled = true;
        lua.disabled = true;
        memory_usage.disabled = true;
        meson.disabled = true;
        nats.disabled = true;
        nim.disabled = true;
        nix_shell.disabled = true;
        nodejs.disabled = true;
        ocaml.disabled = true;
        openstack.disabled = true;
        opa.disabled = true;
        os.disabled = true;
        perl.disabled = true;
        php.disabled = true;
        pijul_channel.disabled = true;
        pulumi.disabled = true;
        purescript.disabled = true;
        python.disabled = true;
        quarto.disabled = true;
        raku.disabled = true;
        red.disabled = true;
        rlang.disabled = true;
        ruby.disabled = true;
        rust.disabled = true;
        scala.disabled = true;
        shlvl.disabled = true;
        singularity.disabled = true;
        solidity.disabled = true;
        spack.disabled = true;
        sudo.disabled = true;
        swift.disabled = true;
        terraform.disabled = true;
        time.disabled = true;
        typst.disabled = true;
        vagrant.disabled = true;
        vcsh.disabled = true;
        vlang.disabled = true;
        zig.disabled = true;
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
        gvv = "edit_diff_files_in_vim";
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
      plugins = with pkgs.tmuxPlugins; [prefix-highlight sensible yank];

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
        bind-key c new-window -c '#{pane_current_path}'

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

  xdg.enable = true;
  xdg.configFile = {"i3/config".text = builtins.readFile ./../../config/i3;};

  home = {
    username = "ahacop";
    homeDirectory = "/home/ahacop";

    file = {
      ".githelpers".source = ./../../config/githelpers;
      ".ssh/config".source = ./../../config/sshconfig;
      ".tigrc".text = ''
        bind generic Y !sh -c 'commit=%(commit); echo $commit | /run/current-system/sw/bin/xclip -selection clipboard & echo $commit | /run/current-system/sw/bin/tmux load-buffer -'
      '';
    };

    stateVersion = "24.05";

    packages = with pkgs; [
      _1password-cli
      asciinema
      awscli2
      bat
      devenv
      duckdb
      fd
      firefox
      fzf
      htop
      jq
      ripgrep
      rofi
      silicon
      tig
      tldr
      tree
    ];
    sessionVariables = {PAGER = "less -FirSwX";};
  };
}
