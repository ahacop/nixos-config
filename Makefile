# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= ahacop
HDDEV ?= /dev/nvme0n1

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= default

# Recipes use bash features (process substitution), not plain POSIX sh.
SHELL := bash

# Stale threshold in days for cleanup targets
STALE_DAYS ?= 30

# Directories to scan for stale items
CODE_DIRS ?= $(HOME)/code

# Re-downloadable tool caches safe to nuke. Listed explicitly so adding a new
# one is a deliberate review (don't add ~/.cache/mozilla without thinking).
# disk-status reports these; clean-caches deletes them.
SAFE_CACHE_DIRS := nix trivy ms-playwright puppeteer chrome-devtools-mcp \
	pip deno bundix go-build bun pnpm chromium informers

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

# LLM agent CLIs come from the numtide llm-agents flake input. The list of
# tools lives once in flake.nix (llmAgentNames), exposed as the llmAgents
# output (package name -> binary name), so check-versions derives it rather
# than duplicating it.
LLM_AGENTS_REPO := numtide/llm-agents.nix
LLM_AGENTS_SYSTEM := aarch64-linux

# Default target
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help clean optimize check-versions upgrade-agents restart-walker switch test vm/bootstrap0 vm/bootstrap vm/secrets vm/copy vm/switch
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
	-docker system prune -a --volumes -f

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
	@for name in $(SAFE_CACHE_DIRS); do \
		if [ -d "$(HOME)/.cache/$$name" ]; then \
			size=$$(du -sh "$(HOME)/.cache/$$name" 2>/dev/null | cut -f1); \
			printf "  ~/.cache/%-22s %s\n" "$$name" "$$size"; \
		fi; \
	done
	@if [ -d "$(HOME)/.cache/mozilla" ]; then \
		size=$$(du -sh "$(HOME)/.cache/mozilla" 2>/dev/null | cut -f1); \
		printf "  ~/.cache/%-22s %s (not cleaned by clean-caches)\n" "mozilla" "$$size"; \
	fi
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
	@out=$$(for dir in $(CODE_DIRS) $(MAKEFILE_DIR); do \
		[ -d "$$dir" ] || continue; \
		while IFS= read -r link; do \
			mdate=$$(stat -c %y "$$link" 2>/dev/null | cut -d' ' -f1); \
			printf "%s  %s\n" "$$mdate" "$$link"; \
		done < <(find "$$dir" \( -name "result" -o -name "result-*" \) -type l -mtime +$(STALE_DAYS) 2>/dev/null); \
	done | sort); \
	if [ -n "$$out" ]; then printf '%s\n' "$$out"; else echo "(none found)"; fi

# A project is stale when its repo shows no activity for STALE_DAYS: no commit
# in the window, and .git/HEAD and .git/index untouched. Checkouts, staging,
# and fresh clones update HEAD/index, so a newly cloned repo counts as active.
# stale-direnvs previews exactly what clean-direnvs deletes; keep their
# staleness tests identical.
stale-direnvs: ## Find .direnv in projects with no git activity in STALE_DAYS
	@echo "=== .direnv in projects inactive for $(STALE_DAYS)+ days ==="
	@echo ""
	@out=$$(for dir in $(CODE_DIRS); do \
		[ -d "$$dir" ] || continue; \
		while IFS= read -r denv; do \
			proj=$$(dirname "$$denv"); \
			[ -d "$$proj/.git" ] || continue; \
			[ -z "$$(git -C "$$proj" log -1 --since='$(STALE_DAYS) days ago' --format=%h 2>/dev/null)" ] || continue; \
			[ -z "$$(find "$$proj/.git/HEAD" "$$proj/.git/index" -mtime -$(STALE_DAYS) 2>/dev/null)" ] || continue; \
			git_date=$$(git -C "$$proj" log -1 --format=%ci 2>/dev/null | cut -d' ' -f1); \
			size=$$(du -sh "$$denv" 2>/dev/null | cut -f1); \
			printf "%-12s %-8s %s\n" "$${git_date:-(unknown)}" "$$size" "$$proj"; \
		done < <(find "$$dir" -name ".direnv" -type d 2>/dev/null); \
	done | sort); \
	if [ -n "$$out" ]; then printf '%s\n' "$$out"; else echo "(none found)"; fi

# nix-direnv names each profile flake-profile-<hash> with a matching .rc file
# and creates a new pair whenever the flake inputs change; old pairs pile up
# as GC roots. The newest pair backs the current environment.
bloated-direnvs: ## Find .direnv with multiple flake profiles
	@echo "=== .direnv folders with multiple profiles ==="
	@echo ""
	@out=$$(for dir in $(CODE_DIRS); do \
		[ -d "$$dir" ] || continue; \
		while IFS= read -r denv; do \
			count=$$(ls -1 "$$denv"/flake-profile-* 2>/dev/null | grep -cv '\.rc$$'); \
			[ "$$count" -gt 1 ] || continue; \
			newest=$$(ls -1t "$$denv"/flake-profile-* 2>/dev/null | grep -v '\.rc$$' | head -1); \
			size=$$(du -sh "$$denv" 2>/dev/null | cut -f1); \
			printf "%-8s %2d profiles  %s  (newest: %s)\n" "$$size" "$$count" "$$denv" "$$(basename "$$newest")"; \
		done < <(find "$$dir" -name ".direnv" -type d 2>/dev/null); \
	done); \
	if [ -n "$$out" ]; then printf '%s\n' "$$out"; else echo "(none found)"; fi

# Keeps the newest flake-profile-<hash> pair per .direnv and deletes the rest.
# If the kept guess is ever wrong, direnv just rebuilds the environment on the
# next load — nothing breaks.
clean-direnv-profiles: ## Remove old flake profiles, keeping the newest
	@echo "Cleaning old flake profiles from .direnv folders..."
	@for dir in $(CODE_DIRS); do \
		[ -d "$$dir" ] || continue; \
		while IFS= read -r denv; do \
			keep=$$(ls -1t "$$denv"/flake-profile-* 2>/dev/null | grep -v '\.rc$$' | head -1); \
			[ -n "$$keep" ] || continue; \
			for profile in "$$denv"/flake-profile-*; do \
				case "$$profile" in *.rc) continue ;; esac; \
				[ "$$profile" = "$$keep" ] && continue; \
				echo "  Removing $$(basename "$$profile") from $$denv"; \
				rm -f "$$profile" "$${profile}.rc"; \
			done; \
		done < <(find "$$dir" -name ".direnv" -type d 2>/dev/null); \
	done
	@echo "Done."

clean-results: ## Remove result symlinks older than STALE_DAYS
	@echo "Removing result symlinks older than $(STALE_DAYS) days..."
	@for dir in $(CODE_DIRS) $(MAKEFILE_DIR); do \
		[ -d "$$dir" ] || continue; \
		find "$$dir" \( -name "result" -o -name "result-*" \) -type l -mtime +$(STALE_DAYS) -print -delete 2>/dev/null; \
	done
	@echo "Done."

# The staleness test matches stale-direnvs; keep them identical.
clean-direnvs: ## Remove .direnv from projects with no git activity in STALE_DAYS
	@echo "Removing .direnv from projects inactive for $(STALE_DAYS)+ days..."
	@for dir in $(CODE_DIRS); do \
		[ -d "$$dir" ] || continue; \
		while IFS= read -r denv; do \
			proj=$$(dirname "$$denv"); \
			[ -d "$$proj/.git" ] || continue; \
			[ -z "$$(git -C "$$proj" log -1 --since='$(STALE_DAYS) days ago' --format=%h 2>/dev/null)" ] || continue; \
			[ -z "$$(find "$$proj/.git/HEAD" "$$proj/.git/index" -mtime -$(STALE_DAYS) 2>/dev/null)" ] || continue; \
			echo "  Removing $$denv"; \
			rm -rf "$$denv"; \
		done < <(find "$$dir" -name ".direnv" -type d 2>/dev/null); \
	done
	@echo "Done."

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

clean-stores: ## Remove pnpm store and user-installed gems (re-downloadable)
	@echo "Removing package stores..."
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

clean-all: clean-results clean-direnvs clean-direnv-profiles clean-caches clean-stores clean ## Full cleanup (stale items + old profiles + caches + stores + gc)
	@echo ""
	@echo "=== Full cleanup complete ==="

check-versions: ## Compare installed LLM agent CLI versions with the latest the llm-agents flake ships
	@MAP=$$(nix eval --json .#llmAgents 2>/dev/null); \
	LATEST=$$(nix eval --impure --json --expr "let f = builtins.getFlake \"github:$(LLM_AGENTS_REPO)\"; p = f.packages.$(LLM_AGENTS_SYSTEM); names = builtins.attrNames (builtins.fromJSON ''$$MAP''); in builtins.listToAttrs (map (n: { name = n; value = p.\$${n}.version or \"?\"; }) names)" 2>/dev/null); \
	printf '%-12s %-26s %s\n' TOOL INSTALLED 'LATEST (flake)'; \
	for n in $$(printf '%s' "$$MAP" | jq -r 'keys[]'); do \
		bin=$$(printf '%s' "$$MAP" | jq -r --arg n "$$n" '.[$$n]'); \
		latest=$$(printf '%s' "$$LATEST" | jq -r --arg n "$$n" '.[$$n]'); \
		if command -v $$bin >/dev/null 2>&1; then \
			inst=$$($$bin --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+[0-9a-zA-Z.+_-]*' | head -n1); \
			[ -z "$$inst" ] && inst='?'; \
			if [ "$$inst" = "$$latest" ]; then mark=''; else mark='  <- update'; fi; \
		else \
			inst='(not on PATH)'; mark=''; \
		fi; \
		printf '%-12s %-26s %s%s\n' "$$bin" "$$inst" "$$latest" "$$mark"; \
	done
	@PINNED=$$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes["llm-agents"].locked.rev'); \
	DATE=$$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes["llm-agents"].locked.lastModified | todate'); \
	UPSTREAM=$$(curl -sf 'https://api.github.com/repos/$(LLM_AGENTS_REPO)/commits/main' | jq -r '.sha // empty'); \
	printf '\n%-12s pinned %s (%s)\n' llm-agents "$$(printf '%s' "$$PINNED" | cut -c1-12)" "$$DATE"; \
	if [ -n "$$UPSTREAM" ] && [ "$$PINNED" != "$$UPSTREAM" ]; then \
		printf '%-12s upstream %s available — run: make upgrade-agents\n' '' "$$(printf '%s' "$$UPSTREAM" | cut -c1-12)"; \
	elif [ -n "$$UPSTREAM" ]; then \
		printf '%-12s pin is current with upstream main\n' ''; \
	fi

upgrade-agents: ## Update the numtide llm-agents flake (claude, codex, amp, pi, opencode, hunk, ccusage)
	nix flake update llm-agents

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
