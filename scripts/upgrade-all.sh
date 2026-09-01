#!/usr/bin/env bash
#
# Rewrites the tip of the branch into two commits: "Update flake" for every
# flake input except llm-agents, then "Update agents" for llm-agents on top.
#
# It drops whichever of those two commits already sits at the tip and builds
# them again from the current inputs, so flake.lock is regenerated instead of
# merged. Amending in place would need a cherry-pick of the agents commit over
# a rewritten flake commit, and both commits edit the same lines of the same
# file, so every run would conflict.
#
# The run stops before it touches history if the working tree is dirty or if a
# tip commit changes any file other than flake.lock. The rebuilt commits
# replace the old ones, so a branch that is already on the remote needs
# git push --force-with-lease.

set -euo pipefail

# The input that gets its own commit. Every other top-level input goes into the
# "Update flake" commit below it.
AGENTS_INPUT="llm-agents"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is dirty. Commit or stash first." >&2
  exit 1
fi

# Peel the two commits off the tip, newest first, so the run starts from the
# commit that carries neither update.
orig=$(git rev-parse HEAD)
base=$orig
for want in "Update agents" "Update flake"; do
  [ "$(git log -1 --format=%s "$base")" = "$want" ] || continue
  if [ "$(git show --name-only --format= "$base")" != "flake.lock" ]; then
    echo "Commit $(git rev-parse --short "$base") ($want) changes more than flake.lock. Stopping." >&2
    exit 1
  fi
  base=$(git rev-parse "$base^")
done

echo "Rebuilding on $(git rev-parse --short "$base"). To undo: git reset --hard $orig"
git reset -q --hard "$base"

# Commit flake.lock under the given message, or report that the update was a
# no-op. The tree is clean apart from flake.lock, so committing the index is
# the same as committing that one path, and it also catches the case where
# flake.lock is untracked at the base commit.
commit_lock() {
  local message=$1 label=$2
  git add flake.lock
  if git diff --cached --quiet; then
    echo "No $label changes."
  else
    git commit -q -m "$message"
    echo "Committed: $message"
  fi
}

mapfile -t inputs < <(
  nix flake metadata --json |
    jq -r --arg skip "$AGENTS_INPUT" '.locks.nodes.root.inputs | keys[] | select(. != $skip)'
)
nix flake update "${inputs[@]}"
commit_lock "Update flake" "flake input"

nix flake update "$AGENTS_INPUT"
commit_lock "Update agents" "agent"

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [ -n "$upstream" ] && ! git merge-base --is-ancestor "$upstream" HEAD; then
  echo "Note: $upstream is not an ancestor of the new tip. Pushing needs --force-with-lease."
fi

echo
git log --oneline -3
