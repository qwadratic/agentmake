#!/usr/bin/env python3
"""attn golden-text eval + honesty assertions. stdlib only.

Checks:
  1. `attn view fixtures/tiny.fs --no-color --tags` == fixtures/tiny.golden.txt
  2. sidecar token/edge matrix == fixtures/tiny.golden.matrix (category/weight
     matrix golden); sidecar disclaimer exact
  3. color-mode ANSI output, stripped, carries every fixture token + legend
  4. honesty legend string present in EVERY mode output: view color, view
     no-color, timeline (one per frame), and both sidecars
  5. spec invariants (§3) hold on the fixture
  6. attn-proxy-check.py (executable weight definition) still passes

Run: python3 demoscene/attn-selfcheck.py
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ATTN = os.path.join(HERE, "attn")
FIX = os.path.join(HERE, "fixtures", "tiny.fs")
GOLD_TXT = os.path.join(HERE, "fixtures", "tiny.golden.txt")
GOLD_MTX = os.path.join(HERE, "fixtures", "tiny.golden.matrix")
TRACE = os.path.join(HERE, "session-trace.jsonl")
DISCLAIMER = "interpretive proxy — not model internals"
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")


def run(*args, env_extra=None):
    env = dict(os.environ)
    env.pop("COLORTERM", None)  # deterministic 256-color SGR in check 3
    if env_extra:
        env.update(env_extra)
    r = subprocess.run([sys.executable, ATTN, *args],
                       capture_output=True, text=True, env=env)
    assert r.returncode == 0, "attn %s failed: %s" % (args, r.stderr)
    return r.stdout


def main():
    tmp = tempfile.mkdtemp(prefix="attn-check-")

    # 1. golden render (no-color --tags IS the category/weight matrix as text)
    out_nc = run("view", FIX, "--no-color", "--tags")
    gold = open(GOLD_TXT).read()
    assert out_nc == gold, "no-color render drifted from tiny.golden.txt"

    # 2. sidecar matrix golden + disclaimer
    sj = os.path.join(tmp, "tiny.attn.json")
    run("view", FIX, "--json", sj)
    doc = json.load(open(sj))
    assert doc["disclaimer"] == DISCLAIMER, "sidecar disclaimer missing/altered"
    assert doc["heuristic"] == "attn-proxy/1"
    mtx = []
    for t in doc["tokens"]:
        mtx.append("%d\t%d\t%d\t%s\t%s\t%.3f\t%d\t%s" % (
            t["i"], t["line"], t["col"], t["text"], t["cat"], t["w"],
            t["depth"], t["junction"] or "-"))
    for e in doc["edges"]:
        mtx.append("edge\t%s\t%d\t%d\t%.3f" % (e["type"], e["from"], e["to"], e["w"]))
    gold_mtx = open(GOLD_MTX).read().rstrip("\n").split("\n")
    assert mtx == gold_mtx, "category/weight matrix drifted from tiny.golden.matrix"

    # 3. color mode: stripped ANSI keeps all tokens + legend
    out_c = run("view", FIX)
    assert "\x1b[" in out_c, "color mode emitted no SGR"
    stripped = ANSI.sub("", out_c)
    for word in ("spaces", "ind", "greet", "frobnicate", "until", "42"):
        assert word in stripped, "token lost in color render: " + word
    assert DISCLAIMER in stripped

    # 4. honesty legend in EVERY mode output
    assert DISCLAIMER in out_nc, "disclaimer missing: view --no-color"
    assert DISCLAIMER in out_c, "disclaimer missing: view color"
    sj2 = os.path.join(tmp, "sess.attn.json")
    out_t = run("timeline", TRACE, "--no-color", "--json", sj2)
    nframes = out_t.count("--ATTN-FRAME")
    assert nframes > 0, "timeline produced no frames"
    assert out_t.count(DISCLAIMER) == nframes, \
        "every timeline frame must carry the disclaimer legend"
    sdoc = json.load(open(sj2))
    assert sdoc["disclaimer"] == DISCLAIMER, "session sidecar disclaimer missing"
    assert sdoc["mode"] == "session" and len(sdoc["frames"]) == nframes

    # 5. spec §3 invariants on the fixture
    w = {}
    for t in doc["tokens"]:
        w.setdefault(t["text"].lower(), []).append(t["w"])
    assert w["if"][0] > w["then"][0], "branch junction outranks closer"
    assert w["until"][0] > w["begin"][0], "loop test outranks loop opener"
    assert w["ind"][1] > w["ind"][0], "long-range use > its own def site"
    assert w["dup"][0] > w["0"][0], "stack op > bare literal"
    assert w["frobnicate"][0] == 0.0, "unknown word weight forced 0"
    assert all(v <= 1.0 for vs in w.values() for v in vs), "clamped"

    # 6. executable weight definition unchanged
    r = subprocess.run([sys.executable, os.path.join(HERE, "attn-proxy-check.py")],
                       capture_output=True, text=True)
    assert r.returncode == 0 and "OK: all invariants hold" in r.stdout, \
        "attn-proxy-check.py regressed"

    print("OK: golden matrix match, invariants hold, disclaimer in every mode")


if __name__ == "__main__":
    main()
