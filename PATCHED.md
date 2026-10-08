# Patched build

This tree is [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) with the patches from
[AzmainMahatab/codex-plugin-cc-patched](https://github.com/AzmainMahatab/codex-plugin-cc-patched) applied.
It is not an official OpenAI release.

Changes from upstream:

- The plugin no longer pins `sandbox: "read-only"` / `approvalPolicy: "never"` for tasks, native review and
  adversarial review. It sends `null`, so Codex applies `sandbox_mode`, `approval_policy` and `approvals_reviewer`
  from `~/.codex/config.toml`. An explicit `task --write` still requests a workspace-write sandbox.
- The rescue agent and runtime skill no longer add `--write` by default.
- The marketplace is renamed to `codex-plugin-cc-patched`; the plugin is still named `codex`.
- Versions are `<upstream version>-patched.h<patch-set hash>`.

Upstream is licensed under the Apache License 2.0 (see `LICENSE` and `NOTICE`); the patches are under the same license.
