## Setup (VM)

This configuration targets one VMware Fusion VM on an Apple Silicon Mac
(`aarch64-linux`). The flake has a single system, `nixosConfigurations.default`,
and the Makefile builds `.#default` unless `NIXNAME` is set to something else.

Download the `aarch64` NixOS ISO from the
[official NixOS download page](https://nixos.org/download.html#nixos-iso).

Create a VMware Fusion VM with these settings:

- ISO: NixOS 24.05 or later.
- Disk: NVMe, 150 GB+. `make vm/bootstrap0` partitions `/dev/nvme0n1`; set
  `HDDEV` if the disk shows up under another name.
- CPU/Memory: at least half the cores and half the RAM.
- Graphics: Full acceleration, full resolution, maximum graphics RAM.
- Network: Bridged, so the VM gets its own address on the local network.
- Remove the sound card, video camera and printer.
- Profile: Disable almost all keybindings.
- Boot Mode: UEFI.

Boot the VM. In the graphical console, set the root password to "root":

```
$ sudo su
$ passwd
```

Take a snapshot here if you want an easy retry.

Run `ip addr` and note the VM's address. In a terminal on the Mac, inside a
clone of this repository:

```
export NIXADDR=<VM ip address>
make vm/bootstrap0
```

That partitions the disk, installs a minimal NixOS with SSH enabled, and
reboots. After the reboot, finish with this configuration:

```
make vm/bootstrap
```

That copies the repository to `/nix-config` in the VM, runs
`nixos-rebuild switch` there, copies the SSH and GPG keys over
(`make vm/secrets`), and reboots.

From here on, work inside the VM. Clone this repository there and use
`make test` and `make switch`.

## Dev Shells (devflakes)

The `devflakes/` directory holds language-specific Nix dev shells that are also
exposed as flake `templates`. Use them to get a reproducible, project-local
toolchain without polluting your system configuration.

Available templates:

- `ruby` — pinned Ruby + bundler/gem build deps
- `rails` — Ruby + postgres, node, vips, flyctl, etc.
- `rust` — stable toolchain + clippy/rustfmt/rust-analyzer
- `prolog` — SWI-Prolog + GUI, `prolog_ls` (wired into Nixvim via the `swipl` on
  PATH), `just`
- `lean` — Lean 4 (`lean` + `lake`) at the version this flake pins, `just`; the
  Lean LSP is wired into Nixvim as `leanls`
- `standardebooks` — direnv passthrough (`.envrc` only, no `flake.nix`) that
  drops in `use flake github:ahacop/standardebooks-nix` to activate the Standard
  Ebooks `se`/`se-ext` devShell

### Initialize a new project

In an empty (or existing) project directory, use the `mkdevenv` shell helper
(defined in `config/functions`):

```
mkdevenv ruby
```

This runs `nix flake init -t ~/nixos-config#ruby` to copy the template's
`flake.nix` into the current directory, and writes an `.envrc` containing
`use flake` if one doesn't already exist. Swap `ruby` for `rails`, `rust`,
`prolog`, `lean`, or `standardebooks`. Run `mkdevenv` with no arguments (or `-h`) to list
the available templates.

### Enter the shell

With [direnv](https://direnv.net/) + nix-direnv (both enabled in this config),
the environment activates automatically once you allow the `.envrc` `mkdevenv`
wrote:

```
direnv allow
```

Without direnv, drop into the shell manually:

```
nix develop
```

### Use without initializing (one-off shell)

You can enter any of these shells ad hoc, straight from this config, without
copying files into your project:

```
nix develop ~/nixos-config/devflakes/ruby
```

## Secrets

Machine-local secrets that shouldn't live in the Nix store or in git (a
`~/.config/secrets.env` file by default) are archived to a 1Password document
and pulled back down with two Make targets:

```
make secrets/backup    # secrets.env  -> 1Password document
make secrets/restore   # 1Password document -> secrets.env (chmod 600)
```

Both require the [1Password CLI](https://developer.1password.com/docs/cli/)
(`op`), which ships in this configuration. They target a `op` account by its
local shorthand (`OP_ACCOUNT`, default `personal`). One-time setup, per
machine, before the first backup:

```
op account add --address my.1password.com --email you@example.com --shorthand personal
eval $(op signin --account personal)
```

Sign-in stores a session token in your shell environment, so run `op signin`
and the `make` target in the same shell.

The targets accept these overrides on the command line:

- `OP_ACCOUNT` — which signed-in `op` account to use (default `personal`).
- `SECRETS_FILE` — path to the local file (default `~/.config/secrets.env`).
- `OP_SECRETS_ITEM` — 1Password document title (default `vm-secrets.env`).
- `OP_VAULT` — restrict to a specific vault (default: account's default vault).

For example, to back up to the work account instead:

```
make secrets/backup OP_ACCOUNT=work
```
