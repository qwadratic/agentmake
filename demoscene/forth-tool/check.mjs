#!/usr/bin/env node
/**
 * Deterministic self-checks for the forth-tool extension (no LLM needed).
 * Loads index.ts via pi's jiti with a mock ExtensionAPI and asserts:
 *   1. exactly ONE tool registered, named "forth"
 *   2. persistence: define word in call 1, use it in call 2 (same VM)
 *   3. sandbox: relative-escape and absolute paths rejected
 *   4. fwrite/fread/load roundtrip inside cwd
 *   5. words/see introspection
 */
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const PI_PKG = "/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/package.json";
const piRequire = createRequire(PI_PKG);
const { createJiti } = piRequire("jiti");

const jiti = createJiti(import.meta.url, {
  alias: { typebox: piRequire.resolve("typebox") },
});

const factory = (await jiti.import(join(HERE, "index.ts"))).default;

// ---- mock ExtensionAPI ----
const tools = [];
const handlers = {};
factory({
  registerTool: (def) => tools.push(def),
  on: (event, handler) => (handlers[event] = handler),
});

// 1. exactly one tool, named forth
assert.equal(tools.length, 1, "must register exactly one tool");
assert.equal(tools[0].name, "forth", "tool must be named forth");
console.log("PASS 1: exactly one tool registered, named forth");

const cwd = mkdtempSync(join(tmpdir(), "forth-tool-check-"));
const ctx = { cwd };
const call = async (code) => tools[0].execute("tc", { code }, undefined, undefined, ctx);
const text = (r) => r.content[0].text;

try {
  // 2. persistence across calls
  const r1 = await call(": sq dup * ;");
  assert.ok(r1.details.newWords.includes("sq"), "call 1 must report new word sq");
  const r2 = await call("3 sq");
  assert.deepEqual(r2.details.stack, [9], "call 2 must see sq from call 1 (persistent VM)");
  assert.equal(r2.details.ok, true);
  console.log("PASS 2: persistence — sq defined in call 1, stack [9] in call 2");

  // 3. sandbox
  const esc = await call('s" ../outside.txt" fread');
  assert.equal(esc.details.ok, false, "relative escape must fail");
  assert.match(esc.details.error, /escapes cwd sandbox/, "escape must be named");
  const abs = await call('s" /etc/passwd" fread');
  assert.equal(abs.details.ok, false, "absolute path must fail");
  assert.match(abs.details.error, /absolute path rejected/);
  // VM survived the rejections and kept state
  const alive = await call("2 sq");
  assert.deepEqual(alive.details.stack, [9, 4], "VM must survive sandbox rejections");
  console.log("PASS 3: sandbox — ../ and absolute paths rejected, VM intact");

  // 4. fwrite / fread / load roundtrip
  await call('s" : cube dup dup * * ;" s" lib.fs" fwrite');
  assert.equal(readFileSync(join(cwd, "lib.fs"), "utf8"), ": cube dup dup * * ;");
  const r4 = await call('s" lib.fs" load  3 cube');
  assert.equal(r4.details.stack.at(-1), 27, "loaded cube must run");
  assert.ok(r4.details.newWords.includes("cube"));
  const r4b = await call('s" lib.fs" fread h.');
  assert.match(text(r4b), /: cube dup dup \* \* ;/, "fread+h. must echo file");
  console.log("PASS 4: fwrite/fread/load roundtrip in cwd");

  // 5. words / see
  const r5 = await call("words");
  assert.match(text(r5), /user: cube sq/, "words must list user definitions");
  assert.match(text(r5), /builtin: .*fwrite/, "words must list builtins");
  const r6 = await call("see sq");
  assert.match(text(r6), /: sq dup \* ;/, "see must show source");
  console.log("PASS 5: words/see introspection");

  // 6. error keeps VM alive
  const bad = await call("nosuchword");
  assert.equal(bad.details.ok, false);
  assert.match(bad.details.error, /unknown word/);
  const still = await call("1 2 +");
  assert.equal(still.details.stack.at(-1), 3, "VM must survive eval errors");
  console.log("PASS 6: eval error reported, VM survives");
} finally {
  await handlers.session_shutdown?.({}, ctx);
  rmSync(cwd, { recursive: true, force: true });
}

console.log("ALL CHECKS PASS");
