#!/usr/bin/env bash
# eval.sh — deterministic screenshot golden gate for the built app.
# serve (ES modules need http) -> snap eval harness -> evalshot vs golden.
set -euo pipefail
cd "$(dirname "$0")"
PORT=${PORT:-8794}
python3 -m http.server "$PORT" --directory . >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
sleep 0.3
mkdir -p shots
../../evals/snap "http://localhost:$PORT/eval.html" shots/eval.png 480 640
../../evals/evalshot shots/eval.png golden/eval.png
