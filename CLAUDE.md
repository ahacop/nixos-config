# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Configuration Management
- `make switch` - Apply configuration changes (rebuilds and switches to new configuration)
- `make test` - Test configuration changes without switching (rebuilds but doesn't activate)
- `make clean` - Clean old generations and garbage collect
- `make optimize` - Optimize nix store

### System Information
- `make check-kernel` - Compare current vs available kernel versions
- `make check-claude-version` - Compare current vs latest Claude Code version

### Package Updates
- `make upgrade-claude` - Update Claude Code to latest version from npm (runs `scripts/claude-update`)
- After updating Claude, run `make switch` to apply

### VM Management (for remote bootstrap from host machine)
- `make vm/bootstrap0` - Bootstrap brand new VM with NixOS installation (requires `NIXADDR` env var)
- `make vm/bootstrap` - Finalize VM bootstrap after initial installation
- `make vm/copy` - Copy Nix configurations into the VM via rsync over SSH
- `make vm/switch` - Run nixos-rebuild switch in the VM

## Architecture

This is a flake-based NixOS configuration for a VMware Fusion VM running on Apple Silicon (aarch64-linux).

### Key Files
- `flake.nix` - Main flake definition with inputs (nixpkgs, home-manager, stylix, nixvim, niri, walker) and custom Claude Code derivation
- `hosts/default/configuration.nix` - System-level NixOS configuration (boot, networking, services, system packages, Stylix theming)
- `hosts/default/home.nix` - User-level configuration via Home Manager (shell, git, nixvim, window manager, application launchers)
- `modules/vmware-guest.nix` - Custom VMware guest module modified for aarch64 support
- `claude-version.json` - Tracks Claude Code version and SHA256 hash for the custom derivation
- `scripts/claude-update` - Bash script that fetches latest Claude version from npm, calculates hash, and updates `claude-version.json`

### Configuration Workflow
1. Edit configuration files (`flake.nix`, `hosts/default/*.nix`, `modules/*.nix`)
2. Run `make test` to build and test without switching
3. Run `make switch` to build and activate the new configuration
4. System will rebuild based on flake configuration and switch to new generation

### Custom Derivations
The `claude-code-latest` function in `flake.nix` builds Claude Code from the npm registry. It:
- Reads version and hash from `claude-version.json`
- Downloads the tarball from npm registry
- Creates a derivation that installs it to `/nix/store`
- Symlinks the CLI to `$out/bin/claude`

### Window Manager (Wayland)
Uses Niri (scrollable-tiling Wayland compositor) with:
- **Waybar** - Status bar
- **Walker** - Application launcher with clipboard history integration, custom runners for clipboard sync, and web search providers
- **Ghostty/Kitty** - Terminal emulators with clipboard sync to host via `pbcopy`/`pbpaste`
- **Mako** - Notification daemon

### Development Environment
- **Nixvim** - Neovim configured via Nix with LSP support (Ruby, Go, TypeScript, Bash, Nix, etc.)
- **direnv + nix-direnv** - Automatic environment switching for project-specific shells
- **devflakes/** - Language-specific development environments:
  - `devflakes/ruby/` - Ruby development environment with specific Ruby version, bundler, postgres, redis, docker, etc.

### VMware Integration
- Custom `vmware-guest.nix` module (based on official module, modified for aarch64)
- Host filesystem mounted at `/host` for file sharing
- Clipboard sync with host via `pbcopy`/`pbpaste` wrapper scripts in Kitty config
- Walker clipboard sync commands for bidirectional clipboard support

### Theme System (Stylix)
Configuration uses Stylix for system-wide theming. Multiple color schemes defined in `configuration.nix`:
- Turbo Pascal theme (blue background with colorful syntax)
- Green VT100 terminal theme
- Black and white monochrome theme
- Amber VT100 terminal theme
- Active theme: Gruvbox Dark Soft (base16)
