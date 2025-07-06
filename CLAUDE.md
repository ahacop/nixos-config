# NixOS Configuration

This is a flake-based NixOS configuration with custom package management and development tools.

## Quick Commands

### Configuration Management
- `make switch` - Apply configuration changes (rebuilds and switches)
- `make test` - Test configuration changes without switching
- `make optimize` - Optimize nix store

### Package Updates
- `claude-update` - Update Claude Code to latest version from npm
- After running `claude-update`, run `make switch` to apply

### System Info
- `make check-kernel` - Check current vs available kernel versions

## Key Files

- `flake.nix` - Main flake configuration with custom packages
- `hosts/default/configuration.nix` - System configuration
- `hosts/default/home.nix` - Home Manager configuration
- `claude-version.json` - Claude Code version and hash tracking
- `scripts/claude-update` - Claude Code update script

## Custom Packages

- `claude-code-latest` - Custom derivation for Claude Code built from npm registry
- Version tracked in `claude-version.json` with SHA256 hash

## Development

The configuration uses flakes and includes development environments in `devflakes/`.

## Testing Changes

1. Make configuration changes
2. Run `make test` to test without switching
3. Run `make switch` to apply changes
