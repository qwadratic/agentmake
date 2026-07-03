/**
 * forth-tool — pi extension registering exactly ONE tool: `forth`.
 *
 * Persistent Forth VM per session: a python3 subprocess running
 * forth_server.py (which reuses the stage0 interpreter from
 * demos/forth-forth) is spawned lazily on first call and kept alive for the
 * whole session, so stack / words / variables persist across tool calls.
 *
 * Coding adaptations live in the VM as forth words: load / fread / fwrite
 * (sandboxed to cwd — enforced server-side), words / see introspection.
 */
import { spawn, type ChildProcess } from "node:child_process";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER = join(HERE, "forth_server.py");
const EVAL_TIMEOUT_MS = 15_000;
const MAX_TEXT = 48_000; // LLM-facing output cap

interface ForthResponse {
	ok: boolean;
	output: string;
	stack: number[];
	depth: number;
	new_words: string[];
	error: string | null;
}

const DESCRIPTION = `Evaluate Forth code in a persistent per-session VM (stage0 dialect from demos/forth-forth). Stack, defined words, and variables persist across calls. Returns printed output, the data stack, and newly defined words.

Dialect: integer data stack; \`: name ... ;\` definitions; if/else/then, begin/until, do/loop/i work ONLY inside definitions; \`variable x\`, \`x @\`, \`x !\`; \`." text"\` prints, \`s" text"\` pushes a string handle (print with \`h.\`).

Coding words (file paths sandboxed to cwd, no absolute paths or escapes):
  s" path" load               interpret a forth source file
  s" path" fread              read file -> string handle
  s" text" s" path" fwrite    write string handle to file
  words                       list user-defined + builtin words
  see name                    show a word's definition

Output truncated to ${MAX_TEXT} bytes. Evaluation aborts (VM restart, state lost) after ${EVAL_TIMEOUT_MS / 1000}s.`;

export default function (pi: ExtensionAPI) {
	let proc: ChildProcess | null = null;
	let pending: ((line: string) => void) | null = null;
	let stderrTail = "";
	let queue: Promise<unknown> = Promise.resolve(); // serialize tool calls

	function killVM(): void {
		if (proc) {
			proc.kill();
			proc = null;
		}
		pending = null;
	}

	function ensureVM(cwd: string): ChildProcess {
		if (proc && proc.exitCode === null && !proc.killed) return proc;
		const p = spawn("python3", [SERVER], { cwd, stdio: ["pipe", "pipe", "pipe"] });
		createInterface({ input: p.stdout! }).on("line", (line) => pending?.(line));
		p.stderr!.on("data", (chunk: Buffer) => {
			stderrTail = (stderrTail + chunk.toString()).slice(-2048);
		});
		p.on("exit", () => {
			if (proc === p) proc = null;
			pending?.(JSON.stringify({
				ok: false, output: "", stack: [], depth: 0, new_words: [],
				error: `forth: VM process died; state lost. stderr: ${stderrTail.trim() || "(empty)"}`,
			} satisfies ForthResponse));
		});
		proc = p;
		return p;
	}

	function evalOnce(code: string, cwd: string, signal?: AbortSignal): Promise<ForthResponse> {
		return new Promise((resolve) => {
			const p = ensureVM(cwd);
			const fail = (error: string): ForthResponse => ({
				ok: false, output: "", stack: [], depth: 0, new_words: [], error,
			});
			const finish = (r: ForthResponse) => {
				clearTimeout(timer);
				signal?.removeEventListener("abort", onAbort);
				pending = null;
				resolve(r);
			};
			const timer = setTimeout(() => {
				killVM();
				finish(fail(`forth: evaluation timed out after ${EVAL_TIMEOUT_MS}ms; VM restarted, session state lost`));
			}, EVAL_TIMEOUT_MS);
			const onAbort = () => {
				killVM();
				finish(fail("forth: evaluation aborted; VM restarted, session state lost"));
			};
			signal?.addEventListener("abort", onAbort, { once: true });
			pending = (line) => {
				try {
					finish(JSON.parse(line) as ForthResponse);
				} catch {
					finish(fail(`forth: bad response from VM: ${line.slice(0, 200)}`));
				}
			};
			try {
				p.stdin!.write(JSON.stringify({ code }) + "\n");
			} catch (err) {
				killVM();
				finish(fail(`forth: failed to reach VM: ${String(err)}`));
			}
		});
	}

	function formatResult(r: ForthResponse): string {
		const lines: string[] = [];
		if (r.error) lines.push(`error: ${r.error}`);
		if (r.output) {
			let out = r.output;
			if (out.length > MAX_TEXT) out = out.slice(0, MAX_TEXT) + `\n[output truncated at ${MAX_TEXT} bytes]`;
			lines.push(`output:\n${out}`);
		}
		const cells = r.stack.join(" ");
		const hidden = r.depth - r.stack.length;
		lines.push(`stack <${r.depth}>:${r.depth ? " " : ""}${hidden > 0 ? `... ${cells}` : cells}`);
		if (r.new_words.length) lines.push(`new words: ${r.new_words.join(" ")}`);
		return lines.join("\n");
	}

	pi.registerTool({
		name: "forth",
		label: "Forth",
		description: DESCRIPTION,
		promptSnippet: "Evaluate Forth code in a persistent per-session VM (stack/words survive across calls)",
		parameters: Type.Object({
			code: Type.String({ description: "Forth source code to evaluate in the session VM" }),
		}),

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const run = queue.then(() => evalOnce(params.code, ctx.cwd, signal));
			queue = run.catch(() => undefined);
			const r = await run;
			return {
				content: [{ type: "text", text: formatResult(r) }],
				details: {
					ok: r.ok,
					stack: r.stack,
					depth: r.depth,
					newWords: r.new_words,
					error: r.error,
				},
			};
		},
	});

	pi.on("session_shutdown", async () => {
		killVM();
	});
}
