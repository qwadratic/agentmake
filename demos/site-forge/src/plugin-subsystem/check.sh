#!/bin/bash
# composite gate: done iff subtree review verdict PASS
cd "$(dirname "$0")" && grep -q '^VERDICT: PASS$' build/report.md
