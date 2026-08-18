#!/usr/bin/env bash
# Launch OpenHands Agent Canvas — the browser UI + backend server that replaced
# the deprecated interactive CLI — and preconfigure its LLM.
#
# Agent Canvas does NOT read the LLM_* environment variables (its own help says
# "LLM settings are configured through the web UI settings page"). So this script
# starts the `agent-canvas` server (installed via `npm i -g
# @openhands/agent-canvas`) on port 8000, waits for it to come up, then seeds the
# model + key into its settings via the local backend API — using LLM_MODEL /
# LLM_API_KEY (and LLM_BASE_URL for the DMR variant) that the kit set. For cloud
# providers LLM_API_KEY is only a placeholder; the sbx proxy swaps in the real
# key on the wire to the provider host, so no real key ever enters the sandbox.
#
# The server is long-running (Ctrl-C to stop). Port 8000 must be forwarded to
# the host: start the sandbox with `sbx run -p 8000 …` (or add a forward), then
# open http://localhost:8000 in your browser. The model will already be set — no
# need to paste anything into Settings > LLM.
#
# Usage (inside the sandbox):
#     bash ~/runbooks/canvas.sh
#     PORT=3000 bash ~/runbooks/canvas.sh          # serve on a different port
set -euo pipefail

PORT="${PORT:-8000}"
BASE="http://localhost:${PORT}"

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

# Start the server in the background so we can seed settings, then hand control
# back to it. Stop it (and its children) on Ctrl-C.
LOG="${HOME}/.openhands/agent-canvas/launch.log"
mkdir -p "$(dirname "$LOG")"
echo "Starting Agent Canvas on port ${PORT} (log: ${LOG}) …"
agent-canvas --port "${PORT}" >"$LOG" 2>&1 &
SRV=$!
cleanup() { echo; echo "Stopping Agent Canvas …"; kill "$SRV" 2>/dev/null || true; pkill -P "$SRV" 2>/dev/null || true; }
trap cleanup INT TERM EXIT

# Wait for the local backend to report healthy (first run pulls the agent-server
# via uvx, so allow generous time).
echo -n "Waiting for the backend to become healthy"
healthy=0
for _ in $(seq 1 60); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "${BASE}/health" 2>/dev/null)" = "200" ]; then
    healthy=1; break
  fi
  echo -n "."; sleep 2
done
echo
if [ "$healthy" != "1" ]; then
  echo "WARN: backend did not report healthy in time; skipping model seeding." >&2
  echo "      Open ${BASE} and configure the model under Settings > LLM manually." >&2
else
  # Seed the LLM settings (best-effort). Agent Canvas auto-generates a backend
  # API key at ~/.openhands/agent-canvas/api-key.txt; the settings API takes a
  # partial diff via PATCH /api/settings.
  KEY="$(cat "${HOME}/.openhands/agent-canvas/api-key.txt" 2>/dev/null | tr -d '\r\n')"
  llm="{\"model\":\"${LLM_MODEL:-}\",\"api_key\":\"${LLM_API_KEY:-}\""
  [ -n "${LLM_BASE_URL:-}" ] && llm="${llm},\"base_url\":\"${LLM_BASE_URL}\""
  llm="${llm}}"
  body="{\"agent_settings_diff\":{\"llm\":${llm}}}"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -X PATCH "${BASE}/api/settings" \
    -H "X-Session-API-Key: ${KEY}" -H "Content-Type: application/json" -d "${body}" 2>/dev/null || true)"
  if [ "$code" = "200" ] || [ "$code" = "204" ]; then
    echo "Seeded model '${LLM_MODEL}' into Agent Canvas settings."
  else
    echo "WARN: could not seed the model automatically (HTTP ${code:-?})." >&2
    echo "      Set the model to '${LLM_MODEL}' under Settings > LLM in the UI;" >&2
    echo "      any placeholder API key works — the sbx proxy injects the real one." >&2
  fi
fi

echo
echo "Agent Canvas is running at ${BASE}"
echo "Forward the port with 'sbx run -p ${PORT} …' and open http://localhost:${PORT}"
echo "Confirm the default local backend shows as 'connected', then start a conversation."
echo "Press Ctrl-C to stop."
wait "$SRV"
