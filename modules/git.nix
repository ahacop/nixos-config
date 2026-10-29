# git, with gh as the credential helper for GitHub, and tig.
{
  flake.modules.homeManager.git =
    let
      # Identity for the git config below.
      fullName = "Ara Hacopian";
      primaryEmail = "ara@hacopian.de";
      workEmail = "ara@changebot.ai";
    in
    {
      programs.gh = {
        enable = true;
        gitCredentialHelper = {
          enable = true;
          hosts = [ "https://github.com" ];
        };
      };

      programs.git = {
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

      home.file.".githelpers".source = ../config/githelpers;
      home.file.".tigrc".text = ''
        bind generic Y !sh -c 'commit=%(commit); echo $commit | /run/current-system/sw/bin/wl-copy -n & echo $commit | /run/current-system/sw/bin/tmux load-buffer -'
        set main-view = line-number:no id:yes date:custom,format="%Y-%m-%d %H:%M" author:full commit-title:yes,graph,refs,overflow=no
      '';
    };
}
