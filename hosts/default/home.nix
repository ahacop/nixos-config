{
  config,
  lib,
  inputs,
  pkgs,
  claude-code-latest,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  stylix.targets.ghostty.enable = false;

  programs = {
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        cursor-style = "block";
        font-family = "Intel One Mono";
        font-size = 24;
        theme = "GruvboxDark";
        window-decoration = "none";
      };
    };

    nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withRuby = false;

      diagnostic = {
        settings = {
          virtual_lines.only_current_line = true;
        };
      };

      globals = {
        mapleader = " ";
      };

      extraConfigVim = ''
        cnoremap %% <C-R>=expand('%:h').'/'<cr>
      '';

      keymaps = [
        {
          mode = [
            "i"
            "s"
          ];
          key = "<C-k>";
          action.__raw = ''
            function()
              local ls = require("luasnip")
              if ls.expand_or_jumpable() then
                ls.expand_or_jump()
              end
            end
          '';
          options = {
            silent = true;
            desc = "LuaSnip jump forward";
          };
        }
        {
          mode = [
            "i"
            "s"
          ];
          key = "<C-j>";
          action.__raw = ''
            function()
              local ls = require("luasnip")
              if ls.jumpable(-1) then
                ls.jump(-1)
              end
            end
          '';
          options = {
            silent = true;
            desc = "LuaSnip jump backward";
          };
        }
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
          options = {
            desc = "TestFile";
          };
        }
        {
          action = "<cmd>TestNearest HEADLESS=0<CR>";
          key = "<leader>tt";
          mode = "n";
          options = {
            desc = "TestNearest";
          };
        }
        {
          action = "<cmd>TestSuite HEADLESS=0<CR>";
          key = "<leader>ts";
          mode = "n";
          options = {
            desc = "TestSuite";
          };
        }
        {
          action = "<cmd>TestFile HEADLESS=1<CR>";
          key = "<leader>thf";
          mode = "n";
          options = {
            desc = "TestFile (HEADLESS=1)";
          };
        }
        {
          action = "<cmd>TestNearest HEADLESS=1<CR>";
          key = "<leader>tht";
          mode = "n";
          options = {
            desc = "TestNearest HEADLESS=1";
          };
        }
        {
          action = "<cmd>TestSuite HEADLESS=1<CR>";
          key = "<leader>ths";
          mode = "n";
          options = {
            desc = "TestSuite HEADLESS=1";
          };
        }
        {
          action = "<cmd>TestVisit<CR>";
          key = "<leader>tv";
          mode = "n";
          options = {
            desc = "TestVisit";
          };
        }
        {
          mode = [
            "n"
            "v"
          ];
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
        {
          action = "<cmd>DBUI<CR>";
          key = "<leader>db";
          mode = "n";
          options = {
            desc = "Run DadBod";
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
        vim-dadbod.enable = true;
        vim-dadbod-completion.enable = true;
        vim-dadbod-ui.enable = true;
        web-devicons.enable = true;
        luasnip.enable = true;
        friendly-snippets.enable = true;
        cmp = {
          enable = true;
          filetype = {
            sql = {
              sources = [
                {name = "vim-dadbod-completion";}
                {name = "buffer";}
              ];
            };
          };
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
              completion = {
                border = "solid";
              };
              documentation = {
                border = "solid";
              };
            };
            sources = [
              {name = "nvim_lsp";}
              {name = "buffer";}
              {name = "luasnip";}
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

            snippet = {
              expand = "function(args) require('luasnip').lsp_expand(args.body) end";
            };

            mapping = {
              "<C-n>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
              "<C-p>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
              "<C-y>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.insert, select = true }, { 'i', 's' })";
              "<C-b>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
            };
          };
        };
        gitlinker = {
          enable = true;
          callbacks = {
            "github.com" = "get_github_type_url";
          };
        };
        lspkind = {
          enable = false;
          symbolMap = {
            Copilot = "";
          };
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
              add = {
                text = "│";
              };
              change = {
                text = "│";
              };
              delete = {
                text = "_";
              };
              topdelete = {
                text = "‾";
              };
              changedelete = {
                text = "~";
              };
              untracked = {
                text = "│";
              };
            };
          };
        };
        indent-blankline.enable = true;
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
          settings = {
            max_lines = 2;
          };
        };
        rainbow-delimiters.enable = true;
        markdown-preview.enable = true;
        telescope = {
          enable = true;
          keymaps = {
            "<leader>ff" = {
              action = "find_files";
              options = {
                desc = "Telescope find files";
              };
            };
            "<leader>fg" = {
              action = "live_grep";
              options = {
                desc = "Telescope live_grep";
              };
            };
            "<leader>fb" = {
              action = "buffers";
              options = {
                desc = "Telescope buffers";
              };
            };
            "<leader>fh" = {
              action = "help_tags";
              options = {
                desc = "Telescope help_tags";
              };
            };
            "<leader>fvcw" = {
              action = "git_commits";
              options = {
                desc = "Telescope git_commits";
              };
            };
            "<leader>fvcb" = {
              action = "git_bcommits";
              options = {
                desc = "Telescope git_bcommits";
              };
            };
            "<leader>fvb" = {
              action = "git_branches";
              options = {
                desc = "Telescope git_branches";
              };
            };
            "<leader>fvs" = {
              action = "git_status";
              options = {
                desc = "Telescope git_status";
              };
            };
            "<leader>fvx" = {
              action = "git_stash";
              options = {
                desc = "Telescope git_stash";
              };
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
            cssls = {
              enable = false;
              extraOptions = {
                on_attach = {
                  # disable formatting
                  __raw = ''
                    function(client, bufnr)
                      client.server_capabilities.documentFormattingProvider = false
                    end
                  '';
                };
              };
            };
            elixirls.enable = true;
            eslint = {
              enable = true;
            };
            gleam.enable = true;
            html = {
              enable = true;
            };
            lua_ls = {
              enable = true;
            };
            marksman = {
              enable = true;
            };
            nil_ls = {
              enable = true;
            };
            ruby_lsp = {
              enable = true;
              package = null;
            };
            tailwindcss.enable = true;
            terraformls = {
              enable = true;
            };
            ts_ls = {
              enable = false;
            };
            yamlls = {
              enable = true;
            };
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
        vim-test.enable = true;
        rustaceanvim.enable = true;
        trouble.enable = true;
        fidget = {
          enable = true;
          settings = {
            progress = {
              suppress_on_insert = true;
              ignore_done_already = true;
            };
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
              hadolint.enable = true;
              # golangci_lint.enable = true;
            };
            formatting = {
              alejandra.enable = true;
              prettier = {
                enable = true;
                disableTsServerFormatter = true;
                settings = {
                  extra_filetypes = [
                    "yaml"
                    "css"
                  ];
                };
              };
              pg_format.enable = true;
              stylua.enable = true;
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

      extraPlugins = with pkgs.vimPlugins; [direnv-vim];
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
        bc = "bin/rails c";
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
        i3b = "list-i3-keybindings | fzf";
        ls = "ls -GF";
        pbcopy = "xclip";
        pbpaste = "xclip -o";
        retag = "git ls-files | xargs ctags";
        show-git-remote-authors = "git for-each-ref --format=' %(authorname) %09 %(refname)' --sort=authorname | grep remote";
        showtodos = "git grep -l TODO | xargs -n1 git blame --show-email -f | grep TODO  | sed -E 's/[[:blank:]]+/ /g' | sort -k 4";
        strip = "sed $'s,x1b\\[[0-9;]*[a-zA-Z],,g;s,\r$,,g'";
        claude-update = "/home/ahacop/nixos-config/scripts/claude-update";
      };
      initContent = ''
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
      difftastic = {
        enable = false;
      };
      ignores = [
        ".envrc"
        ".direnv/"
      ];
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
        bind-key c new-window -c '#{pane_current_path}'

        bind-key C-x last-window
      '';
    };

    wezterm = {
      enable = true;
      enableZshIntegration = true;
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
  xdg.configFile = {
    "i3/config".text = builtins.readFile ./../../config/i3;
  };

  home = {
    username = "ahacop";
    homeDirectory = "/home/ahacop";

    file = {
      ".githelpers".source = ./../../config/githelpers;
      ".ssh/config".source = ./../../config/sshconfig;
      ".local/flake-dev-envs/ruby/flake.nix".source = ./../../devflakes/ruby/flake.nix;
      ".local/flake-dev-envs/ruby/flake.lock".source = ./../../devflakes/ruby/flake.lock;
      ".tigrc".text = ''
        bind generic Y !sh -c 'commit=%(commit); echo $commit | /run/current-system/sw/bin/xclip -selection clipboard & echo $commit | /run/current-system/sw/bin/tmux load-buffer -'
      '';
    };

    stateVersion = "24.05";

    packages = with pkgs; [
      asciinema
      awscli2
      bat
      (claude-code-latest pkgs)
      devenv
      duckdb
      dysk
      fd
      files-to-prompt
      firefox
      fzf
      htop
      jq
      nodejs
      ripgrep
      rofi
      silicon
      tig
      tldr
      tree
    ];
    sessionVariables = {
      PAGER = "less -FirSwX";
    };
  };
}
