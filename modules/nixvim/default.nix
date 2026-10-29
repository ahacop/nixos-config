# Neovim, configured through Nixvim, and the "Neovim" desktop entry that
# opens files in Neovim inside Ghostty.
{ inputs, ... }:
{
  flake.modules.homeManager.nixvim =
    { pkgs, ... }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];

      programs.nixvim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withRuby = false;
        # Skip the generated `man nixvim` option reference. Rendering it walks
        # every nixvim option and costs about two seconds of every evaluation.
        enableMan = false;

        # Nixvim pins its own tested nixpkgs, but we build it against the system
        # nixpkgs (single nixpkgs across the whole config). Set the source
        # explicitly to silence nixvim's follows/skew warning.
        nixpkgs.source = pkgs.path;

        globals = {
          mapleader = " ";
        };

        extraConfigVim = ''
          cnoremap %% <C-R>=expand('%:h').'/'<cr>
        '';

        extraConfigLua = ''
          local function dig(name, code)
            vim.cmd(string.format("digraph %s %d", name, code))
          end

          -- Standard Ebooks typography. One table drives two things per char:
          --   * an insert-mode digraph   (Ctrl-K ,x)  for typing mid-prose
          --   * a normal-mode keymap     (<leader>s,x) that drops it at cursor
          -- Comma is the shared mnemonic between both.
          local se_chars = {
            -- Curly quotes
            { "l", 8216, "‘ left single quote" },
            { "r", 8217, "’ right single quote" },
            { "L", 8220, "“ left double quote" },
            { "R", 8221, "” right double quote" },
            -- Spaces
            { "s", 160, "no-break space" },
            { "t", 8201, "thin space" },
            { "h", 8202, "hair space" },
            -- Dashes
            { "n", 8211, "– en dash" },
            { "m", 8212, "— em dash" },
            -- Ellipsis
            { ".", 8230, "… ellipsis" },
          }
          for _, e in ipairs(se_chars) do
            local key, code, desc = e[1], e[2], e[3]
            dig("," .. key, code)
            vim.keymap.set("n", "<leader>s," .. key, function()
              vim.api.nvim_put({ vim.fn.nr2char(code, 1) }, "c", true, true)
            end, { desc = desc })
          end

          -- Standard Ebooks preview for the <leader>sb keymaps. It builds the
          -- book in the current directory into /tmp and opens the newest EPUB
          -- there in ebook-viewer. open_at is a value for the --open-at option
          -- of ebook-viewer, or nil to open at the start. where is the text
          -- that the status message shows after the EPUB path. Running viewers
          -- are killed first, so only one preview is open.
          function _G.se_build_preview(open_at, where)
            vim.fn.system([[pkill -9 -f ebook-viewer-wrapped]])

            print("Building EPUB...")
            vim.fn.system([[se build --output-dir=/tmp .]])
            local latest_epub = vim.fn.system([[ls -t /tmp/*.epub | head -n1]]):gsub([[%s+''$]], [[]])
            if latest_epub == [[]] then
              print("No EPUB found in /tmp")
              return
            end

            local cmd = { [[ebook-viewer]] }
            if open_at then
              table.insert(cmd, [[--open-at=]] .. open_at)
              print("Opening " .. latest_epub .. " " .. where)
            else
              print("Opening " .. latest_epub)
            end
            table.insert(cmd, latest_epub)
            vim.fn.jobstart(cmd, { detach = true })
          end

          -- WordNet thesaurus functions
          local function wordnet_lookup(word)
            local output = vim.fn.systemlist("wn " .. vim.fn.shellescape(word) .. " -synsn -synsv -synsa -antsn -antsv -antsa 2>/dev/null")
            if vim.v.shell_error ~= 0 or #output == 0 then
              return nil
            end
            return output
          end

          -- Show WordNet results in a floating window
          function _G.wordnet_float(word)
            word = word or vim.fn.expand("<cword>")
            local output = wordnet_lookup(word)
            if not output then
              vim.notify("No results for: " .. word, vim.log.levels.WARN)
              return
            end

            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
            vim.api.nvim_set_option_value("filetype", "wordnet", { buf = buf })

            local width = math.min(80, vim.o.columns - 4)
            local height = math.min(#output, vim.o.lines - 4)
            local win = vim.api.nvim_open_win(buf, true, {
              relative = "cursor",
              row = 1,
              col = 0,
              width = width,
              height = height,
              style = "minimal",
              border = "rounded",
              title = " Thesaurus: " .. word .. " ",
              title_pos = "center",
            })

            vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
            vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
          end

          -- Telescope picker for WordNet
          function _G.telescope_wordnet()
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local conf = require("telescope.config").values
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local previewers = require("telescope.previewers")

            local current_word = vim.fn.expand("<cword>")

            pickers.new({}, {
              prompt_title = "WordNet Thesaurus",
              default_text = current_word,
              finder = finders.new_dynamic({
                fn = function(prompt)
                  if not prompt or prompt == "" then return {} end
                  local output = vim.fn.systemlist("wn " .. vim.fn.shellescape(prompt) .. " -synsn -synsv -synsa 2>/dev/null")
                  if vim.v.shell_error ~= 0 then return {} end

                  -- Parse synonyms from output
                  local synonyms = {}
                  local seen = {}
                  for _, line in ipairs(output) do
                    -- Match words in synonym lines (after =>)
                    local syn_match = line:match("=>%s*(.+)")
                    if syn_match then
                      for word in syn_match:gmatch("([%w_-]+)") do
                        if not seen[word] and word ~= prompt then
                          seen[word] = true
                          table.insert(synonyms, word)
                        end
                      end
                    end
                  end
                  return synonyms
                end,
                entry_maker = function(entry)
                  return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                  }
                end,
              }),
              sorter = conf.generic_sorter({}),
              previewer = previewers.new_buffer_previewer({
                title = "WordNet Definition",
                define_preview = function(self, entry)
                  local output = vim.fn.systemlist("wn " .. vim.fn.shellescape(entry.value) .. " -over 2>/dev/null")
                  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, output)
                end,
              }),
              attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  if selection then
                    vim.cmd("normal! ciw" .. selection.value)
                  end
                end)
                return true
              end,
            }):find()
          end

          -- Telescope picker for the Lean unicode abbreviations that lean.nvim
          -- expands after a backslash. Each row is one symbol with every name
          -- that types it, shortest name first. The search matches the symbol
          -- and the names. Enter puts the symbol after the cursor.
          --
          -- The picker reads lean.nvim's abbreviations.json from the runtimepath.
          -- require("lean.abbreviations").load() is not usable here: it finds the
          -- file relative to the calling file, so a call from init.lua fails.
          function _G.telescope_lean_symbols()
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local conf = require("telescope.config").values
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            local path = vim.api.nvim_get_runtime_file("vscode-lean/abbreviations.json", false)[1]
            if not path then
              vim.notify("lean.nvim abbreviations.json not found", vim.log.levels.ERROR)
              return
            end
            local abbreviations = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))

            local names_by_symbol = {}
            for name, symbol in pairs(abbreviations) do
              names_by_symbol[symbol] = names_by_symbol[symbol] or {}
              table.insert(names_by_symbol[symbol], name)
            end

            local rows = {}
            for symbol, names in pairs(names_by_symbol) do
              table.sort(names, function(a, b)
                if #a ~= #b then return #a < #b end
                return a < b
              end)
              local typed = vim.tbl_map(function(name) return "\\" .. name end, names)
              table.insert(rows, { symbol = symbol, text = table.concat(typed, "  ") })
            end
            table.sort(rows, function(a, b) return a.text < b.text end)

            pickers.new({}, {
              prompt_title = "Lean Symbols",
              finder = finders.new_table({
                results = rows,
                entry_maker = function(row)
                  return {
                    value = row.symbol,
                    display = row.symbol .. "  " .. row.text,
                    ordinal = row.symbol .. " " .. row.text,
                  }
                end,
              }),
              sorter = conf.generic_sorter({}),
              attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  if selection then
                    vim.api.nvim_put({ selection.value }, "c", true, true)
                  end
                end)
                return true
              end,
            }):find()
          end
        '';

        userCommands = {
          ClaudeRecentPlan = {
            command.__raw = ''
              function()
                local plans_dir = vim.fn.expand("~/.claude/plans")
                local handle = io.popen("ls -t " .. plans_dir .. " 2>/dev/null | head -n1")
                if handle then
                  local result = handle:read("*a")
                  handle:close()
                  local filename = result:gsub("%s+$", "")
                  if filename ~= "" then
                    vim.cmd("edit " .. plans_dir .. "/" .. filename)
                  else
                    print("No plans found in ~/.claude/plans")
                  end
                else
                  print("Could not access ~/.claude/plans")
                end
              end
            '';
            desc = "Open the most recent Claude plan";
          };

          ClaudePlans = {
            command.__raw = ''
              function()
                local plans_dir = vim.fn.expand("~/.claude/plans")
                -- Use Telescope if available, otherwise use netrw
                local ok, telescope = pcall(require, "telescope.builtin")
                if ok then
                  telescope.find_files({
                    cwd = plans_dir,
                    prompt_title = "Claude Plans",
                    sorting_strategy = "ascending",
                    file_ignore_patterns = {},
                    find_command = { "ls", "-t", plans_dir },
                  })
                else
                  -- Fallback: open directory in netrw
                  vim.cmd("Explore " .. plans_dir)
                end
              end
            '';
            desc = "Browse Claude plans sorted by most recent";
          };

          NavigateToTest = {
            command.__raw = ''
              function(opts)
                local test_pattern = [[\v^\s*(test|def test_|it\s+['"])]]
                -- With no argument, opts.args is "", so anything but "prev"
                -- searches forward.
                local step = opts.args == "prev" and -1 or 1
                local last = step == 1 and vim.fn.line('$') or 1

                for line_num = vim.fn.line('.') + step, last, step do
                  if vim.fn.match(vim.fn.getline(line_num), test_pattern) >= 0 then
                    vim.cmd('normal! ' .. line_num .. 'G')

                    -- Put the test line one third of the way down the window.
                    local top_third = math.floor(vim.fn.winheight(0) / 3)
                    vim.cmd('normal! zt')
                    vim.cmd('normal! ' .. top_third .. 'k')
                    vim.cmd('normal! ' .. top_third .. 'j')
                    return
                  end
                end

                print(step == 1 and "No more tests found" or "No previous tests found")
              end
            '';
            desc = "Navigate to next or previous test";
            nargs = "?";
          };
        };

        keymaps = [
          {
            action = "<cmd>ClaudeRecentPlan<CR>";
            key = "<leader>cr";
            mode = "n";
            options = {
              silent = true;
              desc = "Open most recent Claude plan";
            };
          }
          {
            action = "<cmd>ClaudePlans<CR>";
            key = "<leader>cp";
            mode = "n";
            options = {
              silent = true;
              desc = "Browse Claude plans";
            };
          }
          {
            action.__raw = "function() _G.wordnet_float() end";
            key = "<leader>wt";
            mode = "n";
            options = {
              silent = true;
              desc = "WordNet thesaurus (word under cursor)";
            };
          }
          {
            action.__raw = "function() _G.telescope_wordnet() end";
            key = "<leader>wT";
            mode = "n";
            options = {
              silent = true;
              desc = "WordNet thesaurus (Telescope)";
            };
          }
          {
            action.__raw = "function() _G.telescope_lean_symbols() end";
            key = "<leader>lu";
            mode = "n";
            options = {
              silent = true;
              desc = "Lean unicode symbols (Telescope)";
            };
          }
          {
            action = ":!se titlecase --no-newline<CR>";
            key = "<leader>st";
            mode = "v";
            options = {
              silent = true;
              desc = "SE titlecase selection";
            };
          }
          {
            action.__raw = ''
              function()
                -- if there is an active search highlight and we are not in the quickfix
                local shouldClearHighlight = vim.bo[0].buftype ~= 'quickfix' and vim.v.hlsearch ~= 0

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
          {
            mode = "n";
            key = "<leader>sb";
            action.__raw = ''
              function()
                -- In a text/*.xhtml chapter, open the EPUB at that chapter.
                local current_file = vim.fn.expand([[%:.]])
                local chapter_file = current_file:match([[([^/]+%.xhtml)''$]])
                if chapter_file and current_file:match([[text/]]) then
                  local chapter = chapter_file:gsub([[%.xhtml''$]], [[]])
                  _G.se_build_preview([[toc-href-contains:]] .. chapter, "at " .. chapter_file)
                else
                  _G.se_build_preview(nil)
                end
              end
            '';
            options = {
              silent = false;
              desc = "SE build + preview EPUB";
            };
          }
          {
            mode = "x";
            key = "<leader>sb";
            action.__raw = ''
              function()
                -- Yank selection to register z
                vim.cmd([[normal! "zy]])
                local selection = vim.fn.getreg([[z]])

                -- Strip HTML tags and whitespace
                local search_text = selection:gsub([[<[^>]+>]], [[]]):gsub([[^%s+]], [[]]):gsub([[%s+''$]], [[]])
                if search_text ~= [[]] then
                  _G.se_build_preview([[search:]] .. search_text, "searching for: " .. search_text)
                else
                  _G.se_build_preview(nil)
                end
              end
            '';
            options = {
              silent = false;
              desc = "SE build + preview EPUB at selection";
            };
          }
          {
            mode = "x";
            key = "<leader>sp";
            action.__raw = ''
              function()
                -- Yank selection to register z
                vim.cmd([[normal! "zy]])
                local selection = vim.fn.getreg([[z]])

                -- Strip HTML tags and surrounding whitespace
                local search_text = selection:gsub([[<[^>]+>]], [[]]):gsub([[^%s+]], [[]]):gsub([[%s+''$]], [[]])
                if search_text == [[]] then
                  print("No text selected")
                  return
                end

                print("Opening page scans for: " .. search_text)
                vim.fn.jobstart({[[se-ext]], [[page-scans]], [[-s]], search_text}, {detach = true})
              end
            '';
            options = {
              silent = false;
              desc = "SE page scans for selection";
            };
          }
          {
            action.__raw = "function() require('aoc').input() end";
            key = "<leader>ai";
            mode = "n";
            options = {
              silent = true;
              desc = "AoC input buffer";
            };
          }
          {
            action.__raw = "function() require('aoc').run() end";
            key = "<leader>ar";
            mode = "n";
            options = {
              silent = true;
              desc = "AoC run real input";
            };
          }
          {
            action.__raw = "function() require('aoc').example() end";
            key = "<leader>ae";
            mode = "n";
            options = {
              silent = true;
              desc = "AoC run example buffer";
            };
          }
          {
            action.__raw = "function() require('aoc').submit() end";
            key = "<leader>as";
            mode = "n";
            options = {
              silent = true;
              desc = "AoC submit";
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

        # Keep lean4 out of the nvim wrapper. The lean plugin below would
        # otherwise bake pkgs.lean4 into the wrapper ahead of the project's on
        # PATH, which makes every nixpkgs bump a lean4 build and can run the
        # wrong Lean version against a project's .olean files. The lean devflake
        # provides the toolchain per project and lean.nvim finds it on PATH via
        # direnv.
        dependencies.lean.enable = false;

        plugins = {
          # lean.nvim runs the Lean language server and adds the infoview: a
          # split that shows the goal state at the cursor and updates as the
          # cursor moves. It also installs the `\to` -> `→` style unicode
          # abbreviations and the `<LocalLeader>` mappings (i infoview, p pin,
          # t term goal, g restart file). The server is `lake serve` from the
          # lean4 toolchain on PATH, which the lean devflake provides.
          lean = {
            enable = true;
            settings = {
              lsp.enable = true;
              mappings = true;
              infoview.autoopen = true;
              # Turn off Kitty graphics inside tmux. At startup lean.nvim sends
              # a Kitty graphics query (`\e_Gi=99999,...`), and tmux takes that
              # text as the pane title, so it shows in the status bar.
              # tui/html.lua still loads kitty.lua without this check, so the
              # infoview can still send the query when it draws HTML.
              graphics.enabled.__raw = "vim.env.TMUX == nil";
            };
          };
          render-markdown.enable = true;
          nvim-surround.enable = true;
          mini = {
            enable = true;
            modules = {
              trailspace = {
                only_in_normal_buffers = true;
              };
            };
          };
          direnv.enable = true;
          vim-dadbod.enable = true;
          vim-dadbod-completion.enable = true;
          vim-dadbod-ui.enable = true;
          web-devicons.enable = true;
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
              performance = {
                debounce = 60;
                fetchingTimeout = 200;
                maxViewEntries = 30;
              };
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

              mapping = {
                "<C-n>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
                "<C-p>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
                "<C-y>" = "cmp.mapping.confirm({ select = true })";
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
          which-key = {
            enable = true;
            settings.spec = [
              {
                __unkeyed-1 = "<leader>s";
                group = "standard ebooks";
              }
              {
                __unkeyed-1 = "<leader>s,";
                group = "typography";
              }
            ];
          };
          treesitter = {
            enable = true;
            nixGrammars = true;
            settings.indent.enable = false;
            folding.enable = false;
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
            settings = {
              defaults = {
                file_ignore_patterns = [
                  "^.git/"
                  "node_modules/"
                ];
              };
              pickers = {
                find_files = {
                  hidden = true;
                };
              };
            };
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
            extensions = {
              fzf-native = {
                enable = true;
              };
            };
          };

          fugitive.enable = true;
          diffview.enable = true;
          endwise.enable = true;
          nvim-lightbulb.enable = true;
          comment.enable = true;
          lualine.enable = true;

          lsp = {
            enable = true;
            servers = {
              gopls.enable = true;
              bashls.enable = true;
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
              prolog_ls = {
                enable = true;
                # Use the swipl on PATH (the prolog devflake's, which has the
                # lsp_server pack baked in) rather than a nixvim-provided one.
                package = null;
                cmd = [
                  "swipl"
                  "-g"
                  "use_module(library(lsp_server))."
                  "-g"
                  "lsp_server:main"
                  "-t"
                  "halt"
                  "--"
                  "stdio"
                ];
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
                enable = true;
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
          vim-test.enable = true;
          trouble.enable = true;
          overseer.enable = true;

          lint = {
            enable = true;
            lintersByFt = {
              markdown = [ "vale" ];
              mdx = [ "vale" ];
            };
            autoCmd = {
              callback = {
                __raw = ''
                  function()
                    require('lint').try_lint()
                  end
                '';
              };
              event = [
                "BufWritePost"
                "BufReadPost"
                "InsertLeave"
              ];
            };
          };
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
                nixfmt.enable = true;
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

        # Vim maps .pl to perl by default; treat SWI-Prolog extensions as prolog
        # so prolog_ls attaches. .plt is SWI's test-file extension, .pro is the
        # Windows fallback when .pl conflicts with Perl.
        filetype = {
          extension = {
            pl = "prolog";
            plt = "prolog";
            pro = "prolog";
          };
        };

        autoGroups = {
          custom_term_open = {
            clear = true;
          };
        };

        autoCmd = [
          {
            event = [ "TextYankPost" ];
            callback = {
              __raw = ''
                function()
                  if vim.env.TMUX then
                    local text = vim.fn.getreg('"')
                    vim.fn.system({'tmux', 'set-buffer', text})
                  end
                end
              '';
            };
          }
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

        extraFiles."lua/aoc.lua".text = ''
          local M = {}

          local INPUT_BUFNAME = "aoc-input"

          local function args_from_buffer()
            local path = vim.api.nvim_buf_get_name(0)
            local year, day, part = path:match("solutions/(%d+)/day(%d+)_part(%d+)%.rb$")
            if not year then
              vim.notify("not an AoC solution: " .. path, vim.log.levels.WARN)
              return
            end
            return year, tostring(tonumber(day)), part
          end

          local function find_input_buf()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf)
                  and vim.api.nvim_buf_get_name(buf):match(INPUT_BUFNAME .. "$") then
                return buf
              end
            end
          end

          local function run_task(name, cmd)
            vim.cmd.write({ mods = { silent = true } })
            local overseer = require("overseer")
            local task = overseer.new_task({ name = name, cmd = cmd })
            task:start()
            overseer.open({ enter = false })
          end

          function M.input()
            local buf = find_input_buf()
            if buf then
              vim.cmd("buffer " .. buf)
            else
              vim.cmd("enew")
              vim.api.nvim_buf_set_name(0, INPUT_BUFNAME)
              vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "hide", false
            end
          end

          function M.run()
            local y, d, p = args_from_buffer()
            if y then
              run_task(("aoc run %s/%s/%s"):format(y, d, p), { "just", "run", y, d, p })
            end
          end

          function M.example()
            local y, d, p = args_from_buffer()
            if not y then return end
            local buf = find_input_buf()
            if not buf then
              vim.notify("no aoc-input buffer — <leader>ai to create one", vim.log.levels.WARN)
              return
            end
            local tmp = vim.fn.tempname()
            vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), tmp)
            run_task(
              ("aoc example %s/%s/%s"):format(y, d, p),
              ("just example %s %s %s < %s"):format(y, d, p, vim.fn.shellescape(tmp))
            )
          end

          function M.submit()
            local y, d, p = args_from_buffer()
            if y then
              run_task(("aoc submit %s/%s/%s"):format(y, d, p), { "just", "submit", y, d, p })
            end
          end

          return M
        '';
      };

      xdg.desktopEntries.nvim-ghostty = {
        name = "Neovim";
        genericName = "Text Editor";
        exec = "ghostty -e nvim %F";
        icon = "nvim";
        terminal = false;
        categories = [
          "Utility"
          "TextEditor"
        ];
        mimeType = [
          "text/plain"
          "text/markdown"
          "text/x-shellscript"
        ];
      };

      xdg.mimeApps.defaultApplications = {
        "text/plain" = [ "nvim-ghostty.desktop" ];
        "text/markdown" = [ "nvim-ghostty.desktop" ];
        "text/x-shellscript" = [ "nvim-ghostty.desktop" ];
      };
    };
}
