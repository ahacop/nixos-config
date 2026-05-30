# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Configuration Management

- `make` / `make help` - List available targets grouped by category
- `make switch` - Apply configuration changes (`sudo nixos-rebuild switch --flake .#default`)
- `make test` - Test configuration changes without switching (rebuilds but doesn't activate)
- `make clean` - Delete old generations, garbage collect, prune docker, rebuild boot
- `make optimize` - Optimize nix store (dedupe via hard links)
- `make restart-walker` - Restart the Walker and Elephant launcher services

There is no application test suite or lint target — this is a system configuration. "Testing" means `make test` (a non-activating `nixos-rebuild`). The single buildable target is `nixosConfigurations.default` (`NIXNAME=default`); commands rebuild `.#default`.

### Disk Cleanup

The Makefile has a dedicated cleanup group. Override `STALE_DAYS=N` (default 30) and `CODE_DIRS` (default `~/code`) to tune scanning.

- `make disk-status` - Disk/nix-store/cache/docker usage overview
- `make gc-roots` - List GC roots, flagging broken ones
- `make stale-results` / `make clean-results` - Find/remove old `result` symlinks
- `make stale-direnvs` / `make clean-direnvs` - Find/remove `.direnv` in inactive projects
- `make bloated-direnvs` / `make clean-direnv-profiles` - Find/trim extra flake profiles in `.direnv`
- `make clean-caches` - Remove re-downloadable tool caches (allow-list in `SAFE_CACHE_DIRS`)
- `make clean-stores` - Prune pnpm/gem content-addressable stores
- `make clean-all` - Full sweep (stale items + caches + stores + `clean`)

### System Information

- `make check-kernel` - Compare current vs available kernel versions
- `make check-claude-version` - Compare current vs latest Claude Code version

### Package Updates

- `make upgrade-claude` - Update Claude Code flake input to latest version
- After updating Claude, run `make switch` to apply

### VM Management (for remote bootstrap from host machine)

- `make vm/bootstrap0` - Bootstrap brand new VM with NixOS installation (requires `NIXADDR` env var)
- `make vm/bootstrap` - Finalize VM bootstrap after initial installation
- `make vm/copy` - Copy Nix configurations into the VM via rsync over SSH
- `make vm/switch` - Run nixos-rebuild switch in the VM

## Architecture

This is a flake-based NixOS configuration for a VMware Fusion VM running on Apple Silicon (aarch64-linux).

### Key Files

- `flake.nix` - Main flake definition with inputs (nixpkgs, home-manager, stylix, nixvim, niri, walker, claude-code-overlay) and the `devflakes/` dev-shell `templates`
- `hosts/default/configuration.nix` - System-level NixOS configuration (boot, networking, services, system packages, Stylix theming). Inline package derivations live here (e.g. `moby-thesaurus`, `thes`, `notify-macos`, `copy-screenshot`)
- `hosts/default/home.nix` - User-level configuration via Home Manager. ~2400 lines; the entire Nixvim setup (LSP servers, keymaps, embedded Lua) is inline here, along with shell, git, jujutsu, and Walker config
- `hosts/default/hardware-configuration.nix` - Generated hardware scan (don't hand-edit)
- `modules/vmware-guest.nix` - Custom VMware guest module modified for aarch64 support
- `config/` - Raw shell files sourced into zsh via `home.nix` (`zshrc`, `functions`, `githelpers`, `sshconfig`)

### Configuration Workflow

1. Edit configuration files (`flake.nix`, `hosts/default/*.nix`, `modules/*.nix`)
2. Run `make test` to build and test without switching
3. Run `make switch` to build and activate the new configuration
4. System will rebuild based on flake configuration and switch to new generation

### Claude Code

Claude Code is provided via the `claude-code-overlay` flake input ([ryoppippi/claude-code-overlay](https://github.com/ryoppippi/claude-code-overlay)), which supplies pre-built official binaries. Update with `make upgrade-claude`, then `make switch`.

### Window Manager (Wayland)

Uses Niri (scrollable-tiling Wayland compositor) with:

- **Waybar** - Status bar
- **Walker** - Application launcher with clipboard history integration, custom runners for clipboard sync, and web search providers
- **Ghostty** - Terminal emulator
- **Mako** - Notification daemon

### Development Environment

- **Nixvim** - Neovim configured via Nix with LSP support (Ruby, Go, TypeScript, Bash, Nix, etc.)
- **direnv + nix-direnv** - Automatic environment switching for project-specific shells
- **devflakes/** - Language-specific dev shells, also exposed as flake `templates` (use `nix flake init -t ~/nixos-config#<name>` in a new project):
  - `ruby` - Pinned Ruby + bundler/gem build deps
  - `rails` - Ruby + postgres, node, vips, flyctl, etc.
  - `rust` - Stable toolchain + clippy/rustfmt/rust-analyzer
  - `prolog` - SWI-Prolog + GUI, `prolog_ls` (wired into Nixvim via the swipl on PATH), `just`
  - `standardebooks` - direnv passthrough (`.envrc` only, no `flake.nix`); drops in `use flake github:ahacop/standardebooks-nix` to activate the Standard Ebooks `se`/`se-ext` devShell

When formatting Nix in this repo, match the existing two-space style; Nixvim formats Nix on save via none-ls (`alejandra`) with `statix` diagnostics.

### VMware Integration

- Custom `vmware-guest.nix` module (based on official module, modified for aarch64)
- Host filesystem mounted at `/host` for file sharing
- Walker clipboard sync commands ("sf"/"st") move the clipboard to/from the host file (`/host/ahacop/clipboard.txt`) on demand

### Theme System (Stylix)

Configuration uses Stylix for system-wide theming. Multiple color schemes defined in `configuration.nix`:

- Turbo Pascal theme (blue background with colorful syntax)
- Green VT100 terminal theme
- Black and white monochrome theme
- Amber VT100 terminal theme
- Active theme: Gruvbox Dark Soft (base16)
