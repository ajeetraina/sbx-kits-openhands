#!/usr/bin/env bash
# Launch OpenHands Agent Canvas — the browser UI + backend server that replaced
# the deprecated interactive CLI.
#
# This starts the `agent-canvas` server (installed via `npm i -g
# @openhands/agent-canvas`) on port 8000. The kit's LLM_* environment
# (LLM_MODEL, placeholder LLM_API_KEY, and LLM_BASE_URL for the DMR variant) is
# picked up by the agent-server on startup, and for cloud providers the sbx
# proxy injects the real key on the wire — so the model is preconfigured; you
# should not need to paste a key into Settings > LLM.
#
# The server is long-running (Ctrl-C to stop). Port 8000 must be forwarded to
# the host: start the sandbox with `sbx run -p 8000 …` (or add a forward), then
# open http://localhost:8000 in your browser.
#
# Usage (inside the sandbox):
#     bash ~/runbooks/canvas.sh
#     PORT=3000 bash ~/runbooks/canvas.sh          # serve on a different port
set -euo pipefail

PORT="${PORT:-8000}"

if ! command -v agent-canvas >/dev/null 2>&1; then
  echo "agent-canvas is not on PATH. Expected it from 'npm i -g @openhands/agent-canvas'." >&2
  echo "Check the Node.js + Agent Canvas install steps ran (node --version should be >= 22.12)." >&2
  exit 1
fi

echo "agent-canvas: $(command -v agent-canvas)"
echo "node:         $(command -v node) ($(node --version 2>/dev/null || echo '?'))"
echo "LLM_MODEL:    ${LLM_MODEL:-(unset)}"
echo "LLM_BASE_URL: ${LLM_BASE_URL:-(default)}"
echo
echo "Starting Agent Canvas on port ${PORT}."
echo "Forward it with 'sbx run -p ${PORT} …' and open http://localhost:${PORT}"
echo "Confirm the default local backend shows as 'connected', then start a conversation."
echo "Press Ctrl-C to stop."
echo

exec agent-canvas --port "${PORT}"
