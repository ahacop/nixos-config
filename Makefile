# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= ahacop
HDDEV ?= /dev/nvme0n1

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= default

# Stale threshold in days for cleanup targets
STALE_DAYS ?= 30

# Directories to scan for stale items
CODE_DIRS ?= $(HOME)/code

# Machine-local secrets file (untracked, outside the Nix store) and the
# 1Password document it is backed up to/restored from. OP_VAULT is optional.
# OP_ACCOUNT selects which signed-in 1Password account to use. Override on the
# command line to target another one.
SECRETS_FILE ?= $(HOME)/.config/secrets.env
OP_SECRETS_ITEM ?= vm-secrets.env
OP_ACCOUNT ?= personal
OP_VAULT ?=
OP_ACCOUNT_FLAG := $(if $(OP_ACCOUNT),--account $(OP_ACCOUNT),)
OP_VAULT_FLAG := $(if $(OP_VAULT),--vault $(OP_VAULT),)

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS := -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

CLAUDE_OVERLAY_API := https://api.github.com/repos/ryoppippi/nix-claude-code/contents/versions

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help clean optimize check-kernel check-claude-version upgrade-claude restart-walker switch test vm/bootstrap0 vm/bootstrap vm/secrets vm/copy vm/switch
.PHONY: disk-status gc-roots stale-results stale-direnvs bloated-direnvs clean-results clean-direnvs clean-direnv-profiles clean-caches clean-stores clean-all
.PHONY: secrets/backup secrets/restore

# Help target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Configuration Management:'
	@grep -E '^(switch|test|optimize|clean|restart-walker):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Disk Cleanup (use STALE_DAYS=N to adjust threshold, default 30):'
	@grep -E '^(disk-status|gc-roots|stale-[a-z]+|bloated-[a-z]+|clean-[a-z-]+):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Package Updates:'
	@grep -E '^upgrade-.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'System Info:'
	@grep -E '^check-.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Secrets:'
	@grep -E '^secrets/.*:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
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
	-docker system prune -a --volumes

optimize: ## Optimize nix store
	nix-store --optimize

# =============================================================================
# Disk Status & Cleanup Targets
# =============================================================================

disk-status: ## Show disk usage overview (nix store, caches, docker)
	@echo "=== Disk Usage Overview ==="
	@echo ""
	@echo "Filesystem:"
	@df -h / | tail -1 | awk '{printf "  Used: %s / %s (%s)\n", $$3, $$2, $$5}'
	@echo ""
	@echo "Nix store:"
	@du -sh /nix/store 2>/dev/null | awk '{printf "  Size: %s\n", $$1}'
	@echo "  GC roots: $$(ls /nix/var/nix/gcroots/auto/ 2>/dev/null | wc -l)"
	@echo ""
	@echo "Caches:"
	@for dir in nix mozilla trivy ms-playwright pip bundix; do \
		if [ -d "$(HOME)/.cache/$$dir" ]; then \
			size=$$(du -sh "$(HOME)/.cache/$$dir" 2>/dev/null | cut -f1); \
			printf "  ~/.cache/%-15s %s\n" "$$dir" "$$size"; \
		fi; \
	done
	@echo ""
	@echo "Docker:"
	@if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then \
		docker system df --format 'table  {{.Type}}\t{{.Size}}\t{{.Reclaimable}}' 2>/dev/null || echo "  (not running)"; \
	else \
		echo "  (not running)"; \
	fi

gc-roots: ## List all GC roots with status
	@echo "=== GC Roots ==="
	@echo ""
	@for link in /nix/var/nix/gcroots/auto/*; do \
		target=$$(readlink "$$link" 2>/dev/null); \
		if [ -e "$$target" ]; then \
			status="OK"; \
		else \
			status="BROKEN"; \
		fi; \
		printf "%-7s %s\n" "$$status" "$$target"; \
	done | sort -k2

stale-results: ## Find result symlinks older than STALE_DAYS
	@echo "=== Result symlinks older than $(STALE_DAYS) days ==="
	@echo ""
	@found=0; \
	for dir in $(CODE_DIRS) $(HOME)/nixos-config; do \
		if [ -d "$$dir" ]; then \
			while IFS= read -r link; do \
				if [ -n "$$link" ]; then \
					mdate=$$(stat -c %y "$$link" 2>/dev/null | cut -d' ' -f1); \
					printf "%s  %s\n" "$$mdate" "$$link"; \
					found=1; \
				fi; \
			done < <(find "$$dir" -name "result" -type l -mtime +$(STALE_DAYS) 2>/dev/null); \
		fi; \
	done; \
	if [ "$$found" = "0" ]; then echo "(none found)"; fi

stale-direnvs: ## Find .direnv in projects with no git activity in STALE_DAYS
	@echo "=== .direnv in projects inactive for $(STALE_DAYS)+ days ==="
	@echo ""
	@found=0; \
	for dir in $(CODE_DIRS); do \
		if [ -d "$$dir" ]; then \
			while IFS= read -r denv; do \
				if [ -n "$$denv" ]; then \
					proj=$$(dirname "$$denv"); \
					if [ -d "$$proj/.git" ]; then \
						latest=$$(find "$$proj" -maxdepth 2 \( -name "*.rb" -o -name "*.nix" -o -name "*.go" -o -name "*.ts" -o -name "*.js" -o -name "*.ex" -o -name "Gemfile.lock" \) -mtime -$(STALE_DAYS) 2>/dev/null | head -1); \
						if [ -z "$$latest" ]; then \
							git_date=$$(git -C "$$proj" log -1 --format=%ci 2>/dev/null | cut -d' ' -f1); \
							size=$$(du -sh "$$denv" 2>/dev/null | cut -f1); \
							printf "%-12s %-8s %s\n" "$${git_date:-(unknown)}" "$$size" "$$proj"; \
							found=1; \
						fi; \
					fi; \
				fi; \
			done < <(find "$$dir" -name ".direnv" -type d 2>/dev/null); \
		fi; \
	done | sort; \
	if [ "$$found" = "0" ]; then echo "(none found)"; fi

bloated-direnvs: ## Find .direnv with multiple old flake profiles
	@echo "=== .direnv folders with multiple profiles ==="
	@echo ""
	@found=0; \
	for dir in $(CODE_DIRS); do \
		if [ -d "$$dir" ]; then \
			find "$$dir" -name ".direnv" -type d 2>/dev/null | while read -r denv; do \
				count=$$(ls -1 "$$denv"/flake-profile-* 2>/dev/null | grep -v '\.rc$$' | wc -l); \
				if [ "$$count" -gt 1 ]; then \
					current=$$(readlink "$$denv/flake-profile" 2>/dev/null | xargs basename 2>/dev/null); \
					size=$$(du -sh "$$denv" 2>/dev/null | cut -f1); \
					printf "%-8s %2d profiles  %s  (current: %s)\n" "$$size" "$$count" "$$denv" "$$current"; \
					found=1; \
				fi; \
			done; \
		fi; \
	done; \
	if [ "$$found" = "0" ]; then echo "(none found)"; fi

clean-direnv-profiles: ## Remove old flake profiles, keeping only current
	@echo "Cleaning old flake profiles from .direnv folders..."
	@for dir in $(CODE_DIRS); do \
		if [ -d "$$dir" ]; then \
			find "$$dir" -name ".direnv" -type d 2>/dev/null | while read -r denv; do \
				current=$$(readlink "$$denv/flake-profile" 2>/dev/null); \
				if [ -n "$$current" ]; then \
					for profile in "$$denv"/flake-profile-*; do \
						case "$$profile" in \
							*.rc) ;; \
							"$$current") ;; \
							*) \
								echo "  Removing $$(basename $$profile) from $$denv"; \
								rm -f "$$profile" "$${profile}.rc" 2>/dev/null; \
								;; \
						esac; \
					done; \
				fi; \
			done; \
		fi; \
	done
	@echo "Done."

clean-results: ## Remove result symlinks older than STALE_DAYS
	@echo "Removing result symlinks older than $(STALE_DAYS) days..."
	@for dir in $(CODE_DIRS) $(HOME)/nixos-config; do \
		if [ -d "$$dir" ]; then \
			find "$$dir" -name "result" -type l -mtime +$(STALE_DAYS) -print -delete 2>/dev/null; \
		fi; \
	done
	@echo "Done."

clean-direnvs: ## Remove .direnv from projects inactive for STALE_DAYS
	@echo "Removing .direnv from projects inactive for $(STALE_DAYS)+ days..."
	@for dir in $(CODE_DIRS); do \
		if [ -d "$$dir" ]; then \
			find "$$dir" -name ".direnv" -type d 2>/dev/null | while read -r denv; do \
				proj=$$(dirname "$$denv"); \
				if [ -d "$$proj/.git" ]; then \
					latest=$$(find "$$proj" -maxdepth 2 \( -name "*.rb" -o -name "*.nix" -o -name "*.go" -o -name "*.ts" -o -name "*.js" -o -name "*.ex" -o -name "Gemfile.lock" \) -mtime -$(STALE_DAYS) 2>/dev/null | head -1); \
					if [ -z "$$latest" ]; then \
						echo "  Removing $$denv"; \
						rm -rf "$$denv"; \
					fi; \
				fi; \
			done; \
		fi; \
	done
	@echo "Done."

# Re-downloadable tool caches safe to nuke. Listed explicitly so adding a new
# one is a deliberate review (don't add ~/.cache/mozilla without thinking).
SAFE_CACHE_DIRS := nix trivy ms-playwright puppeteer chrome-devtools-mcp \
	pip deno bundix go-build bun pnpm chromium informers

clean-caches: ## Clean nix and other re-downloadable tool caches
	@echo "Cleaning caches..."
	@for name in $(SAFE_CACHE_DIRS); do \
		dir="$(HOME)/.cache/$$name"; \
		if [ -d "$$dir" ]; then \
			size=$$(du -sh "$$dir" 2>/dev/null | cut -f1); \
			rm -rf "$$dir"; \
			printf "  Removed ~/.cache/%-22s (%s)\n" "$$name" "$$size"; \
		fi; \
	done
	@echo "Done."

clean-stores: ## Prune content-addressable package stores (pnpm, gem)
	@echo "Pruning package stores..."
	@if [ -d "$(HOME)/.local/share/pnpm/store" ]; then \
		size=$$(du -sh "$(HOME)/.local/share/pnpm/store" 2>/dev/null | cut -f1); \
		rm -rf "$(HOME)/.local/share/pnpm/store"; \
		printf "  Removed ~/.local/share/pnpm/store    (%s)\n" "$$size"; \
	fi
	@if [ -d "$(HOME)/.local/share/gem" ]; then \
		size=$$(du -sh "$(HOME)/.local/share/gem" 2>/dev/null | cut -f1); \
		rm -rf "$(HOME)/.local/share/gem"; \
		printf "  Removed ~/.local/share/gem           (%s)\n" "$$size"; \
	fi
	@echo "Done."

clean-all: clean-results clean-direnvs clean-caches clean-stores clean ## Full cleanup (stale items + caches + stores + gc)
	@echo ""
	@echo "=== Full cleanup complete ==="

check-kernel: ## Check current vs available kernel versions
	@echo "Current kernel: $$(uname -r)"
	@echo "Latest nixpkgs kernel: $$(nix eval --raw nixpkgs#linuxPackages_latest.kernel.version)"
	@echo "Pinned 6.15.2 kernel: $$(nix eval --raw .#nixosConfigurations.${NIXNAME}.config.boot.kernelPackages.kernel.version)"

check-claude-version: ## Check current vs latest Claude Code version
	@echo "Installed: $$(claude --version)"
	@echo "Pinned:    $$(REV=$$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes["claude-code-overlay"].locked.rev // empty'); \
		curl -sf "$(CLAUDE_OVERLAY_API)?ref=$$REV" | jq -r '[.[].name | select(endswith(".json")) | rtrimstr(".json")] | sort_by(split(".") | map(tonumber)) | last')"
	@echo "Latest:    $$(curl -sf '$(CLAUDE_OVERLAY_API)' | jq -r '[.[].name | select(endswith(".json")) | rtrimstr(".json")] | sort_by(split(".") | map(tonumber)) | last')"

upgrade-claude: ## Update Claude Code overlay to latest version
	nix flake update claude-code-overlay

restart-walker: ## Restart Walker and Elephant services
	systemctl --user restart elephant.service
	systemctl --user restart walker.service

switch: ## Apply configuration changes (rebuilds and switches)
	sudo nixos-rebuild switch --flake ".#${NIXNAME}"

test: ## Test configuration changes without switching
	sudo nixos-rebuild test --flake ".#$(NIXNAME)"

# =============================================================================
# Secrets (machine-local env file, archived in 1Password — never committed)
# =============================================================================

secrets/backup: ## Back up local secrets.env to 1Password
	@command -v op >/dev/null 2>&1 || { echo "op (1Password CLI) not found. Try: nix-shell -p _1password-cli"; exit 1; }
	@if [ ! -f "$(SECRETS_FILE)" ]; then echo "No secrets file at $(SECRETS_FILE)"; exit 1; fi
	@if op document get "$(OP_SECRETS_ITEM)" $(OP_ACCOUNT_FLAG) $(OP_VAULT_FLAG) >/dev/null 2>&1; then \
		echo "Updating 1Password document '$(OP_SECRETS_ITEM)'..."; \
		op document edit "$(OP_SECRETS_ITEM)" "$(SECRETS_FILE)" $(OP_ACCOUNT_FLAG) $(OP_VAULT_FLAG); \
	else \
		echo "Creating 1Password document '$(OP_SECRETS_ITEM)'..."; \
		op document create "$(SECRETS_FILE)" --title "$(OP_SECRETS_ITEM)" $(OP_ACCOUNT_FLAG) $(OP_VAULT_FLAG); \
	fi
	@echo "Done."

secrets/restore: ## Restore local secrets.env from 1Password
	@command -v op >/dev/null 2>&1 || { echo "op (1Password CLI) not found. Try: nix-shell -p _1password-cli"; exit 1; }
	@mkdir -p "$$(dirname "$(SECRETS_FILE)")"
	@echo "Fetching 1Password document '$(OP_SECRETS_ITEM)' -> $(SECRETS_FILE)..."
	@op document get "$(OP_SECRETS_ITEM)" $(OP_ACCOUNT_FLAG) $(OP_VAULT_FLAG) --out-file "$(SECRETS_FILE)"
	@chmod 600 "$(SECRETS_FILE)"
	@echo "Done. Run 'source $(SECRETS_FILE)' or open a new shell to load it."

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
