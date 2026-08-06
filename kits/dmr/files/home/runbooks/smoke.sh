#!/usr/bin/env bash
# Flagship end-to-end check for the sbx-kits-openhands kit.
#
# Runs the OpenHands CLI headlessly against a tiny task and prints the result.
# It exercises the installed `openhands` binary, the LLM_* env the kit sets, the
# proxy-injected key (cloud providers), and a live round-trip to the model. If
# you only run one thing to confirm the kit works, run this.
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

# --override-with-envs is required — OpenHands ignores LLM_* env vars otherwise.
# --headless needs a task (-t); --exit-without-confirmation keeps it non-interactive.
exec openhands --headless --override-with-envs --exit-without-confirmation -t "${TASK}"
