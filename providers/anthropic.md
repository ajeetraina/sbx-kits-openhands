# Anthropic / Claude (default, recommended)

Wires OpenHands Agent Canvas (and the headless runner) to Anthropic Claude
through LiteLLM. The API key is injected by the sbx proxy as the `x-api-key`
header on the wire, so it never enters the sandbox.

| | |
|---|---|
| Surfaces | `agent-canvas` (browser UI + backend, port 8000) + headless `openhands` |
| LLM | Anthropic Claude (`api.anthropic.com`) |
| `LLM_MODEL` | `anthropic/claude-opus-4-8` (swap for `anthropic/claude-sonnet-4-6` for a cheaper/faster loop) |
| Credential | Anthropic API key via `sbx secret set anthropic` |

## 1. Create an Anthropic API key

In the [Claude Console](https://platform.claude.com/) → **API keys** → create a
key. Copy the `sk-ant-…` value.

## 2. Store the key as a secret (never baked into the kit)

`anthropic` is a built-in sbx service, so a plain `sbx secret set` stores the
key — no host or env flags needed:

```bash
echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic   # or omit the pipe to be prompted
sbx secret ls   # confirm the secret is stored
```

The sandbox sees `LLM_API_KEY` as a placeholder; the proxy swaps in the real key
on the `x-api-key` header for requests to `api.anthropic.com`.

## 3. (Optional) Choose the model

The kit defaults to `anthropic/claude-opus-4-8`. To use a different Claude model,
edit `LLM_MODEL` in a local clone (`kits/anthropic/spec.yaml`) or
`export LLM_MODEL=anthropic/claude-sonnet-4-6` inside the sandbox before running.

## Run

```bash
echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic
sbx run -p 8000 --kit docker.io/ajeetraina777/sbx-openhands-kits:latest claude   # :latest == :anthropic
# or from a local clone:
sbx run -p 8000 --kit ./kits/anthropic claude
```

`-p 8000` forwards Agent Canvas to the host.

## What the kit contains

- Installs Node.js 22 + OpenHands Agent Canvas (`npm i -g
  @openhands/agent-canvas`, bin: `agent-canvas`) and the headless OpenHands
  runner (`uv tool install openhands --python 3.12`, bin: `openhands`) onto
  `PATH`.
- `permissions.network.allow` includes `api.anthropic.com` plus the install
  hosts (pypi, GitHub for the uv-managed Python, `nodejs.org`,
  `registry.npmjs.org`, `ghcr.io`).
- `api.anthropic.com` is a built-in sbx service. The kit's `credentials` block
  declares an `anthropic` service key injected as `x-api-key` on requests to
  that domain; the proxy attaches the real key (stored via
  `sbx secret set anthropic`) on the wire while `LLM_API_KEY` in the sandbox
  stays a placeholder.

## Verify (inside the sandbox)

Both surfaces are installed:

```console
!command -v agent-canvas && node --version
!command -v openhands
```

End-to-end (the single most useful check) — headless one-shot task:

```console
!bash ~/runbooks/smoke.sh
```

`--override-with-envs` is required for the headless runner and is passed by the
runbook — it ignores the `LLM_*` env vars without it. For the interactive
browser UI, run `bash ~/runbooks/canvas.sh` and open http://localhost:8000.
