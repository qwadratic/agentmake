#!/usr/bin/env node
// goal-md-generator: read selected task JSON {id,title,body} on stdin,
// write goal.md with sections the engine expects: Goal, Constraints, Done criteria.
// Body lines after an "Acceptance:" marker become done criteria; rest stays in goal statement.
// Usage: goal-md-generator.js [outputPath]   (default: ./goal.md)
"use strict";
const fs = require("fs");

let input = "";
process.stdin.on("data", (d) => (input += d));
process.stdin.on("end", () => {
  let task;
  try {
    task = JSON.parse(input.split(/\r?\n/).find((l) => l.trim()) || "");
  } catch (e) {
    process.stderr.write("goal-md-generator: invalid task JSON: " + e.message + "\n");
    process.exit(1);
  }
  if (!task.title) {
    process.stderr.write("goal-md-generator: task has no title\n");
    process.exit(1);
  }

  const body = task.body || "";
  let desc = body, acceptance = "";
  const m = body.match(/^\s*Acceptance:\s*/im);
  if (m) {
    desc = body.slice(0, m.index).trim();
    acceptance = body.slice(m.index + m[0].length).trim();
  }

  const md = [
    "# Goal",
    "",
    task.title,
    ...(desc ? ["", desc] : []),
    "",
    "## Constraints",
    "",
    "- Keep changes minimal; no new dependencies unless the task says otherwise.",
    "",
    "## Done criteria",
    "",
    acceptance || "- Task \"" + task.title + "\" is implemented and verified.",
    "",
  ].join("\n");

  const out = process.argv[2] || "goal.md";
  fs.writeFileSync(out, md);
  process.stderr.write("goal-md-generator: wrote " + out + "\n");
});
