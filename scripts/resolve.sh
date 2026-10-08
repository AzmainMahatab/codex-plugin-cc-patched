#!/usr/bin/env bash
# Resolve which upstream release to build and the patched version string for it.
# Prints `tag=<upstream tag>` and `version=<patched version>` lines (GITHUB_OUTPUT format).
set -euo pipefail

readonly UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/openai/codex-plugin-cc.git}"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

latest_stable_tag() {
  # Why: only plain vMAJOR.MINOR.PATCH tags are releases; pre-release tags are skipped.
  git ls-remote --tags --refs "$UPSTREAM_URL" \
    | awk '{ sub("refs/tags/", "", $2); print $2 }' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
}

patchset_hash() {
  # Intention: any change to the patch queue yields a new version, so Claude Code picks up the rebuild.
  LC_ALL=C cat "$REPO_ROOT"/patches/*.patch | sha256sum | cut -c1-8
}

tag="${UPSTREAM_TAG:-$(latest_stable_tag)}"
if [[ -z "$tag" ]]; then
  echo "No stable upstream tag found at $UPSTREAM_URL" >&2
  exit 1
fi

# Ex: v1.0.6 + patch hash 3f9a2c1d -> 1.0.6-patched.h3f9a2c1d (the "h" keeps the identifier alphanumeric).
echo "tag=$tag"
echo "version=${tag#v}-patched.h$(patchset_hash)"
