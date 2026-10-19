# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a flake-based NixOS configuration for one VMware Fusion VM on an Apple Silicon Mac (`aarch64-linux`). The flake has one system, `nixosConfigurations.default`. There is no test suite and no lint target.

## Checking a change

The user builds and switches the system. Check a change by evaluating it, which builds nothing:

```
GC_INITIAL_HEAP_SIZE=4G nix eval .#nixosConfigurations.default.config.system.build.toplevel.drvPath
```

Evaluation does not run `noctalia config validate` or `niri validate`. Those checks run during the build, so a bad Noctalia key or niri setting shows up only when the user runs `make test`. Say so when a change touches either config. Format Nix with `nix fmt` (nixfmt, the same formatter Nixvim applies on save).

`make help` lists every Make target. `make test` builds without activating and leaves a root-owned `./result` link. `make switch` builds and activates.

## Layout

- `flake.nix` holds the inputs, the dev-shell `templates`, and `llmAgentNames`. `llmAgentNames` is the one list of LLM CLIs from the `llm-agents` input. `home.nix` installs them and `make check-versions` reads them through the `llmAgents` output.
- `hosts/default/configuration.nix` is the system config: boot, services, printing, VMware guest, Stylix theme, and small inline packages such as `print-doc` and `notify-macos`.
- `hosts/default/home.nix` is the Home Manager config, about 2500 lines. It contains the whole Nixvim setup (LSP servers, keymaps, embedded Lua), zsh, git, tmux, niri and Noctalia. Search it by option path, for example `programs.noctalia`.
- `hosts/default/hardware-configuration.nix` is generated. Do not edit it by hand.
- `config/` holds raw zsh files that `home.nix` sources. `mkdevenv` lives in `config/functions`.
- `devflakes/` holds the dev shells that the flake exposes as `templates` (`nix flake init -t ~/nixos-config#<name>`). The global gitignore ignores `.envrc`, so a template that ships one needs `git add -f`.
- `plugins/` holds Noctalia plugins that `home.nix` links into `~/.local/share/noctalia/plugins`. After a new plugin is added, `make reload-shell` is not enough; the shell needs `make restart-shell`.

## Desktop

Niri is the Wayland compositor. Noctalia is the whole shell layer in one process: bar, launcher, notifications, clipboard history, OSDs and lock screen. Its settings are a Nix attrset under `programs.noctalia.settings`, rendered to TOML. Niri starts it with `spawn-at-startup`, not systemd. Ghostty is the terminal.

The Mac clipboard syncs through the `clipway` input, which patches `open-vm-tools` and runs `vmtoolsd -n vmusr` as a user service. It needs `xwayland-satellite` for an X display at startup.

The Mac home directory is mounted at `/host` over HGFS. Never run a search or glob that starts at `/`, because it walks into the Mac files. Name paths explicitly.

## Make targets with side effects

- `make upgrade-all` (`scripts/upgrade-all.sh`) updates every input and rewrites the tip of the branch into an `Update flake` commit and an `Update agents` commit. It replaces those commits if they are already at the tip, so a pushed branch then needs `git push --force-with-lease`.
- `make pin-kernel` and `make unpin-kernel` rewrite the `nixpkgs-kernel` line in `flake.nix` and relock. `nixpkgs-kernel` supplies only the kernel. Kernels newer than 7.2.6 made this VM slow and logged "vmwgfx: No GMR memory available".
- `make clean-docker-layers` stops docker for a short time, and it refuses to run while any image or container exists.
- `make clean-caches` and `make clean-stores` delete only the directories in `SAFE_CACHE_DIRS` and `SAFE_STORE_DIRS`. Add a new directory to those lists, not to the recipe.

## Input pins

Most inputs follow our `nixpkgs`. `llm-agents` keeps its own nixpkgs on purpose, so its CLIs match the `cache.numtide.com` binaries. `aoc-cli`, `erwindb` and `opdsview` all follow one `rust-overlay` input.
