#!/usr/bin/env bash
# Flagship end-to-end check for the sbx-kits-openhands kit.
#
# Runs the OpenHands CLI headlessly against a tiny task and prints the result.
# It exercises the installed `openhands` binary, the LLM_* env the kit sets, the
# proxy-injected key (cloud providers), and a live round-trip to the model. If
# you only run one thing to confirm the kit works, run this.
#
# Exit status is trustworthy: OpenHands headless prints "Goodbye!" and exits 0
# even when the LLM call fails (e.g. a 401 lands as a ConversationErrorEvent),
# so this script also scans the run's event log and exits non-zero if the run
# recorded an error.
#
# Usage (inside the sandbox):
#     bash ~/runbooks/smoke.sh
#     bash ~/runbooks/smoke.sh "refactor foo.py to add type hints"
set -euo pipefail

TASK="${*:-Create a file hello.txt containing the text 'hello from openhands' and then read it back.}"

if ! command -v openhands >/dev/null 2>&1; then
  echo "openhands is not on PATH. Expected it under ~/.local/bin (uv tool install)." >&2
  echo "Check the install step ran and that PATH includes /home/agent/.local/bin." >&2
  exit 1
fi

echo "openhands: $(command -v openhands)"
echo "LLM_MODEL: ${LLM_MODEL:-(unset)}"
echo "LLM_BASE_URL: ${LLM_BASE_URL:-(default)}"
echo "Task: ${TASK}"
echo

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

# --override-with-envs is required — OpenHands ignores LLM_* env vars otherwise.
# --headless needs a task (-t); --exit-without-confirmation keeps it non-interactive.
# Capture output while still streaming it, and don't let `set -e` abort before
# the post-run check below (we inspect the exit code explicitly).
set +e
openhands --headless --override-with-envs --exit-without-confirmation -t "${TASK}" 2>&1 | tee "$out"
rc=${PIPESTATUS[0]}
set -e

if [ "$rc" -ne 0 ]; then
  echo >&2
  echo "FAIL: openhands exited non-zero (${rc})." >&2
  exit "$rc"
fi

# OpenHands can record an error event yet still exit 0. Locate this run's event
# log (via the "Conversation ID:" line it prints, else the newest conversation)
# and fail if it contains a ConversationErrorEvent / AgentErrorEvent.
conv_root="${HOME}/.openhands/conversations"
conv_id="$(grep -oiE 'Conversation ID:[[:space:]]*[0-9a-f]+' "$out" | tail -1 | grep -oiE '[0-9a-f]{8,}' | tail -1 || true)"

events_dir=""
if [ -n "$conv_id" ] && [ -d "$conv_root/$conv_id/events" ]; then
  events_dir="$conv_root/$conv_id/events"
elif [ -d "$conv_root" ]; then
  latest="$(ls -td "$conv_root"/*/ 2>/dev/null | head -1 || true)"
  [ -n "$latest" ] && [ -d "${latest}events" ] && events_dir="${latest}events"
fi

if [ -z "$events_dir" ]; then
  echo >&2
  echo "WARN: could not find the OpenHands event log under $conv_root to verify success." >&2
  echo "The run exited 0; treating as success, but the round-trip was not confirmed." >&2
  exit 0
fi

err_file="$(grep -rlE '"kind"[[:space:]]*:[[:space:]]*"(ConversationErrorEvent|AgentErrorEvent)"' "$events_dir" 2>/dev/null | head -1 || true)"
if [ -n "$err_file" ]; then
  echo >&2
  echo "FAIL: OpenHands recorded an error event (the CLI itself still exited 0):" >&2
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$err_file" >&2 <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
code = d.get("code") or d.get("kind")
detail = d.get("detail") or d.get("message") or ""
print(f"  {code}: {detail}"[:1000])
PY
  else
    grep -oE '"(code|detail|message)"[[:space:]]*:[[:space:]]*"[^"]*"' "$err_file" | sed 's/^/  /' >&2 || cat "$err_file" >&2
  fi
  echo >&2
  echo "For a cloud provider this is usually an auth problem — confirm the secret" >&2
  echo "is stored for the right service (sbx secret ls)." >&2
  exit 1
fi

echo
echo "PASS: OpenHands completed the task with no error events."
