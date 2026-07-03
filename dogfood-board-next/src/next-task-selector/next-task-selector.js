#!/usr/bin/env node
// next-task-selector: read board-reader JSON lines on stdin, pick first (top of column).
// Prints selected task as JSON {id,title,body} to stdout.
"use strict";

let input = "";
process.stdin.on("data", (d) => (input += d));
process.stdin.on("end", () => {
  const line = input.split(/\r?\n/).find((l) => l.trim());
  if (!line) {
    process.stderr.write("next-task-selector: todo column is empty, nothing to pick\n");
    process.exit(1);
  }
  let task;
  try {
    task = JSON.parse(line);
  } catch (e) {
    process.stderr.write("next-task-selector: invalid JSON input: " + e.message + "\n");
    process.exit(1);
  }
  process.stdout.write(JSON.stringify({ id: task.id, title: task.title, body: task.body || "" }) + "\n");
});
