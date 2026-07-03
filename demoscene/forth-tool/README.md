# forth-tool — pi extension: one tool, persistent Forth VM

Registers exactly **one** pi tool, `forth`, backed by the stage0 interpreter
from `demos/forth-forth` (imported via importlib — reused, not rewritten).

```
pi (LLM) ──tool call {code}──▶ index.ts ──NDJSON──▶ forth_server.py (python3, kept alive)
                                                        └─ CodingForth(stage0.Forth)
```

## Persistence

One `python3 forth_server.py` subprocess per session, spawned lazily on the
first `forth` call, killed on `session_shutdown`. Stack, defined words, and
variables persist across tool calls:

```
call 1: : sq dup * ;        →  new words: sq
call 2: 7 sq                →  stack <1>: 49
```

Each call returns: printed output, data stack (+depth), defined-words delta,
error (VM survives eval errors).

## Coding adaptations (as forth words)

| word | stack effect | does |
|---|---|---|
| `load` | `( h-path -- )` | interpret forth file |
| `fread` | `( h-path -- h-contents )` | read file → string handle |
| `fwrite` | `( h-contents h-path -- )` | write string handle to file |
| `words` | `( -- )` | list user-defined + builtin words |
| `see` | `( "name" -- )` | show a word's definition source |

**Sandbox (trust boundary):** all file paths resolve under the session cwd
realpath. Absolute paths, `..` escapes, and symlink escapes are rejected
server-side; the VM survives the rejection.

Guardrails: 15s eval timeout and abort-signal handling (kill + respawn, state
loss reported), 48KB LLM-facing output cap, serialized tool calls.

## Run

```sh
pi -e demoscene/forth-tool/index.ts          # then: "use the forth tool ..."
node demoscene/forth-tool/check.mjs          # deterministic self-checks, no LLM
```

## Self-check results

- `node check.mjs` — ALL CHECKS PASS (1: exactly one tool named forth,
  2: persistence across calls, 3: sandbox rejections + VM intact,
  4: fwrite/fread/load roundtrip, 5: words/see, 6: errors don't kill VM)
- `pi -p --no-builtin-tools --no-extensions -e index.ts "list tools"` → `forth`
- `pi -p --no-builtin-tools -e index.ts` define `sq` then `7 sq` → `stack <1>: 49`
