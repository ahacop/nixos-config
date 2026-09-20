{
  config,
  lib,
  inputs,
  llmAgentPackages,
  pkgs,
  user,
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

  nirisnap = pkgs.stdenv.mkDerivation {
    pname = "nirisnap";
    version = "1.1.0-unstable-2026-09-17";

    src = pkgs.fetchFromGitHub {
      owner = "sergionoodles";
      repo = "nirisnap";
      rev = "d1b8f4677db7a67fb2c0348f2b02c0892f320764";
      hash = "sha256-pkgYfxuJz9lYDVvL9PaYkgNOpR6Rn35txBLDwlboEo8=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      wayland-scanner
      qt6Packages.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtwayland
      kdePackages.layer-shell-qt
      wayland
    ];

    cmakeFlags = [ "-DBUILD_TESTING=OFF" ];

    # nirisnap runs these as child processes and looks them up on PATH:
    # wl-copy/wl-paste for the clipboard, tesseract for OCR, notify-send for
    # the capture-finished notification. It also runs `niri msg`, which comes
    # from the session's own niri on PATH.
    qtWrapperArgs = [
      "--prefix PATH : ${
        lib.makeBinPath (
          with pkgs;
          [
            wl-clipboard
            libnotify
            (tesseract5.override { enableLanguages = [ "eng" ]; })
          ]
        )
      }"
    ];

    meta = {
      description = "Native Wayland screenshot and annotation overlay for niri";
      homepage = "https://github.com/sergionoodles/nirisnap";
      license = lib.licenses.mit;
      mainProgram = "nirisnap";
    };
  };

  whisper-dictate = pkgs.writeShellApplication {
    name = "whisper-dictate";
    runtimeInputs = with pkgs; [
      ffmpeg
      whisper-cpp
      wtype
      libnotify
      coreutils
      gnused
    ];
    text = ''
      MODEL_NAME="''${WHISPER_DICTATE_MODEL:-medium.en}"
      MODEL_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/whisper-dictate"
      MODEL_FILE="$MODEL_DIR/ggml-$MODEL_NAME.bin"
      WAV="/tmp/whisper-dictate-$UID.wav"
      TXT="$WAV.txt"
      PIDFILE="/tmp/whisper-dictate-$UID.pid"

      mkdir -p "$MODEL_DIR"

      if [[ ! -f "$MODEL_FILE" ]]; then
        notify-send -t 5000 "Whisper" "Downloading $MODEL_NAME model (one-time)…"
        whisper-cpp-download-ggml-model "$MODEL_NAME" "$MODEL_DIR"
      fi

      if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        PID="$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
        kill -INT "$PID" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8; do
          kill -0 "$PID" 2>/dev/null || break
          sleep 0.25
        done
        notify-send -t 1500 "Whisper" "Transcribing…"
        whisper-cli -m "$MODEL_FILE" -f "$WAV" -nt -np -otxt >/dev/null 2>&1 || true
        TEXT=""
        if [[ -f "$TXT" ]]; then
          TEXT="$(tr -d '\n' < "$TXT" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        fi
        rm -f "$WAV" "$TXT"
        if [[ -n "$TEXT" ]]; then
          wtype -- "$TEXT"
        else
          notify-send -t 1500 "Whisper" "(no speech detected)"
        fi
      else
        rm -f "$WAV" "$TXT" "$PIDFILE"
        notify-send -t 1500 "Whisper" "Recording… (press again to stop)"
        ffmpeg -loglevel error -nostdin -f pulse -i default -ar 16000 -ac 1 -y "$WAV" >/dev/null 2>&1 &
        echo $! > "$PIDFILE"
      fi
    '';
  };
in
{
  stylix.targets.firefox.profileNames = [ "default" ];
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

    nixvim = {
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
              -- Kill existing ebook-viewer instances
              vim.fn.system([[pkill -9 -f ebook-viewer-wrapped]])

              print("Building EPUB...")
              vim.fn.system([[se build --output-dir=/tmp .]])
              local latest_epub = vim.fn.system([[ls -t /tmp/*.epub | head -n1]]):gsub([[%s+''$]], [[]])
              if latest_epub ~= [[]] then
                local cmd = {[[ebook-viewer]]}

                -- Check if current buffer is a text/*.xhtml file
                local current_file = vim.fn.expand([[%:.]])
                local chapter_file = current_file:match([[([^/]+%.xhtml)''$]])
                if chapter_file and current_file:match([[text/]]) then
                  table.insert(cmd, [[--open-at=toc-href-contains:]] .. chapter_file:gsub([[%.xhtml''$]], [[]]))
                  print("Opening " .. latest_epub .. " at " .. chapter_file)
                else
                  print("Opening " .. latest_epub)
                end

                table.insert(cmd, latest_epub)
                vim.fn.jobstart(cmd, {detach = true})
              else
                print("No EPUB found in /tmp")
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
              -- Kill existing ebook-viewer instances
              vim.fn.system([[pkill -9 -f ebook-viewer-wrapped]])

              -- Yank selection to register z
              vim.cmd([[normal! "zy]])
              local selection = vim.fn.getreg([[z]])

              print("Building EPUB...")
              vim.fn.system([[se build --output-dir=/tmp .]])
              local latest_epub = vim.fn.system([[ls -t /tmp/*.epub | head -n1]]):gsub([[%s+''$]], [[]])
              if latest_epub ~= [[]] then
                local cmd = {[[ebook-viewer]]}

                -- Strip HTML tags and whitespace
                local search_text = selection:gsub([[<[^>]+>]], [[]]):gsub([[^%s+]], [[]]):gsub([[%s+''$]], [[]])
                if search_text ~= [[]] then
                  table.insert(cmd, [[--open-at=search:]] .. search_text)
                  print("Opening " .. latest_epub .. " searching for: " .. search_text)
                else
                  print("Opening " .. latest_epub)
                end

                table.insert(cmd, latest_epub)
                vim.fn.jobstart(cmd, {detach = true})
              else
                print("No EPUB found in /tmp")
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
            # nixd.enable = true;
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
      # prefix = "C-x";
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

        plugins.enabled = [ "ahmedhossamdev/timezone-hub" ];

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
            actions.right = "panel-toggle ahmedhossamdev/timezone-hub:panel";
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
            # The two clipboard lines keep the "(sf)" and "(st)" suffixes the
            # old .desktop files carried, so typing sf or st still selects
            # them. `global` puts them in the unprefixed search as well.
            command = "printf '%s\\n' 'Clipboard: Sync from Host (sf)' 'Clipboard: Sync to Host (st)' 'Display: 1920x1080' 'Display: 7680x3200' 'Dictate: toggle'";
            exec = ''case "{selection}" in "Clipboard: Sync from Host (sf)") wl-copy -n < /host/ahacop/clipboard.txt && notify-send "Clipboard synced from host" ;; "Clipboard: Sync to Host (st)") wl-paste -n > /host/ahacop/clipboard.txt && notify-send "Clipboard synced to host" ;; "Display: 1920x1080") niri msg output Virtual-1 mode 1920x1080@60.000 ;; "Display: 7680x3200") niri msg output Virtual-1 mode 7680x3200@60.000 ;; "Dictate: toggle") whisper-dictate ;; esac'';
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
            exec = ''${pkgs.udiskie}/bin/udiskie-umount --detach "{selection}" && notify-send "Ejected {selection}"'';
          };
        };
      };
    };

    # The home-manager niri module builds a niri of its own solely to run
    # `niri validate` over the config generated below. Point it at the package
    # the system actually runs so the config is checked against the compositor
    # that reads it, and only one niri gets built.
    niri.package = pkgs.niri;

    niri.settings = {
      # Environment variables
      environment = {
        QT_QPA_PLATFORM = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
      };

      # Output configuration
      outputs."Virtual-1" = {
        scale = 1.5;
      };

      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
          repeat-delay = 400;
          repeat-rate = 30;
          track-layout = "window";
        };

        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };

        mouse = {
          accel-speed = 0.0;
          accel-profile = "flat";
        };

        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "10%";
        };

        workspace-auto-back-and-forth = true;
      };

      cursor = {
        hide-when-typing = true;
      };

      # Layout configuration
      layout = {
        gaps = 0;

        # The desktop background: everything niri does not cover with a window
        # is painted this color. Noctalia's wallpaper is off, so nothing draws
        # on top of it.
        background-color = config.lib.stylix.colors.withHashtag.base00;

        # center-focused-column = "on-overflow";

        # Make windows share space (two windows visible side by side)
        # default-column-width = {
        #   proportion = 0.5;
        # };
        #
        # preset-column-widths = [
        #   { proportion = 1.0 / 3.0; }
        #   { proportion = 1.0 / 2.0; }
        #   { proportion = 2.0 / 3.0; }
        # ];
      };

      animations = {
        enable = true;
      };

      # niri --session exports WAYLAND_DISPLAY and XDG_CURRENT_DESKTOP to
      # systemd and D-Bus on its own, so nothing here has to.
      spawn-at-startup = [
        { command = [ "noctalia" ]; }
      ];

      window-rules = [
        {
          matches = [
            {
              app-id = "firefox$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
        }

        # Dialogs and popups - floating by default
        {
          matches = [
            { title = "^Open File$"; }
            { title = "^Save File$"; }
            { title = "^Save As$"; }
          ];
          open-floating = true;
        }
      ];

      binds = with config.lib.niri.actions; {
        "Mod+Shift+Slash".action = show-hotkey-overlay;

        "Mod+Return".action = spawn "ghostty";

        # Noctalia surfaces. Every one is a toggle, so the same key closes it.
        "Mod+D".action = spawn-sh "noctalia msg panel-toggle launcher";
        "Mod+Space".action = spawn-sh "noctalia msg panel-toggle control-center";
        "Mod+Shift+C".action = spawn-sh "noctalia msg panel-toggle clipboard";
        "Mod+Shift+Comma".action = spawn-sh "noctalia msg settings-toggle";
        "Mod+Tab".action = spawn-sh "noctalia msg window-switcher";
        "Mod+Shift+Escape".action = spawn-sh "noctalia msg session lock";

        "Mod+Shift+Backslash" = {
          action = spawn "whisper-dictate";
          repeat = false;
        };

        "Super+Alt+S" = {
          action = spawn-sh "pkill orca || exec orca";
          allow-when-locked = true;
        };

        "XF86AudioRaiseVolume" = {
          action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          allow-when-locked = true;
        };

        "XF86AudioPlay" = {
          action = spawn-sh "playerctl play-pause";
          allow-when-locked = true;
        };
        "XF86AudioStop" = {
          action = spawn-sh "playerctl stop";
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action = spawn-sh "playerctl previous";
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action = spawn-sh "playerctl next";
          allow-when-locked = true;
        };

        "XF86MonBrightnessUp" = {
          action = spawn [
            "brightnessctl"
            "--class=backlight"
            "set"
            "+10%"
          ];
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = spawn [
            "brightnessctl"
            "--class=backlight"
            "set"
            "10%-"
          ];
          allow-when-locked = true;
        };

        "Mod+O" = {
          action = toggle-overview;
          repeat = false;
        };

        "Mod+W" = {
          action = close-window;
          repeat = false;
        };

        "Mod+Left".action = focus-column-left;
        "Mod+Down".action = focus-window-down;
        "Mod+Up".action = focus-window-up;
        "Mod+Right".action = focus-column-right;
        "Mod+H".action = focus-column-left;
        "Mod+J".action = focus-window-down;
        "Mod+K".action = focus-window-up;
        "Mod+L".action = focus-column-right;

        "Mod+Ctrl+Left".action = move-column-left;
        "Mod+Ctrl+Down".action = move-window-down;
        "Mod+Ctrl+Up".action = move-window-up;
        "Mod+Ctrl+Right".action = move-column-right;
        "Mod+Ctrl+H".action = move-column-left;
        "Mod+Ctrl+J".action = move-window-down;
        "Mod+Ctrl+K".action = move-window-up;
        "Mod+Ctrl+L".action = move-column-right;

        "Mod+Home".action = focus-column-first;
        "Mod+End".action = focus-column-last;
        "Mod+Ctrl+Home".action = move-column-to-first;
        "Mod+Ctrl+End".action = move-column-to-last;

        "Mod+Shift+Left".action = focus-monitor-left;
        "Mod+Shift+Down".action = focus-monitor-down;
        "Mod+Shift+Up".action = focus-monitor-up;
        "Mod+Shift+Right".action = focus-monitor-right;
        "Mod+Shift+H".action = focus-monitor-left;
        "Mod+Shift+J".action = focus-monitor-down;
        "Mod+Shift+K".action = focus-monitor-up;
        "Mod+Shift+L".action = focus-monitor-right;

        "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
        "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

        "Mod+BracketLeft".action = consume-or-expel-window-left;
        "Mod+BracketRight".action = consume-or-expel-window-right;

        "Mod+Comma".action = consume-window-into-column;
        "Mod+Period".action = expel-window-from-column;

        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+Ctrl+R".action = reset-window-height;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;

        "Mod+Ctrl+F".action = expand-column-to-available-width;

        "Mod+C".action = center-column;
        "Mod+Ctrl+C".action = center-visible-columns;

        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";

        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";

        "Mod+V".action = toggle-window-floating;
        "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

        "Mod+Shift+W".action = toggle-column-tabbed-display;

        "Mod+Escape" = {
          action = toggle-keyboard-shortcuts-inhibit;
          allow-inhibiting = false;
        };

        "Mod+Shift+X".action = quit;

        # nirisnap has no window mode, so window capture stays on niri's
        # built-in screenshot action.
        "Mod+P".action = spawn "nirisnap";
        "Mod+Ctrl+P".action = spawn [
          "nirisnap"
          "--capture-fullscreen"
        ];
        "Mod+Alt+P".action.screenshot-window = [ ];

        "Mod+Shift+P".action = power-off-monitors;
      };
    };
  };

  xdg.enable = true;
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "text/plain" = [ "nvim-ghostty.desktop" ];
      "text/markdown" = [ "nvim-ghostty.desktop" ];
      "text/x-shellscript" = [ "nvim-ghostty.desktop" ];
    };
  };

  home = {
    username = user;
    homeDirectory = "/home/${user}";

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
      # flake.nix from the llmAgentNames single source of truth and passed in
      # via extraSpecialArgs.
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
        # inputs.pgbox.packages.${pkgs.stdenv.hostPlatform.system}.default
        mermaid-cli
        nirisnap
        pomodoro
        presenterm
        sdcv
        udiskie # puts udiskie-umount and udiskie-info on the PATH; the daemon is services.udiskie above
        vale
        websters-1913-stardict
        whisper-dictate
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
