# codex-plugin-cc-patched

[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) (the Codex plugin for Claude Code), rebuilt
automatically from each upstream release with a small patch queue applied. Not affiliated with OpenAI.

## What the patch changes

Upstream hardcodes `sandbox: "read-only"` / `"workspace-write"` and `approvalPolicy: "never"` for every Codex thread
it starts, which overrides `~/.codex/config.toml` (upstream issue
[#482](https://github.com/openai/codex-plugin-cc/issues/482)). With `approvalPolicy: "never"`, Codex's auto-review
("Approve for me") can never run, and on Windows the forced sandbox can make every shell command fail.

The patch sends `null` instead, so Codex resolves `sandbox_mode`, `approval_policy` and `approvals_reviewer` from your
config — the same way the plugin already treats `model`. Details: [`PATCHED.md`](PATCHED.md) and
[`patches/`](patches/).

## Install in Claude Code

Add the marketplace (the `dist` branch holds the built plugin):

```json
// ~/.claude/settings.json
{
  "extraKnownMarketplaces": {
    "codex-plugin-cc-patched": {
      "source": { "source": "github", "repo": "AzmainMahatab/codex-plugin-cc-patched", "ref": "dist" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "codex@codex-plugin-cc-patched": true }
}
```

Disable or uninstall `codex@openai-codex` first so the two copies don't both register `/codex:*` commands.

## How updates work

`.github/workflows/sync.yml` runs daily, on demand, and whenever the patch queue changes:

1. Resolve the latest stable upstream tag (`vX.Y.Z`) and the version `X.Y.Z-patched.h<hash of patches/>`.
2. Skip if `dist` already has that version.
3. Clone the tag, `git am --3way patches/*.patch`, run upstream's `npm test` and `npm run build`.
4. Set the version with upstream's `scripts/bump-version.mjs`, rename the marketplace, and commit the tree to `dist`
   (append-only, never force-pushed).

If any step fails, the workflow opens (or comments on) an issue labelled `sync-failure` and `dist` stays on the last
good build.

GitHub disables scheduled workflows in public repositories after 60 days without repository activity. If upstream
goes quiet for that long, re-enable the workflow from the Actions tab (GitHub emails a warning first).

## Updating the patch when upstream changes

```bash
git clone https://github.com/openai/codex-plugin-cc.git && cd codex-plugin-cc
git checkout vX.Y.Z
git am --3way ../codex-plugin-cc-patched/patches/*.patch   # resolve conflicts, then: git am --continue
npm ci && npm test
git format-patch vX.Y.Z --no-signature -o ../codex-plugin-cc-patched/patches/
```

Commit the regenerated `patches/` to `main`; the workflow rebuilds `dist`. Once upstream ships an equivalent change,
delete the patch.

## License

Apache License 2.0, as upstream. See `LICENSE`.
