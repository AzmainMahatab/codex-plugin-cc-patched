#!/usr/bin/env bash
# Commit a built tree onto the `dist` branch and push it. Appends commits only; never force-pushes.
# Usage: publish.sh <tree-dir> <version> <upstream-tag>
set -euo pipefail

readonly BRANCH="dist"
readonly COMMITTER=(-c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com")

tree_dir="$(cd "$1" && pwd)"
version="$2"
tag="$3"

worktree="$(mktemp -d)/dist"

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null; then
  git fetch --quiet origin "$BRANCH"
  git worktree add --quiet -B "$BRANCH" "$worktree" "origin/$BRANCH"
else
  git worktree add --quiet --orphan -b "$BRANCH" "$worktree"
fi
trap 'git worktree remove --force "$worktree"' EXIT

(
  cd "$worktree"
  git rm -rq --ignore-unmatch .
  cp -a "$tree_dir"/. .
  git add -A
  if git diff --cached --quiet; then
    echo "dist already matches $version; nothing to publish."
    exit 0
  fi
  git "${COMMITTER[@]}" commit --quiet -m "dist: $version (upstream $tag)"
  git push --quiet origin "$BRANCH"
  echo "Published $version to $BRANCH."
)
