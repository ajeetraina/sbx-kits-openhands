# OpenAI

Wires OpenHands Agent Canvas (and the headless runner) to OpenAI through LiteLLM.
The API key is injected by the sbx proxy as an `Authorization: Bearer` header on
the wire, so it never enters the sandbox.

| | |
|---|---|
| Surfaces | `agent-canvas` (browser UI + backend, port 8000) + headless `openhands` |
| LLM | OpenAI (`api.openai.com`) |
| `LLM_MODEL` | `openai/gpt-4o` (swap for any OpenAI chat model you have access to) |
| Credential | OpenAI API key via `sbx secret set openai` |

## 1. Create an OpenAI API key

In the [OpenAI platform](https://platform.openai.com/api-keys) → create a secret
key. Copy the `sk-…` value.

## 2. Store the key as a secret

`openai` is a built-in sbx service, so a plain `sbx secret set` stores the key —
no host or env flags needed:

```bash
echo "$OPENAI_API_KEY" | sbx secret set openai   # or omit the pipe to be prompted; `sbx secret set openai --oauth` for OAuth
sbx secret ls   # confirm the secret is stored
```

The sandbox sees `LLM_API_KEY` as a placeholder; the proxy swaps in the real key
on the `Authorization: Bearer …` header for requests to `api.openai.com`.

## 3. (Optional) Choose the model

The kit defaults to `openai/gpt-4o`. To use another model, edit `LLM_MODEL` in a
local clone (`kits/openai/spec.yaml`) or `export LLM_MODEL=openai/<model>` inside
the sandbox before running.

## Run

```bash
echo "$OPENAI_API_KEY" | sbx secret set openai
sbx run -p 8000 --kit docker.io/ajeetraina777/sbx-openhands-kits:openai claude
# or from a local clone:
sbx run -p 8000 --kit ./kits/openai claude
```

`-p 8000` forwards Agent Canvas to the host.

## What the kit contains

- Installs Node.js 22 + OpenHands Agent Canvas (`npm i -g
  @openhands/agent-canvas`, bin: `agent-canvas`) and the headless OpenHands
  runner (`uv tool install openhands --python 3.12`, bin: `openhands`) onto
  `PATH`.
- `permissions.network.allow` includes `api.openai.com` plus the install hosts
  (pypi, GitHub, `nodejs.org`, `registry.npmjs.org`, `ghcr.io`).
- `api.openai.com` is a built-in sbx service. The kit's `credentials` block
  declares an `openai` service key injected as a Bearer token on requests to
  that domain; the proxy attaches the real key (stored via
  `sbx secret set openai`) on the wire while `LLM_API_KEY` in the sandbox
  stays a placeholder.

## Verify (inside the sandbox)

```console
!command -v agent-canvas && node --version
!bash ~/runbooks/smoke.sh
```

`--override-with-envs` is required for the headless runner and is passed by the
runbook — it ignores the `LLM_*` env vars without it. For the interactive
browser UI, run `bash ~/runbooks/canvas.sh` and open http://localhost:8000.
