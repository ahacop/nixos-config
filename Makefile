# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= ahacop
HDDEV ?= /dev/nvme0n1

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= default

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS := -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# We need to do some OS switching below.
UNAME := $(shell uname)

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help clean optimize check-kernel check-claude-version upgrade-claude switch test vm/bootstrap0 vm/bootstrap vm/secrets vm/copy vm/switch

# Help target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Configuration Management:'
	@grep -E '^(switch|test|optimize|clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Package Updates:'
	@grep -E '^upgrade-.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'System Info:'
	@grep -E '^check-.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'VM Management:'
	@grep -E '^vm/.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

clean: ## Clean old generations and garbage collect
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old
	nix-collect-garbage -d
	sudo nixos-rebuild boot --flake ".#${NIXNAME}"
	-docker builder prune -f
	-docker image prune -f
	-docker volume prune -f

optimize: ## Optimize nix store
	nix-store --optimize

check-kernel: ## Check current vs available kernel versions
	@echo "Current kernel: $$(uname -r)"
	@echo "Latest nixpkgs kernel: $$(nix eval --raw nixpkgs#linuxPackages_latest.kernel.version)"
	@echo "Pinned 6.15.2 kernel: $$(nix eval --raw .#nixosConfigurations.${NIXNAME}.config.boot.kernelPackages.kernel.version)"

check-claude-version: ## Check current vs latest Claude Code version
	@echo "Current claude-code version: $$(jq -r .version claude-version.json)"
	@echo "Latest claude-code version: $$(npm view @anthropic-ai/claude-code version)"

upgrade-claude: ## Update Claude Code to latest version from npm
	./scripts/claude-update

switch: ## Apply configuration changes (rebuilds and switches)
ifeq ($(UNAME), Darwin)
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXNAME}"
else
	sudo nixos-rebuild switch --flake ".#${NIXNAME}"
endif

test: ## Test configuration changes without switching
ifeq ($(UNAME), Darwin)
	nix build ".#darwinConfigurations.${NIXNAME}.system"
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${NIXNAME}"
else
	sudo nixos-rebuild test --flake ".#$(NIXNAME)"
endif

vm/bootstrap0: ## Bootstrap brand new VM with NixOS installation
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted $(HDDEV) -- mklabel gpt; \
		parted $(HDDEV) -- mkpart primary 512MB -8GB; \
		parted $(HDDEV) -- mkpart primary linux-swap -8GB 100\%; \
		parted $(HDDEV) -- mkpart ESP fat32 1MB 512MB; \
		parted $(HDDEV) -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos $(HDDEV)p1; \
		mkswap -L swap $(HDDEV)p2; \
		mkfs.fat -F 32 -n boot $(HDDEV)p3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixUnstable;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
  			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

vm/bootstrap: ## Finalize VM bootstrap after initial installation
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

vm/secrets: ## Copy GPG and SSH secrets into the VM
	# GPG keyring
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='.#*' \
		--exclude='S.*' \
		--exclude='*.conf' \
		$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg
	# SSH keys
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh

vm/copy: ## Copy Nix configurations into the VM
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

vm/switch: ## Run nixos-rebuild switch in the VM (requires vm/copy first)
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/nix-config#${NIXNAME}\" \
	"
