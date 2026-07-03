#!/usr/bin/env python3
"""forth-tool server: persistent Forth VM over NDJSON stdin/stdout.

Reuses the stage0 interpreter from demos/forth-forth (imported via importlib,
not rewritten). One VM per process; the pi extension keeps this process alive
for the whole session, so stack / words / variables persist across tool calls.

Protocol: one JSON object per line on stdin  {"code": "<forth source>"}
          one JSON object per line on stdout {"ok", "output", "stack",
                                              "depth", "new_words", "error"}

Coding-agent words added on top of stage0:
  load    ( h-path -- )             interpret forth file (sandboxed to cwd)
  fread   ( h-path -- h-contents )  read file into string handle
  fwrite  ( h-contents h-path -- )  write string handle to file
  words   ( -- )                    print user-defined + builtin word names
  see     ( "name" -- )             print word definition source

Sandbox (trust boundary): all paths resolve under the launch cwd realpath.
Absolute paths and any escape (.., symlinks) are rejected.
"""
import importlib.util
import io
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STAGE0 = os.path.normpath(
    os.path.join(HERE, "..", "..", "demos", "forth-forth", "src", "stage0", "stage0.py")
)

spec = importlib.util.spec_from_file_location("stage0", STAGE0)
stage0 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stage0)

BUILTINS = [
    "+", "-", "*", "/", "mod", "negate", "=", "<", ">",
    "dup", "drop", "swap", "over", "rot", ".", "emit", "cr", "i", "@", "!",
    "token", "h.", "h=", "h>n",
    ":", ";", "variable", "if", "else", "then", "begin", "until", "do", "loop",
    '."', 's"', "\\", "(",
    "load", "fread", "fwrite", "words", "see",
]

MAX_OUTPUT = 100_000   # server-side cap; extension truncates further for LLM
MAX_STACK = 64         # serialize at most this many top-of-stack cells


class ForthError(Exception):
    pass


class CodingForth(stage0.Forth):
    def __init__(self, cwd):
        super().__init__("", None)
        self.sandbox = os.path.realpath(cwd)
        self.sources = {}  # name -> ": name ... ;" source text for `see`

    # ---- sandbox (trust boundary: no path escape) ----
    def safe_path(self, handle):
        try:
            rel = self.strings[handle]
        except (IndexError, TypeError):
            raise ForthError("forth: bad string handle for path")
        if not rel:
            raise ForthError("forth: empty path")
        if os.path.isabs(rel):
            raise ForthError("forth: absolute path rejected (sandboxed to cwd): " + rel)
        p = os.path.realpath(os.path.join(self.sandbox, rel))
        if p != self.sandbox and not p.startswith(self.sandbox + os.sep):
            raise ForthError("forth: path escapes cwd sandbox: " + rel)
        return p

    # ---- reentrant interpret (used by eval loop and `load`) ----
    def interpret_source(self, src):
        saved = (self.src, self.pos)
        self.src, self.pos = src, 0
        try:
            self.interpret()
        finally:
            self.src, self.pos = saved

    # ---- record definition source for `see` ----
    def compile_def(self):
        start = self.pos
        super().compile_def()
        text = self.src[start:self.pos].strip()
        parts = text.split()
        if parts:
            self.sources[parts[0].lower()] = ": " + text

    # ---- coding-agent words (user definitions shadow these, like stage0) ----
    def exec_word(self, t):
        if t not in self.words:
            if t == "load":
                path = self.safe_path(self.stack.pop())
                with open(path) as f:
                    self.interpret_source(f.read())
                return
            if t == "fread":
                path = self.safe_path(self.stack.pop())
                with open(path) as f:
                    self.stack.append(self.intern(f.read()))
                return
            if t == "fwrite":
                path = self.safe_path(self.stack.pop())
                try:
                    data = self.strings[self.stack.pop()]
                except (IndexError, TypeError):
                    raise ForthError("forth: bad string handle for fwrite contents")
                with open(path, "w") as f:
                    f.write(data)
                return
            if t == "words":
                names = sorted(self.words)
                self.out.write("user: " + (" ".join(names) if names else "(none)") + "\n")
                self.out.write("builtin: " + " ".join(BUILTINS) + "\n")
                return
            if t == "see":
                name = self.next_token()
                if name is None:
                    raise ForthError("forth: see: missing word name")
                name = name.lower()
                if name in self.sources:
                    self.out.write(self.sources[name] + "\n")
                elif name in self.words:
                    self.out.write(name + ": " + repr(self.words[name]) + "\n")
                else:
                    raise ForthError("forth: see: unknown word: " + name)
                return
        super().exec_word(t)


def main():
    vm = CodingForth(os.getcwd())
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            code = json.loads(line).get("code", "")
        except (ValueError, AttributeError):
            sys.stdout.write(json.dumps({
                "ok": False, "output": "", "stack": [], "depth": 0,
                "new_words": [], "error": "forth-server: bad request json",
            }) + "\n")
            sys.stdout.flush()
            continue

        before = set(vm.words)
        buf = io.StringIO()
        vm.out = buf
        err = None
        try:
            vm.interpret_source(code)
        except ForthError as e:
            err = str(e)
        except SystemExit as e:
            err = str(e)
        except IndexError:
            err = "forth: stack underflow (or bad handle)"
        except RecursionError:
            err = "forth: recursion limit exceeded"
        except Exception as e:  # keep VM alive on any eval error
            err = "forth: %s: %s" % (type(e).__name__, e)

        output = buf.getvalue()
        if len(output) > MAX_OUTPUT:
            output = output[:MAX_OUTPUT] + "\n[forth: output capped at %d bytes]" % MAX_OUTPUT

        resp = {
            "ok": err is None,
            "output": output,
            "stack": list(vm.stack[-MAX_STACK:]),
            "depth": len(vm.stack),
            "new_words": [w for w in vm.words if w not in before],
            "error": err,
        }
        sys.stdout.write(json.dumps(resp) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
