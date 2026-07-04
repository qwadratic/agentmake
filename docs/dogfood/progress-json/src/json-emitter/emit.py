#!/usr/bin/env python3
"""json-emitter: collector output -> schema-conformant JSON on stdout.

Usage: emit.py [build_dir]
"""
import json
import os
import sys
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "progress-data-collector"))
from collect import collect  # noqa: E402

VERSION = "1.0.0"


def emit(raw):
    """Map raw collector dict to schema shape (progress.schema.json)."""
    done, total = raw["done"], raw["total"]
    return {
        "version": VERSION,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "totals": {"done": done, "total": total},
        "percent": round(done * 100 / total, 1) if total else 0,
        # ponytail: collector has one flat artifact list -> single section.
        # Upgrade path: group items by dirname when make progress grows sections.
        "sections": [{"name": "artifacts", "done": done, "total": total}],
    }


if __name__ == "__main__":
    raw = collect(sys.argv[1] if len(sys.argv) > 1 else "build")
    print(json.dumps(emit(raw)))
