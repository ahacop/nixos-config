# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    <nixos-hardware/apple/macbook-air/6>
    /etc/nixos/hardware-configuration.nix
    <home-manager/nixos>
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/11f12cf6-c837-438b-8818-dc4ddb87aa2d";
      allowDiscards = true;

    };
  };


  networking = {
    hostName = "mopsliebe"; # Define your hostname.

    wireless.iwd.enable = true;

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    firewall = {
      allowedTCPPorts = [ 17500 ];
      allowedUDPPorts = [ 17500 ];
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.interfaces.wlp3s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  fonts = {
    fontconfig.defaultFonts.monospace = ["Inconsolata"];
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      font-awesome
      joypixels
      libertine
      noto-fonts-emoji
      dejavu_fonts
      inconsolata
    ];
  };

  environment.variables = {
    EDITOR = "nvim";
    XDG_CURRENT_DESKTOP = "Unity";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    bat
    ctags
    darktable
    docker-compose
    dropbox-cli
    dust
    elixir
    exa
    exercism
    fd
    firefox-wayland
    ffsend
    fzf
    gitAndTools.gitFull
    gnome3.seahorse
    graphviz
    isync
    kondo
    mpv
    mu
    neovim
    networkmanager
    ngrok
    nodejs
    pavucontrol
    procs
    ruby
    signal-desktop
    skim
    skype
    slack
    steam
    transmission-gtk
    tree
    vimb
    wget
    wirelesstools
    wofi
    xclip
    youtube-dl

    (emacsWithPackagesFromUsePackage {
      config = builtins.readFile ./dotfiles/emacs.el;

      # Package is optional, defaults to pkgs.emacs
      package = pkgs.emacsUnstable;

      # By default emacsWithPackagesFromUsePackage will only pull in packages with `:ensure t`.
      # Setting alwaysEnsure to true emulates `use-package-always-ensure` and pulls in all use-package references.
      alwaysEnsure = true;

      # Optionally provide extra packages not in the configuration file
      #extraEmacsPackages = epkgs: [
      #  epkgs.cask
      #];
      # Optionally override derivations
      #override = epkgs: epkgs // {
      #  weechat = epkgs.melpaPackages.weechat.overrideAttrs(old: {
      #    patches = [ ./weechat-el.patch ];
      #  });
      #};
    })
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.

  powerManagement.enable = true;
  location.provider = "geoclue2";

  services = {
    printing.enable = true;
    locate.enable = true;
    redshift = {
      enable = true;
      package = pkgs.redshift-wlr;
    };
    gnome3.gnome-keyring.enable = true;
    blueman.enable = true;

    postgresql = {
      enable = true;
      package = pkgs.postgresql_12;
    };

    xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "ctrl:nocaps";
      libinput = {
        enable = true;
        tapping = true;
        clickMethod = "clickfinger";
        disableWhileTyping = true;
        accelSpeed = "0.001";
      };
      displayManager = {
        defaultSession = "sway";
        autoLogin = {
          enable = true;
          user = "ahacop";
        };
        lightdm = {
          enable = true;
        };
      };
    };
  };

  nixpkgs.config.pulseaudio = true;
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      kanshi # autorandr
      mako # notification daemon
      (waybar.override {
        pulseSupport = true;
      })
      swayidle
      swaylock # lockscreen
      xwayland # for legacy apps
    ];
  };

  # FIXME: not sure if all this is really necessary
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    kdm.enableGnomeKeyring = true;
    lightdm.enableGnomeKeyring = true;
    sddm.enableGnomeKeyring = true;
    slim.enableGnomeKeyring = true;
  };

  # Enable sound.
  sound.enable = true;

  hardware = {
    brillo.enable = true;
    pulseaudio = {
      enable = true;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
      package = pkgs.pulseaudioFull;
      support32Bit = true;
    };

    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];

    bluetooth = {
      enable = true;
    };
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  users.users = {
    ahacop = {
      isNormalUser = true;
      description = "Ara Hacopian";
      extraGroups = [ "sway" "video" "docker" "disk" "audio" "wheel" "networkmanager" ];
    };
  };

  virtualisation.docker.enable = true;

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      #pinentryFlavor = "curses";
    };
    tmux.enable = true;
    evince.enable = true;
    bash = {
      enableCompletion = true;
      enableLsColors = true;
      interactiveShellInit = (builtins.readFile dotfiles/bashrc)
      + (builtins.readFile dotfiles/functions)
      + (builtins.readFile dotfiles/bin/git-prompt.sh)
      + (builtins.readFile dotfiles/bin/git-completion.bash);
      shellAliases = {
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
        pd = "pushd";
        gv = "open_modified_and_untracked_in_vim";
        gvh = "open_changed_from_head_in_vim";
        tat = "tmux attach -t `basename $PWD` || tmux new-session -As \"$(basename \"$PWD\" | tr . -)\"";
      };
    };
  };


  home-manager.useGlobalPkgs = true;
  home-manager.users.ahacop = { pkgs, ... }: {
    home.file.".emacs".source = ./dotfiles/emacs.el;
    home.file.".githelpers".source = ./dotfiles/githelpers;
    home.file.".gitignore.global".source = ./dotfiles/gitignore.global;
    home.file.".gemrc".source = ./dotfiles/gemrc;
    home.file.".tmux.conf".source = ./dotfiles/tmux.conf;
    home.file.".ctags".source = ./dotfiles/ctags;
    home.file.".mbsyncrc".source = ./dotfiles/mbsyncrc;
    home.file.".config/sway/config".source = ./dotfiles/sway.config;
    home.file.".config/waybar/config".source = ./dotfiles/waybar.config;
    home.file.".config/waybar/style.css".source = ./dotfiles/waybar.css;

    programs.git = {
      enable = true;
      userEmail = "ara@hacopian.de";
      userName = "Ara Hacopian";
      extraConfig = {
        credential.helper = "libsecret";
        github.user = "ahacop";
        merge.tool = "vimdiff";
      };
      aliases = {
        aa     = "add --all";
        amend  = "commit --amend";
        br     = "branch";
        ci     = "commit";
        co     = "checkout";
        dc     = "diff --cached";
        df     = "diff";
        dh1    = "diff HEAD~1";
        di     = "diff";
        ds     = "diff --stat";
        fa     = "fetch --all";
        ff     = "merge --ff-only";
        lg     = "log -p";
        noff   = "merge --no-ff";
        pom    = "push origin master";
        pullff = "pull --ff-only";
        st     = "status";

        # Divergence (commits we added and commits remote added)
        div = "divergence";

        # Goodness (summary of diff lines added/removed/total)
        gn  = "goodness";
        gnc = "goodness --cached";

        # Fancy logging.
        #   h  = head
        #   hp = head with patch
        #   r  = recent commits, only current branch
        #   ra = recent commits, all reachable refs
        #   l  = all commits, only current branch
        #   la = all commits, all reachable refs
        head = "!git l -1";
        h    = "!git head";
        hp   = "!. ~/.githelpers && show_git_head";
        r    = "!git l -30";
        ra   = "!git r --all";
        l    = "!. ~/.githelpers && pretty_git_log";
        la   = "!git l --all";
        today = "log --since=midnight --author='ahacop' --oneline";
        yesterday = "log --since=midnight.yesterday --until=midnight --author='ahacop' --oneline";
      };
    };

    programs.firefox = {
      enable = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        decentraleyes
        facebook-container
        https-everywhere
        multi-account-containers
        privacy-badger
        tridactyl
        ublock-origin
      ];
      profiles =
        let defaultSettings = {
          "app.update.auto" = false;
              "browser.startup.homepage" = "about:blank";
              "browser.ctrlTab.recentlyUsedOrder" = false;
              #"browser.newtabpage.enabled" = false;
              #"browser.bookmarks.showMobileBookmarks" = true;
              #"browser.uidensity" = 1;
              #"browser.urlbar.update1" = true;
              #"distribution.searchplugins.defaultLocale" = "en-GB";
              #"general.useragent.locale" = "en-GB";
              #"identity.fxaccounts.account.device.name" = config.networking.hostName;
              "privacy.trackingprotection.enabled" = true;
              "privacy.trackingprotection.socialtracking.enabled" = true;
              "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
              "services.sync.declinedEngines" = "addons,passwords,prefs";
              "services.sync.engine.addons" = false;
              "services.sync.engineStatusChanged.addons" = true;
              "services.sync.engine.passwords" = false;
              "services.sync.engine.prefs" = false;
              "services.sync.engineStatusChanged.prefs" = true;
              #"signon.rememberSignons" = false;
            };
        in {
          home = {
            id = 0;
            settings = defaultSettings // {
              "browser.urlbar.placeholderName" = "DuckDuckGo";
              "browser.urlbar.placeholderName.private" = "DuckDuckGo";
              "browser.search.hiddenOneOffs" = "Google,Amazon.com,Bing,Wikipedia (en)";
              "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = "";
              "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";
              "browser.search.region" = "US";
              #"toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
            #userChrome = builtins.readFile ../conf.d/userChrome.css;
          };
        };
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withRuby = true;
      plugins = with pkgs.vimPlugins; [
        fzf-vim
        matchit-zip
        vim-airline
        vim-airline-themes
        vim-colors-solarized
        vim-endwise
        vim-eunuch
        vim-fugitive
        vim-gutentags
        vim-polyglot
        vim-sensible
        vim-test
      ];
      extraConfig = ''
        let mapleader=','
        let g:solarized_termcolors=256

        set autowrite
        set fileformats=unix,dos,mac
        set hlsearch
        set ignorecase
        set number
        set shell=bash
        set showcmd
        set showmatch
        set showmode
        set smartcase
        set splitbelow
        set splitright
        "set textwidth=72
        set title
        set ts=2 sts=2 sw=2 expandtab
        set visualbell
        set wildmode=longest,list
        " vim-solarized settings
        if has('gui_running')
        set background=light
        else
        set background=dark
        endif
        colorscheme solarized
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          " MISC KEY MAPS
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          map <Left> <Nop>
          map <Right> <Nop>
          map <Up> <Nop>
          map <Down> <Nop>

          " Move around splits with <c-hjkl>
          nnoremap <c-j> <c-w>j
          nnoremap <c-k> <c-w>k
          nnoremap <c-h> <c-w>h
          nnoremap <c-l> <c-w>l
          imap <c-c> <esc>

          " Clear the search buffer when hitting return
          function! MapCR()
            if &buftype ==# 'quickfix'
              execute "unmap <cr>"
            else
              execute "nnoremap <cr> :nohlsearch<cr>"
            endif
          endfunction
          call MapCR()
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          " OPEN FILES IN DIRECTORY OF CURRENT FILE
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          cnoremap %% <C-R>=expand('%:h').'/'<cr>
          map <leader>e :edit %%
          map <leader>v :view %%
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          " PROMOTE VARIABLE TO RSPEC LET
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          function! PromoteToLet()
            :normal! dd
            " :exec '?^\s*it\>'
            :normal! P
            :.s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
            :normal ==
          endfunction
          :command! PromoteToLet :call PromoteToLet()
          :map <leader>p :PromoteToLet<cr>

          " open quickfix after any grep invocation
          augroup grepQuickFixGroup
          autocmd QuickFixCmdPost *grep* cwindow
          augroup END

          augroup vimrcEx
            " Clear all autocmds in the group
            autocmd!
            autocmd FileType text setlocal textwidth=78
            " Jump to last cursor position unless it's invalid or in an event handler
            autocmd BufReadPost *
              \ if line("'\"") > 0 && line("'\"") <= line("$") |
              \   exe "normal g`\"" |
              \ endif
            autocmd! BufReadPost gitcommit
              \ if line("'\"") > 0 && line("'\"") <= line("$") |
              \   exe "normal g`\"" |
              \ endif
            autocmd FileType gitcommit setlocal spell spelllang=en_us
            autocmd FileType gitcommit DiffGitCached | wincmd L

            "for ruby, autoindent with two spaces, always expand tabs
            autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber set ai sw=2 sts=2 et
            autocmd FileType python set sw=4 sts=4 et
            autocmd! BufRead,BufNewFile *.sass setfiletype sass

            autocmd BufRead *.mkd  set ai formatoptions=tcroqn2 comments=n:&gt;
            autocmd BufRead *.markdown  set ai formatoptions=tcroqn2 comments=n:&gt;

            " Indent p tags
            "autocmd FileType html,eruby if g:html_indent_tags !~ '\\|p\>' | let g:html_indent_tags .= '\|p\|li\|dt\|dd' | endif

            " Leave the return key alone when in command line windows, since it's used
            " to run commands there.
            autocmd! CmdwinEnter * :unmap <cr>
            autocmd! CmdwinLeave * :call MapCR()
            autocmd BufEnter * :call MapCR()
            autocmd BufRead,BufNewFile Podfile set filetype=ruby
          augroup END

          let g:airline#extensions#ale#enabled = 1

          " Fzf
          nnoremap <leader>ff :GFiles<CR>
          nnoremap <Leader>fb :Buffers<CR>
          nnoremap <Leader>fh :History<CR>
          nnoremap <Leader>fc :Commits<CR>
          nnoremap <Leader>ft :Tags<CR>
          " hide statusline when fzf buffer is open
          autocmd! FileType fzf
          autocmd  FileType fzf set laststatus=0 noshowmode noruler
            \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

          " Development specific

          " Invoke make
          nnoremap <leader>k :!make<cr>

          " vim-test mappings
          nmap <silent> <leader>t :TestNearest<CR>
          nmap <silent> <leader>T :TestFile<CR>
          nmap <silent> <leader>s :TestSuite<CR>
          nmap <silent> <leader>l :TestLast<CR>
          nmap <silent> <leader>g :TestVisit<CR>

          " enable coc status in airline
          let g:airline#extensions#coc#enabled = 1

          " gutentags
          let g:gutentags_generate_on_new = 0
          let g:gutentags_cache_dir = "~/.tags_cache"

          let g:ale_linters = {
          \   'javascript': ['eslint'],
          \   'ruby': ['rubocop'],
          \}

          let g:ale_linters_explicit = 1
          let g:airline#extensions#ale#enabled = 1
          nmap <silent> <C-k> <Plug>(ale_previous_wrap)
          nmap <silent> <C-j> <Plug>(ale_next_wrap)

          " Language specific

          " Set asm as kickass syntax
          autocmd BufRead *.asm set filetype=kickass

          " javascript
          let g:jsx_ext_required = 1 " syntax highlighting only on .jsx files

          command! -nargs=0 Prettier :CocCommand prettier.formatFile
      '';
    };
  };

  systemd.user.services.dropbox = {
    description = "Dropbox";
    wantedBy = [ "graphical-session.target" ];
    environment = {
      QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
      QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
    };
    serviceConfig = {
      ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
      ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
      KillMode = "control-group"; # upstream recommends process
      Restart = "on-failure";
      PrivateTmp = true;
      ProtectSystem = "full";
      Nice = 10;
    };
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
