#!/usr/bin/env python3
"""parity.py <human_output_file> <json_output_file>

Asserts numbers in `make progress` human output match `make progress-json`.
Human summary line: [####    ] done/total (pct%)  -- pct is integer floor.
"""
import json
import re
import sys


def parse_human(text):
    m = re.search(r"\]\s*(\d+)/(\d+)\s*\((\d+)%\)", text)
    if not m:
        sys.exit("FAIL: cannot parse human summary line")
    done, total, pct = map(int, m.groups())
    checkmarks = text.count("\u2713")
    return done, total, pct, checkmarks


def main(human_path, json_path):
    with open(human_path) as f:
        done, total, pct, checkmarks = parse_human(f.read())
    with open(json_path) as f:
        j = json.load(f)

    jt = j["totals"]
    assert jt["done"] == done, f"done: json {jt['done']} != human {done}"
    assert jt["total"] == total, f"total: json {jt['total']} != human {total}"
    # human pct is integer floor of done*100/total; json is rounded to 0.1
    exact = done * 100 / total if total else 0
    assert int(exact) == pct, f"human pct {pct} != floor({exact})"
    assert abs(j["percent"] - exact) < 0.05, \
        f"json percent {j['percent']} != {exact}"
    assert checkmarks == done, f"checkmark count {checkmarks} != done {done}"
    sec = sum(s["done"] for s in j["sections"]), sum(s["total"] for s in j["sections"])
    assert sec == (done, total), f"sections sum {sec} != totals ({done},{total})"


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
    print("parity: all fields match")
