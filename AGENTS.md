# AGENTS.md

This repo is a flake-based NixOS config for VMware Fusion VMs on an Apple Silicon Mac (`aarch64-linux`). Each VM is a host with one system named after its hostname.

## Checking a change

The user builds and switches the system. Check a change by evaluating it, which builds nothing:

```
GC_INITIAL_HEAP_SIZE=4G nix eval .#nixosConfigurations.default.config.system.build.toplevel.drvPath
```

Evaluate every host the change can reach.

Evaluation does not run `noctalia config validate` or `niri validate`. Only the build (`make test`) runs them, so tell the user when a change touches the Noctalia or niri config. Format Nix with `nix fmt`.

Commit a change before the user switches to try it, even an experiment. The user does not switch from a dirty tree. If the change does not work, drop or revert the commit.

## Where things are

- `flake.nix` holds only the inputs. import-tree loads every `.nix` file under `modules/` as a flake-parts module, except paths that contain `/_`.
- A feature file in `modules/` puts its NixOS part in `flake.modules.nixos.<name>` and its home-manager part in `flake.modules.homeManager.<name>`. A feature with both parts adds its home-manager part to `home-manager.sharedModules` from its NixOS part.
- A host is a named module too. `modules/hosts/<host>/default.nix` defines `flake.modules.nixos.<host>` and `flake.modules.homeManager.<host>`, which import the base and the host's features and set what only that host has (its hostName and stateVersion), and builds `nixosConfigurations.<host>` from `nixos.<host>` alone. A host imports each feature once: the NixOS part if there is one, or else the home-manager part. The hostName must equal `<host>`, because the Makefile builds the system named after the hostname.
- A setting every host gets goes in the base. A capability only some hosts want goes in its own feature, which only those hosts import. A setting for one host only goes in that host's module. Hosts only add: to keep something off one host, move it out of the base into a feature or a host module, and do not use `mkForce` or disable options.
- A local evaluation reads only the files that git tracks. `make vm/install` and `make vm/copy` copy the tree without `.git`, so the VM build reads every file under `modules/`. Do not leave an untracked `.nix` file in `modules/`.
- Each feature has one file or directory in `modules/` with its name: audio, cli-tools, containers, dictation, dictionary, ebook-collecting, ebook-production, ebook-reading, firefox, ghostty, git, llm-agents, mac-host, networking, niri, nix-ld, nixvim, noctalia, notes, printing, ssh, theme, tmux, usb-drives, vmware-guest, writing and zsh. A feature holds one concern: everything for a purpose, such as `cli-tools` for the everyday admin tools, not one file per app and not a grab-bag.
- `modules/base/configuration.nix` and `modules/base/home.nix` are the base: `flake.modules.nixos.configuration` and `flake.modules.homeManager.home`, the system and user settings that every host gets and that belong to no feature. `configuration.nix` holds the system itself (boot, nix, the user, time, logging) and imports the features every host gets: audio, cli-tools, containers and ssh. `home.nix` has small shell tools such as starship and direnv, and the session variables.
- `modules/base/_hardware-configuration.nix` is the file that `nixos-generate-config` wrote. It fits any of these VMs. `nix fmt` does not format it.
- No module gets `specialArgs`. A flake-parts module reads the flake inputs as `inputs` and the user name as `config.user`, from `modules/user.nix`. A NixOS or home-manager part uses them from the enclosing flake-parts module.
- To add or remove an LLM CLI, edit `llmAgentNames` in `modules/llm-agents.nix`. The home-manager part in that file and `make check-versions` both read that list.
- The global gitignore ignores `.envrc`. An `.envrc` in a `devflakes/` template needs `git add -f`.

## Desktop

Niri is the compositor. Noctalia is the whole shell: bar, launcher, notifications, clipboard history, OSDs and lock screen. Niri starts Noctalia with `spawn-at-startup`, not systemd. Ghostty is the terminal.

The Mac home directory is mounted at `/host` over HGFS. Never run a search or glob that starts at `/`, because it walks into the Mac files. Name paths explicitly.

## History rewrites

`make upgrade-all` replaces the `Update flake` and `Update agents` commits at the tip of the branch. A branch that is already pushed then needs `git push --force-with-lease`.
