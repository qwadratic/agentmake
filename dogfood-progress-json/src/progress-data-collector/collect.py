#!/usr/bin/env python3
"""progress-data-collector: scan repo state same as `make progress`.

`make progress` checks existence of ARTIFACTS:
  $(B)/effort.json $(B)/plan.json $(B)/<component>.done... $(B)/report.md
Component list comes from plan.json. This module rebuilds that artifact
list and gathers raw done/total counts into a plain dict.
"""
import json
import os
import sys


def collect(build_dir="build"):
    """Return raw counts dict. Mirrors ARTIFACTS ordering in engine/build.mk."""
    plan_path = os.path.join(build_dir, "plan.json")
    components = []
    if os.path.isfile(plan_path):
        with open(plan_path) as f:
            plan = json.load(f)
        components = [c["id"] for c in plan.get("components", [])]

    artifacts = [os.path.join(build_dir, "effort.json"), plan_path]
    artifacts += [os.path.join(build_dir, f"{c}.done") for c in components]
    artifacts += [os.path.join(build_dir, "report.md")]

    items = [{"path": p, "done": os.path.isfile(p)} for p in artifacts]
    done = sum(1 for i in items if i["done"])
    total = len(items)
    return {
        "items": items,
        "done": done,
        "total": total,
        "percent": (done * 100 // total) if total else 0,
    }


if __name__ == "__main__":
    print(json.dumps(collect(sys.argv[1] if len(sys.argv) > 1 else "build")))
