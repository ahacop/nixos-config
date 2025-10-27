{
  config,
  lib,
  inputs,
  pkgs,
  claude-code-latest,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  stylix.targets.ghostty.enable = false;

  programs = {
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Ara Hacopian";
          email = "ara@hacopian.de";
        };
        aliases = {
          # Common shortcuts
          d = [ "diff" ];
          di = [ "diff" ];
          l = [ "log" ];
          ll = [
            "log"
            "-r"
            "::@"
          ]; # Show all ancestors of current revision
          lg = [
            "log"
            "--graph"
          ];

          # Branch operations
          b = [ "branch" ];
          bl = [
            "branch"
            "list"
          ];
          bc = [
            "branch"
            "create"
          ];
          bd = [
            "branch"
            "delete"
          ];

          # Navigation
          co = [ "checkout" ];
          n = [ "new" ]; # Create new commit

          # Working with changes
          a = [ "squash" ]; # Amend/squash into parent
          sp = [ "split" ];
          ab = [ "abandon" ];

          # History exploration
          p = [
            "log"
            "-r"
            "@-"
          ]; # Show previous commit
          pp = [
            "log"
            "-r"
            "@--"
          ]; # Show grandparent commit
          r = [
            "log"
            "-r"
            "root()"
          ];

          # Useful queries
          mine = [
            "log"
            "-r"
            "mine()"
          ]; # Your commits
          conflicts = [
            "log"
            "-r"
            "conflict()"
          ];
          heads = [
            "log"
            "-r"
            "heads()"
          ];
        };
      };
    };
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
        theme = "Gruvbox Dark Hard";
        window-decoration = "none";
        # bell-features = "system, attention";
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

      userCommands = {
        NavigateToTest = {
          command.__raw = ''
            function(opts)
              local direction = opts.args or "next"
              local test_pattern = [[\v^\s*(test|def test_|it\s+['"])]]
              local current_line = vim.fn.line('.')

              if direction == "next" then
                -- Search forward for next test
                local last_line = vim.fn.line('$')

                for line_num = current_line + 1, last_line do
                  local line = vim.fn.getline(line_num)
                  if vim.fn.match(line, test_pattern) >= 0 then
                    -- Move to the test line
                    vim.cmd('normal! ' .. line_num .. 'G')

                    -- Position test in top third of window
                    local winheight = vim.fn.winheight(0)
                    local top_third = math.floor(winheight / 3)
                    vim.cmd('normal! zt')
                    vim.cmd('normal! ' .. top_third .. 'k')
                    vim.cmd('normal! ' .. top_third .. 'j')

                    return
                  end
                end

                print("No more tests found")
              else
                -- Search backward for previous test
                for line_num = current_line - 1, 1, -1 do
                  local line = vim.fn.getline(line_num)
                  if vim.fn.match(line, test_pattern) >= 0 then
                    -- Move to the test line
                    vim.cmd('normal! ' .. line_num .. 'G')

                    -- Position test in top third of window
                    local winheight = vim.fn.winheight(0)
                    local top_third = math.floor(winheight / 3)
                    vim.cmd('normal! zt')
                    vim.cmd('normal! ' .. top_third .. 'k')
                    vim.cmd('normal! ' .. top_third .. 'j')

                    return
                  end
                end

                print("No previous tests found")
              end
            end
          '';
          desc = "Navigate to next or previous test";
          nargs = "?";
        };
      };

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
          action = "<cmd>TestFile HEADLESS=1<CR>";
          key = "<leader>tf";
          mode = "n";
          options = {
            desc = "TestFile";
          };
        }
        {
          action = "<cmd>TestNearest HEADLESS=1<CR>";
          key = "<leader>tt";
          mode = "n";
          options = {
            desc = "TestNearest";
          };
        }
        {
          action = "<cmd>TestSuite HEADLESS=1<CR>";
          key = "<leader>ts";
          mode = "n";
          options = {
            desc = "TestSuite";
          };
        }
        {
          action = "<cmd>TestFile HEADLESS=0<CR>";
          key = "<leader>thf";
          mode = "n";
          options = {
            desc = "TestFile in the browser";
          };
        }
        {
          action = "<cmd>TestNearest HEADLESS=0<CR>";
          key = "<leader>tht";
          mode = "n";
          options = {
            desc = "TestNearest in the browser";
          };
        }
        {
          action = "<cmd>TestSuite HEADLESS=0<CR>";
          key = "<leader>ths";
          mode = "n";
          options = {
            desc = "TestSuite in the browser";
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
          mode = "n";
          key = "]c";
          action.__raw = ''
            function()
              if vim.wo.diff then
                vim.cmd.normal({']c', bang = true})
              else
                require('gitsigns').nav_hunk('next')
              end
            end
          '';
          options = {
            silent = true;
            desc = "Next hunk";
          };
        }
        {
          mode = "n";
          key = "[c";
          action.__raw = ''
            function()
              if vim.wo.diff then
                vim.cmd.normal({'[c', bang = true})
              else
                require('gitsigns').nav_hunk('prev')
              end
            end
          '';
          options = {
            silent = true;
            desc = "Previous hunk";
          };
        }
        {
          mode = "n";
          key = "<leader>ghs";
          action = ":Gitsigns stage_hunk<CR>";
          options = {
            silent = true;
            desc = "Stage hunk";
          };
        }
        {
          mode = "n";
          key = "<leader>ghr";
          action = ":Gitsigns reset_hunk<CR>";
          options = {
            silent = true;
            desc = "Reset hunk";
          };
        }
        {
          mode = "v";
          key = "<leader>ghs";
          action.__raw = ''
            function()
              require('gitsigns').stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end
          '';
          options = {
            silent = true;
            desc = "Stage hunk (visual)";
          };
        }
        {
          mode = "v";
          key = "<leader>ghr";
          action.__raw = ''
            function()
              require('gitsigns').reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end
          '';
          options = {
            silent = true;
            desc = "Reset hunk (visual)";
          };
        }
        {
          mode = "n";
          key = "<leader>ghp";
          action = ":Gitsigns preview_hunk<CR>";
          options = {
            silent = true;
            desc = "Preview hunk";
          };
        }
        {
          mode = "n";
          key = "<leader>ghi";
          action = ":Gitsigns preview_hunk_inline<CR>";
          options = {
            silent = true;
            desc = "Preview hunk inline";
          };
        }
        {
          mode = "n";
          key = "<leader>ghD";
          action.__raw = ''
            function()
              require('gitsigns').diffthis('~')
            end
          '';
          options = {
            silent = true;
            desc = "Diff this ~";
          };
        }
        {
          mode = "n";
          key = "<leader>ghQ";
          action.__raw = ''
            function()
              require('gitsigns').setqflist('all')
            end
          '';
          options = {
            silent = true;
            desc = "Set quickfix list (all)";
          };
        }
        {
          mode = "n";
          key = "<leader>ghq";
          action = ":Gitsigns setqflist<CR>";
          options = {
            silent = true;
            desc = "Set quickfix list";
          };
        }
        {
          mode = "n";
          key = "<leader>gtb";
          action = ":Gitsigns toggle_current_line_blame<CR>";
          options = {
            silent = true;
            desc = "Toggle line blame";
          };
        }
        {
          mode = "n";
          key = "<leader>gtw";
          action = ":Gitsigns toggle_word_diff<CR>";
          options = {
            silent = true;
            desc = "Toggle word diff";
          };
        }
        {
          mode = [
            "o"
            "x"
          ];
          key = "ih";
          action = ":Gitsigns select_hunk<CR>";
          options = {
            silent = true;
            desc = "Select hunk";
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
        {
          mode = "n";
          key = "]t";
          action = ":NavigateToTest next<CR>";
          options = {
            silent = true;
            desc = "Next minitest";
          };
        }
        {
          mode = "n";
          key = "[t";
          action = ":NavigateToTest prev<CR>";
          options = {
            silent = true;
            desc = "Previous minitest";
          };
        }
        {
          mode = "n";
          key = "<leader>tw";
          action.__raw = ''
            function()
              require('mini.trailspace').trim()
            end
          '';
          options = {
            silent = true;
            desc = "Trim trailing whitespace";
          };
        }
        {
          mode = "n";
          key = "<leader>tW";
          action.__raw = ''
            function()
              require('mini.trailspace').trim_last_lines()
            end
          '';
          options = {
            silent = true;
            desc = "Trim trailing empty lines";
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
        tabstop = 2;
      };

      plugins = {
        render-markdown.enable = true;
        numbertoggle.enable = false;
        nvim-surround.enable = true;
        mini = {
          enable = true;
          modules = {
            trailspace = {
              only_in_normal_buffers = true;
            };
          };
        };
        gitgutter.enable = true;
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
                { name = "vim-dadbod-completion"; }
                { name = "buffer"; }
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
              { name = "nvim_lsp"; }
              { name = "buffer"; }
              { name = "luasnip"; }
              { name = "path"; }
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
              "<C-y>" =
                "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.insert, select = true }, { 'i', 's' })";
              "<C-b>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
            };
          };
        };
        gitlinker = {
          enable = true;
          settings = {
            callbacks = {
              "github.com".__raw = "require('gitlinker.hosts').get_github_type_url";
            };
          };
        };
        lspkind = {
          enable = false;
          settings = {
            maxwidth = 50;
            ellipsis_char = "...";
            symbol_map = {
              Copilot = "";
            };
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
            gopls.enable = true;
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
              extraOptions = {
                on_attach = {
                  __raw = ''
                    function(client, bufnr)
                      -- Disable formatting to avoid RuboCop errors
                      client.server_capabilities.documentFormattingProvider = false
                      client.server_capabilities.documentRangeFormattingProvider = false
                    end
                  '';
                };
              };
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
              golangci_lint.enable = true;
              checkmake.enable = true;
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
              gofmt.enable = true;
              goimports.enable = true;
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
          event = [ "TermOpen" ];
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
          event = [ "FileType" ];
          pattern = [ "gitcommit" ];
          callback = {
            __raw = ''
              function()
                vim.opt.colorcolumn = "72"
              end
            '';
          };
        }
        {
          event = [ "BufWritePre" ];
          pattern = [ "*" ];
          callback = {
            __raw = ''
              function()
                require('mini.trailspace').trim()
                require('mini.trailspace').trim_last_lines()
              end
            '';
          };
        }
      ];

      extraPlugins = with pkgs.vimPlugins; [ direnv-vim ];
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
        bf = "bun format";
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
        germ = "dict -d fd-deu-eng";
        gl = "git log";
        gv = "open_modified_and_untracked_in_vim";
        gvh = "open_changed_from_head_in_vim";
        gvv = "edit_diff_files_in_vim";
        i3b = "list-i3-keybindings | fzf";
        ls = "ls -GF";
        pbcopy = "xclip";
        pbpaste = "xclip -o";
        show-git-remote-authors = "git for-each-ref --format=' %(authorname) %09 %(refname)' --sort=authorname | grep remote";
        showtodos = "git grep -l TODO | xargs -n1 git blame --show-email -f | grep TODO  | sed -E 's/[[:blank:]]+/ /g' | sort -k 4";
        strip = "sed $'s,x1b\\[[0-9;]*[a-zA-Z],,g;s,\r$,,g'";
      };
      initContent = ''
        ${builtins.readFile ./../../config/zshrc}

        ${builtins.readFile ./../../config/functions}

        # Generate pgbox completion if available
        if command -v pgbox >/dev/null 2>&1; then
          eval "$(pgbox completion zsh)"
        fi

        # Tmux window renaming hooks
        if [[ -n "$TMUX" ]]; then
          # Function to rename tmux window
          tmux_rename_window() {
            if [[ -n "$1" ]]; then
              tmux rename-window "$1" 2>/dev/null
            fi
          }

          # Variable to store the last meaningful window name
          typeset -g TMUX_LAST_WINDOW_NAME=""

          # Hook that runs before command execution
          preexec() {
            local cmd="$1"
            local cmd_name="''${cmd%% *}"

            # Skip renaming for job control commands
            if [[ "$cmd_name" =~ ^(fg|bg|jobs)$ ]]; then
              return
            fi

            # Store current window name before changing it
            TMUX_LAST_WINDOW_NAME=$(tmux display-message -p '#W' 2>/dev/null)

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
      enableBashIntegration = true; # see note on other shells below
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
        hosts = [ "https://github.com" ];
      };
    };

    difftastic = {
      enable = false;
    };

    git = {
      enable = true;
      ignores = [
        ".envrc"
        ".direnv/"
      ];
      lfs.enable = true;
      settings = {
        user = {
          name = "Ara Hacopian";
          email = "ara@hacopian.de";
        };
        alias = {
          aa = "add --all";
          amend = "commit --amend";
          br = "branch";
          ci = "commit";
          cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
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
          today = "log --since=midnight --author='ahacop' --oneline";
          yesterday = "log --since=midnight.yesterday --until=midnight --author='ahacop' --oneline";
          churn = "!f() { git log --all -M -C --name-only --format='format:' \"$@\" | sort | grep -v '^$' | uniq -c | sort -n; }; f";
        };
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

        # Move current window one position left
        bind-key < swap-window -t -1

        # Move current window one position right
        bind-key > swap-window -t +1

        # Allow window renaming by shell hooks
        set-option -g allow-rename on
        set-window-option -g automatic-rename off
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
      ".config/fish/functions/gc-ai.fish".source = ./../../scripts/gc-ai.fish;
      ".tigrc".text = ''
        bind generic Y !sh -c 'commit=%(commit); echo $commit | /run/current-system/sw/bin/xclip -selection clipboard & echo $commit | /run/current-system/sw/bin/tmux load-buffer -'
      '';
    };

    stateVersion = "24.05";

    packages = with pkgs; [
      asciinema
      bat
      circumflex
      (claude-code-latest pkgs)
      devenv
      duckdb
      dysk
      fd
      firefox
      fzf
      htop
      jq
      mermaid-cli
      nodejs
      inputs.pgbox.packages.${pkgs.system}.default
      (pkgs.python3Packages.buildPythonApplication rec {
        pname = "pgxnclient";
        version = "1.3.2";
        pyproject = true;

        src = pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-sDQ+BEuNAET/S+WF7M4BR7EAfbeuixJ0O/IidYpOx9k=";
        };

        postPatch = ''
          # Fix the setup.py to remove pytest-runner requirement
          substituteInPlace setup.py \
            --replace "setup_requires = ['pytest-runner']" "" \
            --replace "setup_requires" "# setup_requires"
        '';

        build-system = with pkgs.python3Packages; [
          setuptools
          wheel
        ];

        dependencies = with pkgs.python3Packages; [
          six
        ];

        meta = with lib; {
          description = "Command line client for the PostgreSQL Extension Network";
          homepage = "https://pgxn.org/";
          license = licenses.bsd3;
        };
      })
      presenterm
      readest
      ripgrep
      rofi
      silicon
      tig
      tldr
      tree
      dunst
    ];
    sessionVariables = {
      PAGER = "less -FirSwX";
      # Force software rendering for kitty in VM environment
      LIBGL_ALWAYS_SOFTWARE = "1";
      MESA_GL_VERSION_OVERRIDE = "3.3";
    };
  };
}
