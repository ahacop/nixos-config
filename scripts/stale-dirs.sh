#!/usr/bin/env bash
#
# Lists or deletes the .direnv and Rust target/ directories of projects that
# show no git activity for DAYS days. The Makefile targets stale-direnvs,
# clean-direnvs, stale-targets and clean-targets call it, so a stale-* target
# lists exactly what the matching clean-* target deletes.
#
#   stale-dirs.sh list|clean direnv|target DAYS DIR...
#
# A repository is stale when it has no commit in the last DAYS days and its
# HEAD and index files are older than that too. Checkouts, staging and fresh
# clones update HEAD and index, so a newly cloned repository counts as active.
#
# A .direnv counts only when the directory that holds it is the root of a
# repository: it has a .git directory, or a .git file for a worktree.
#
# Cargo never deletes old build output from target/, so it grows with each
# toolchain or dependency change. A target/ counts only when a Cargo.toml sits
# next to it. The staleness test uses the repository that holds the crate, so
# a crate in a subdirectory of a repository works.

set -eu

usage() {
  echo "usage: $0 list|clean direnv|target DAYS DIR..." >&2
  exit 1
}

[ $# -ge 3 ] || usage
action=$1 kind=$2 days=$3
shift 3

case "$action" in list | clean) ;; *) usage ;; esac
case "$kind" in
  direnv) label=".direnv" ;;
  target) label="Rust target/" ;;
  *) usage ;;
esac

# Succeeds when the repository at ROOT shows no activity in the last $days
# days.
repo_is_stale() {
  local root=$1 gitdir
  gitdir=$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  [ -z "$(git -C "$root" log -1 --since="$days days ago" --format=%h 2>/dev/null)" ] || return 1
  [ -z "$(find "$gitdir/HEAD" "$gitdir/index" -mtime -"$days" 2>/dev/null)" ]
}

# Prints "ROOT<TAB>DIRECTORY" for each stale directory of $kind under the
# given directories. ROOT is the repository that the staleness test used.
stale_dirs() {
  local dir found root
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    if [ "$kind" = direnv ]; then
      while IFS= read -r found; do
        root=$(dirname "$found")
        [ -e "$root/.git" ] || continue
        if repo_is_stale "$root"; then printf '%s\t%s\n' "$root" "$found"; fi
      done < <(find "$dir" -name .direnv -type d 2>/dev/null)
    else
      while IFS= read -r found; do
        [ -f "$(dirname "$found")/Cargo.toml" ] || continue
        root=$(git -C "$(dirname "$found")" rev-parse --show-toplevel 2>/dev/null) || continue
        if repo_is_stale "$root"; then printf '%s\t%s\n' "$root" "$found"; fi
      done < <(find "$dir" -name target -type d -prune 2>/dev/null)
    fi
  done
}

if [ "$action" = list ]; then
  echo "=== $label in projects inactive for $days+ days ==="
  echo ""
  # A .direnv line shows the project. A target/ line shows the target/
  # directory, because one repository can hold several crates.
  out=$(stale_dirs "$@" | while IFS=$'\t' read -r root found; do
    git_date=$(git -C "$root" log -1 --format=%ci 2>/dev/null | cut -d' ' -f1)
    size=$(du -sh "$found" 2>/dev/null | cut -f1)
    if [ "$kind" = direnv ]; then shown=$root; else shown=$found; fi
    printf "%-12s %-8s %s\n" "${git_date:-(unknown)}" "$size" "$shown"
  done | sort)
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo "(none found)"; fi
else
  echo "Removing $label from projects inactive for $days+ days..."
  stale_dirs "$@" | while IFS=$'\t' read -r _ found; do
    if [ "$kind" = direnv ]; then
      echo "  Removing $found"
    else
      echo "  Removing $found ($(du -sh "$found" 2>/dev/null | cut -f1))"
    fi
    rm -rf "$found"
  done
  echo "Done."
fi
