# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Configuration Management

- `make` / `make help` - List available targets grouped by category
- `make switch` - Apply configuration changes (`sudo nixos-rebuild switch --flake .#default`)
- `make test` - Build the configuration without activating it (`nixos-rebuild build`, leaves a `./result` link)
- `make clean` - Delete old generations, garbage collect, prune docker, rebuild boot
- `make optimize` - Optimize nix store (dedupe via hard links)
- `make reload-shell` - Reload the Noctalia shell config without restarting it

There is no application test suite or lint target — this is a system configuration. "Testing" means `make test` (`nixos-rebuild build`, which activates nothing). The single buildable target is `nixosConfigurations.default` (`NIXNAME=default`); commands rebuild `.#default`.

### Disk Cleanup

The Makefile has a dedicated cleanup group. Override `STALE_DAYS=N` (default 30) and `CODE_DIRS` (default `~/code`) to tune scanning.

- `make disk-status` - Disk/nix-store/cache/store/docker usage overview
- `make gc-roots` - List GC roots, flagging broken ones, plus the profile links that act as roots (a leftover standalone `home-manager` profile shows up here)
- `make docker-volumes` - List named docker volumes with sizes; `clean` never removes these, drop one with `docker volume rm <name>`
- `make stale-results` / `make clean-results` - Find/remove old `result` symlinks
- `make stale-direnvs` / `make clean-direnvs` - Find/remove `.direnv` in inactive projects
- `make bloated-direnvs` / `make clean-direnv-profiles` - Find/trim extra flake profiles in `.direnv`
- `make clean-caches` - Remove re-downloadable tool caches (allow-list in `SAFE_CACHE_DIRS`; uses sudo for root-owned dirs such as trivy)
- `make clean-stores` - Remove re-downloadable package stores (allow-list in `SAFE_STORE_DIRS`: pnpm, gem, npm, cargo registry, go modules)
- `make clean-docker-layers` - Remove orphaned overlay2 layers; stops docker briefly and refuses to run while any image or container exists
- `make clean-all` - Full sweep (stale items + old flake profiles + caches + stores + `clean` + docker layers)

### System Information

- `make check-versions` - Compare each installed LLM agent CLI (the `llmAgentNames` list in `flake.nix`) against the version the `llm-agents` flake currently ships, flagging any that are behind, plus whether the flake pin itself is behind upstream

### Package Updates

- `make upgrade-agents` - Update the `llm-agents` flake input (bumps every CLI in `llmAgentNames` together)
- `make upgrade-all` (`scripts/upgrade-all.sh`) - Update every flake input and rewrite the tip of the branch into two commits: `Update flake` for all inputs except `llm-agents`, then `Update agents` for `llm-agents` on top. It drops whichever of those two commits is already at the tip and builds them again from the current inputs, so `flake.lock` is regenerated instead of merged. It refuses to run on a dirty tree, and stops if a tip commit changes any file other than `flake.lock`. The rebuilt commits replace the old ones, so a branch already on the remote needs `git push --force-with-lease`.
- After updating, run `make switch` to apply

### VM Management (for remote bootstrap from host machine)

- `make vm/bootstrap0` - Bootstrap brand new VM with NixOS installation (requires `NIXADDR` env var)
- `make vm/bootstrap` - Finalize VM bootstrap after initial installation
- `make vm/copy` - Copy Nix configurations into the VM via rsync over SSH
- `make vm/switch` - Run nixos-rebuild switch in the VM

## Architecture

This is a flake-based NixOS configuration for a VMware Fusion VM running on Apple Silicon (aarch64-linux).

### Key Files

- `flake.nix` - Main flake definition with inputs (nixpkgs, home-manager, stylix, nixvim, niri, llm-agents) and the `devflakes/` dev-shell `templates`
- `hosts/default/configuration.nix` - System-level NixOS configuration (boot, networking, services, system packages, Stylix theming). Inline package derivations live here (e.g. `moby-thesaurus`, `thes`, `notify-macos`, `copy-screenshot`)
- `hosts/default/home.nix` - User-level configuration via Home Manager. ~2400 lines; the entire Nixvim setup (LSP servers, keymaps, embedded Lua) is inline here, along with shell, git, and Noctalia config
- `hosts/default/hardware-configuration.nix` - Generated hardware scan (don't hand-edit)
- `config/` - Raw shell files sourced into zsh via `home.nix` (`zshrc`, `functions`, `githelpers`, `sshconfig`)
- `scripts/` - Shell scripts that Makefile targets call when a recipe is too long to read inline (`upgrade-all.sh`)

### Configuration Workflow

1. Edit configuration files (`flake.nix`, `hosts/default/*.nix`)
2. Run `make test` to build and test without switching
3. Run `make switch` to build and activate the new configuration
4. System will rebuild based on flake configuration and switch to new generation

### LLM Coding Agents

LLM CLI tools (the `llmAgentNames` list in `flake.nix`) come from the `llm-agents` flake input ([numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)), whose `overlays.default` exposes them under `pkgs.llm-agents.<name>` (installed in `home.nix`). It ships prebuilt binaries via the `cache.numtide.com` substituter and is updated daily upstream. Bump the pin with `make upgrade-agents` (updates the whole `llm-agents` input), then `make switch`. `make check-versions` shows each tool's installed version next to the latest the flake ships (marking any that are behind) and flags when the pin is behind upstream `main`.

### Window Manager (Wayland)

Uses Niri (scrollable-tiling Wayland compositor) with:

- **Noctalia** - The whole shell layer in one process: bar, launcher, notification daemon, control center, clipboard history, OSDs and lock screen. Configured as a Nix attrset under `programs.noctalia.settings` in `home.nix`, rendered to TOML and validated during the build by `noctalia config validate`. Started by niri `spawn-at-startup`, not systemd. Replaced Waybar, Walker, Mako and cliphist.
- **Ghostty** - Terminal emulator

### Development Environment

- **Nixvim** - Neovim configured via Nix with LSP support (Ruby, Go, TypeScript, Bash, Nix, etc.)
- **direnv + nix-direnv** - Automatic environment switching for project-specific shells
- **devflakes/** - Language-specific dev shells, also exposed as flake `templates` (use `nix flake init -t ~/nixos-config#<name>` in a new project):
  - `ruby` - Pinned Ruby + bundler/gem build deps
  - `rails` - Ruby + postgres, node, vips, flyctl, etc.
  - `rust` - Stable toolchain + clippy/rustfmt/rust-analyzer
  - `prolog` - SWI-Prolog + GUI, `prolog_ls` (wired into Nixvim via the swipl on PATH), `just`
  - `lean` - Lean 4 (`lean` + `lake`) at the version this flake pins, `just`; the Lean LSP is wired into Nixvim as `leanls`, running `lake serve` from the shell
  - `standardebooks` - direnv passthrough (`.envrc` only, no `flake.nix`); drops in `use flake github:ahacop/standardebooks-nix` to activate the Standard Ebooks `se`/`se-ext` devShell

When formatting Nix in this repo, match the existing two-space style; Nixvim formats Nix on save via none-ls (`nixfmt`) with `statix` diagnostics, and `nix fmt` runs the same nixfmt.

### VMware Integration

- The upstream NixOS `virtualisation.vmware.guest` module in headless mode (no X server): vmtoolsd plus the HGFS mount helper, no vmware-user
- Host filesystem mounted at `/host` for file sharing
- Clipboard sync commands ("sf"/"st") move the clipboard to/from the host file (`/host/ahacop/clipboard.txt`) on demand; they live in the Noctalia launcher, reachable by typing sf/st or under the `/cmd` prefix

### Theme System (Stylix)

Configuration uses Stylix for system-wide theming. Multiple color schemes defined in `configuration.nix`:

- Turbo Pascal theme (blue background with colorful syntax)
- Green VT100 terminal theme
- Black and white monochrome theme
- Amber VT100 terminal theme
- Active theme: Gruvbox Dark Soft (base16)
