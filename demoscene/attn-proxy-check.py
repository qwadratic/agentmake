#!/usr/bin/env python3
"""Reference check for ATTN-SPEC weight heuristic (attn-proxy/1). stdlib only."""
import math, re

CATS = {
    **{w: "def" for w in (":", ";", "variable", "constant")},
    **{w: "ctl" for w in ("if", "else", "then", "begin", "until", "do", "loop", "i")},
    **{w: "stk" for w in ("dup", "drop", "swap", "over", "rot")},
    **{w: "prim" for w in ("+", "-", "*", "/", "mod", "negate", "=", "<", ">",
                            "@", "!", ".", "emit", "cr", "token", "h.", "h=", "h>n", '."', 's"')},
}
# (consumed, produced) per word -> stack activity
ARITY = {"dup": (1, 2), "drop": (1, 0), "swap": (2, 2), "over": (2, 3), "rot": (3, 3),
         "+": (2, 1), "-": (2, 1), "*": (2, 1), "/": (2, 1), "mod": (2, 1),
         "negate": (1, 1), "=": (2, 1), "<": (2, 1), ">": (2, 1),
         "@": (1, 1), "!": (2, 0), ".": (1, 0), "emit": (1, 0), "cr": (0, 0),
         "token": (0, 1), "h.": (1, 0), "h=": (2, 1), "h>n": (1, 2), "i": (0, 1)}
MAX_ACT = 6  # rot: 3+3
NUM = re.compile(r"^[+-]?\d+$")
JUNCTION = {"if": 0.8, "else": 0.8, "until": 0.8, "loop": 0.8, "begin": 0.4, "do": 0.4, "then": 0.4}

def cat(tok, defs):
    t = tok.lower()
    if t in CATS: return CATS[t]
    if NUM.match(t): return "lit"
    if t in defs: return "usr"
    return "usr"

def weights(tokens, defs, refcount, defline, lines):
    """tokens: [(text,line)] ; returns [(text, cat, w)]"""
    maxref = max(refcount.values() or [1])
    out = []
    depth = 0
    for text, line in tokens:
        t = text.lower(); c = cat(t, defs)
        if c == "com":
            out.append((text, c, 0.05)); continue
        w_ref = w_stack = w_edge = w_j = 0.0
        if t in defs and t in refcount:                    # def-site glow
            w_ref = math.log2(1 + refcount[t]) / math.log2(1 + maxref)
        if t in ARITY:
            cns, prd = ARITY[t]; w_stack = (cns + prd) / MAX_ACT
        if c == "usr" and t in defline:                    # use-site long-range edge
            d = abs(line - defline[t])
            w_edge = min(1.0, math.log(1 + d) / math.log(1 + lines))
        if t in JUNCTION:
            depth_adj = min(1.5, 1 + 0.15 * depth)
            w_j = JUNCTION[t] * depth_adj
        if t in ("if", "begin", "do"): depth += 1
        if t in ("then", "until", "loop"): depth = max(0, depth - 1)
        base = {"lit": 0.15, "def": 0.3}.get(c, 0.0)
        w = min(1.0, (base + w_ref + w_stack + w_edge + w_j) / 1.6)
        out.append((text, c, round(w, 3)))
    return out

# corpus fragment: stage1 compiler.fs `spaces` + a hot word `ind` used far away
src = [(":", 1), ("spaces", 1), ("begin", 2), ("dup", 2), ("0", 2), (">", 2),
       ("if", 2), ("32", 2), ("emit", 2), ("1", 2), ("-", 2), ("0", 2),
       ("else", 2), ("-1", 2), ("then", 2), ("until", 2), ("drop", 2), (";", 2),
       (":", 4), ("ind", 4), ("depth", 4), ("@", 4), ("spaces", 4), (";", 4),
       ("ind", 60), (".\"", 60)]
defs = {"spaces", "ind", "depth"}
refcount = {"spaces": 1, "ind": 22, "depth": 8}  # ind is the hot word in compiler.fs
defline = {"spaces": 1, "ind": 4, "depth": 1}
res = weights(src, defs, refcount, defline, lines=140)

byname = {}
for text, c, w in res:
    byname.setdefault(text.lower(), []).append((c, w))
    print(f"{text:8s} {c:5s} {w}")

# invariants the spec promises
w = lambda n, i=0: byname[n][i][1]
assert w("if") > w("then"), "branch junction outranks closer"
assert w("until") > w("begin"), "loop test outranks loop opener"
assert byname["ind"][0][1] > byname["spaces"][0][1], "hot def (22 refs) > cold def (1 ref)"
assert byname["ind"][1][1] > byname["ind"][0][1], "long-range use salient (distance boost)"
assert all(v <= 1.0 for vs in byname.values() for _, v in vs), "clamped"
assert w("dup") > w("0"), "stack activity > bare literal"
print("OK: all invariants hold")
