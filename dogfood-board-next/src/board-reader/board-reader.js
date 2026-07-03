#!/usr/bin/env node
// board-reader: locate backlog board markdown in repo, print 'todo' column tasks as JSON lines.
// Board format: markdown with `## <column>` headings; tasks are `- title` items,
// following indented lines belong to the task body.
// Usage: board-reader.js [boardFile] [--root DIR]
"use strict";
const fs = require("fs");
const path = require("path");

const CANDIDATES = [
  "board.md", "BOARD.md", "backlog.md", "BACKLOG.md",
  path.join(".board", "board.md"), path.join("backlog", "board.md"),
];

function findBoard(root) {
  for (const c of CANDIDATES) {
    const p = path.join(root, c);
    if (fs.existsSync(p) && fs.statSync(p).isFile()) return p;
  }
  return null;
}

function parseBoard(text) {
  const columns = {}; // name -> [{id,title,body}]
  let col = null, task = null, idx = 0;
  for (const line of text.split(/\r?\n/)) {
    const h = line.match(/^##\s+(.+?)\s*$/);
    if (h) { col = h[1].trim().toLowerCase(); columns[col] = columns[col] || []; task = null; continue; }
    if (!col) continue;
    const t = line.match(/^- (?:\[[ xX]\]\s*)?(.+?)\s*$/);
    if (t) {
      idx += 1;
      task = { id: `task-${idx}`, title: t[1], body: "" };
      columns[col].push(task);
      continue;
    }
    if (task && /^\s+\S/.test(line)) {
      task.body += (task.body ? "\n" : "") + line.trim();
    } else if (line.trim() === "") {
      // blank line ends nothing; keep task open (allow spaced body? MVP: close task)
      task = null;
    }
  }
  return columns;
}

function main() {
  const args = process.argv.slice(2);
  let root = process.cwd(), file = null;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--root") root = args[++i];
    else file = args[i];
  }
  if (!file) file = findBoard(root);
  if (!file || !fs.existsSync(file)) {
    process.stderr.write("board-reader: no board file found (looked for: " + CANDIDATES.join(", ") + ")\n");
    process.exit(1);
  }
  const columns = parseBoard(fs.readFileSync(file, "utf8"));
  for (const task of columns["todo"] || []) {
    process.stdout.write(JSON.stringify(task) + "\n");
  }
}

main();
