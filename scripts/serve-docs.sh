#!/usr/bin/env bash
# Serve docs/ locally (same tree GitHub Pages publishes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8888}"
cd "$ROOT/docs"
echo "Docs preview: http://127.0.0.1:${PORT}/"
echo "Stop with Ctrl-C."
exec python3 -m http.server "$PORT" --bind 127.0.0.1
