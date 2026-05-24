## Setup (VM)

You can download the NixOS ISO from the
[official NixOS download page](https://nixos.org/download.html#nixos-iso).
There are ISOs for both `x86_64` and `aarch64` at the time of writing this.

Create a VMware Fusion VM with the following settings. My configurations
are made for VMware Fusion exclusively currently and you will have issues
on other virtualization solutions without minor changes.

- ISO: NixOS 23.05 or later.
- Disk: SATA 150 GB+
- CPU/Memory: I give at least half my cores and half my RAM, as much as you can.
- Graphics: Full acceleration, full resolution, maximum graphics RAM.
- Network: Shared with my Mac.
- Remove sound card, remove video camera, remove printer.
- Profile: Disable almost all keybindings
- Boot Mode: UEFI

Boot the VM, and using the graphical console, change the root password to "root":

```
$ sudo su
$ passwd
# change to root
```

At this point, verify `/dev/sda` exists. This is the expected block device
where the Makefile will install the OS. If you setup your VM to use SATA,
this should exist. If `/dev/nvme` or `/dev/vda` exists instead, you didn't
configure the disk properly. Note, these other block device types work fine,
but you'll have to modify the `bootstrap0` Makefile task to use the proper
block device paths.

Also at this point, I recommend making a snapshot in case anything goes wrong.
I usually call this snapshot "prebootstrap0". This is entirely optional,
but it'll make it super easy to go back and retry if things go wrong.

Run `ifconfig` and get the IP address of the first device. It is probably
`192.168.58.XXX`, but it can be anything. In a terminal with this repository
set this to the `NIXADDR` env var:

```
export NIXADDR=<VM ip address>
```

The Makefile assumes an Intel processor by default. If you are using an
ARM-based processor (M1, etc.), you must change `NIXNAME` so that the ARM-based
configuration is used:

```
export NIXNAME=vm-aarch64
```

**Other Hypervisors:** If you are using Parallels, use `vm-aarch64-prl`.
If you are using UTM, use `vm-aarch64-utm`. Note that the environments aren't
_exactly_ equivalent between hypervisors but they're very close and they
all work.

Perform the initial bootstrap. This will install NixOS on the VM disk image
but will not setup any other configurations yet. This prepares the VM for
any NixOS customization:

```
make vm/bootstrap0
```

After the VM reboots, run the full bootstrap, this will finalize the
NixOS customization using this configuration:

```
make vm/bootstrap
```

You should have a graphical functioning dev VM.

At this point, I never use Mac terminals ever again. I clone this repository
in my VM and I use the other Make tasks such as `make test`, `make switch`, etc.
to make changes my VM.

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
