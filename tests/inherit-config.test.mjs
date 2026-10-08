import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";

import { buildEnv, installFakeCodex } from "./fake-codex-fixture.mjs";
import { initGitRepo, makeTempDir, run } from "./helpers.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SCRIPT = path.join(ROOT, "plugins", "codex", "scripts", "codex-companion.mjs");

function repoWithUncommittedChange() {
  const repo = makeTempDir();
  initGitRepo(repo);
  fs.mkdirSync(path.join(repo, "src"));
  fs.writeFileSync(path.join(repo, "src", "app.js"), "export const value = items[0];\n");
  run("git", ["add", "src/app.js"], { cwd: repo });
  run("git", ["commit", "-m", "init"], { cwd: repo });
  fs.writeFileSync(path.join(repo, "src", "app.js"), "export const value = items[0].id;\n");
  return repo;
}

function runCompanion(args) {
  const repo = repoWithUncommittedChange();
  const binDir = makeTempDir();
  installFakeCodex(binDir);
  const result = run("node", [SCRIPT, ...args], { cwd: repo, env: buildEnv(binDir) });
  assert.equal(result.status, 0, result.stderr);
  const state = JSON.parse(fs.readFileSync(path.join(binDir, "fake-codex-state.json"), "utf8"));
  return state.lastThreadStartPolicy;
}

// Intention: a null sandbox and approval policy make the app-server resolve both from the user's config.toml.
const INHERITED = { sandbox: null, approvalPolicy: null };

test("task defers sandbox and approval policy to the user's Codex config", () => {
  assert.deepEqual(runCompanion(["task", "inspect the change"]), INHERITED);
});

test("task --write requests a workspace-write sandbox and keeps the configured approval policy", () => {
  assert.deepEqual(runCompanion(["task", "--write", "apply the fix"]), { sandbox: "workspace-write", approvalPolicy: null });
});

test("review defers sandbox and approval policy to the user's Codex config", () => {
  assert.deepEqual(runCompanion(["review"]), INHERITED);
});

test("adversarial review defers sandbox and approval policy to the user's Codex config", () => {
  assert.deepEqual(runCompanion(["adversarial-review"]), INHERITED);
});
