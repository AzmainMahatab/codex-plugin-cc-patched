#!/usr/bin/env bash
# Build the patched plugin tree: upstream release + patches/, tested, re-versioned and re-branded.
# Usage: build.sh <upstream-tag> <version> <output-dir>
set -euo pipefail

readonly UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/openai/codex-plugin-cc.git}"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly MARKETPLACE_NAME="codex-plugin-cc-patched"
readonly MARKETPLACE_OWNER="AzmainMahatab"
# Why: these commits only exist in the throwaway clone (the tree is exported with git archive), but git am needs an identity.
readonly COMMITTER=(-c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com")

tag="$1"
version="$2"
out_dir="$3"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
src="$work/src"

git clone --quiet --depth 1 --branch "$tag" "$UPSTREAM_URL" "$src"
git -C "$src" "${COMMITTER[@]}" am --3way "$REPO_ROOT"/patches/*.patch

(
  cd "$src"
  npm ci --no-audit --no-fund
  npm test
  npm run build
  node scripts/bump-version.mjs "$version"
  node scripts/bump-version.mjs --check "$version"
)

# Why: the marketplace must not present itself as OpenAI's; the plugin stays named `codex` so /codex:* commands are unchanged.
marketplace="$src/.claude-plugin/marketplace.json"
jq --arg name "$MARKETPLACE_NAME" --arg owner "$MARKETPLACE_OWNER" --arg tag "$tag" '
  .name = $name
  | .owner = { name: $owner }
  | .metadata.description = "Codex plugin for Claude Code (upstream openai/codex-plugin-cc \($tag)), patched to follow the sandbox and approval settings in ~/.codex/config.toml."
' "$marketplace" > "$work/marketplace.json"
mv "$work/marketplace.json" "$marketplace"

cp "$REPO_ROOT/PATCHED.md" "$src/PATCHED.md"
git -C "$src" add -A
git -C "$src" "${COMMITTER[@]}" commit --quiet -m "Version $version"

mkdir -p "$out_dir"
git -C "$src" archive --format=tar HEAD | tar -x -C "$out_dir"
# Why: upstream's pull-request CI is not meant to run against the generated dist branch.
rm -rf "$out_dir/.github"
