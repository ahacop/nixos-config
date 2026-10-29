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

- `hosts/default/home.nix` has about 2,600 lines: Nixvim, zsh, git, tmux, niri and Noctalia. Search it by option path, for example `programs.noctalia`.
- `hosts/default/configuration.nix` is the system config.
- To add or remove an LLM CLI, edit `llmAgentNames` in `flake.nix`. `home.nix` and `make check-versions` both read that list.
- The global gitignore ignores `.envrc`. An `.envrc` in a `devflakes/` template needs `git add -f`.

## Desktop

Niri is the compositor. Noctalia is the whole shell: bar, launcher, notifications, clipboard history, OSDs and lock screen. Niri starts Noctalia with `spawn-at-startup`, not systemd. Ghostty is the terminal.

The Mac home directory is mounted at `/host` over HGFS. Never run a search or glob that starts at `/`, because it walks into the Mac files. Name paths explicitly.

## History rewrites

`make upgrade-all` replaces the `Update flake` and `Update agents` commits at the tip of the branch. A branch that is already pushed then needs `git push --force-with-lease`.
