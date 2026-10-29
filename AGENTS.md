# AGENTS.md

This repo is a flake-based NixOS config for one VMware Fusion VM on an Apple Silicon Mac (`aarch64-linux`). It has one system, `nixosConfigurations.default`. There is no test suite and no lint target.

## Checking a change

The user builds and switches the system. Check a change by evaluating it, which builds nothing:

```
GC_INITIAL_HEAP_SIZE=4G nix eval .#nixosConfigurations.default.config.system.build.toplevel.drvPath
```

Evaluation does not run `noctalia config validate` or `niri validate`. Only the build (`make test`) runs them, so tell the user when a change touches the Noctalia or niri config. Format Nix with `nix fmt`.

Commit a change before the user switches to try it, even an experiment. The user does not switch from a dirty tree. If the change does not work, drop or revert the commit.

## Where things are

- `flake.nix` holds only the inputs. import-tree loads every `.nix` file under `modules/` as a flake-parts module, except paths that contain `/_`. `modules/hosts/default/default.nix` builds `nixosConfigurations.default`.
- A feature file in `modules/` puts its NixOS part in `flake.modules.nixos.<name>` and its home-manager part in `flake.modules.homeManager.<name>`. A feature with both parts adds its home-manager part to `home-manager.sharedModules` from its NixOS part. The host file lists each feature once: the NixOS part if there is one, or else the home-manager part.
- A local evaluation reads only the files that git tracks. `make vm/copy` copies the tree without `.git`, so the VM build reads every file under `modules/`. Do not leave an untracked `.nix` file in `modules/`.
- Each feature has one file or directory in `modules/` with its name: dictation, dictionary, firefox, ghostty, git, llm-agents, niri, nixvim, noctalia, printing, theme, tmux, usb-drives, vmware-guest and zsh.
- `modules/hosts/default/configuration.nix` and `modules/hosts/default/home.nix` hold the system and user settings that belong to no feature. `home.nix` has the user packages, small shell tools such as starship and direnv, and the session variables.
- `modules/hosts/default/_hardware-configuration.nix` is the file that `nixos-generate-config` wrote. `nix fmt` does not format it.
- No module gets `specialArgs`. A flake-parts module reads the flake inputs as `inputs` and the user name as `config.user`, from `modules/user.nix`. A NixOS or home-manager part uses them from the enclosing flake-parts module.
- To add or remove an LLM CLI, edit `llmAgentNames` in `modules/llm-agents.nix`. The home-manager part in that file and `make check-versions` both read that list.
- The global gitignore ignores `.envrc`. An `.envrc` in a `devflakes/` template needs `git add -f`.

## Desktop

Niri is the compositor. Noctalia is the whole shell: bar, launcher, notifications, clipboard history, OSDs and lock screen. Niri starts Noctalia with `spawn-at-startup`, not systemd. Ghostty is the terminal.

The Mac home directory is mounted at `/host` over HGFS. Never run a search or glob that starts at `/`, because it walks into the Mac files. Name paths explicitly.

## History rewrites

`make upgrade-all` replaces the `Update flake` and `Update agents` commits at the tip of the branch. A branch that is already pushed then needs `git push --force-with-lease`.
