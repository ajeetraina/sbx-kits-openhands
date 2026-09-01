# Docker Model Runner (local, no cloud key)

Wires OpenHands Agent Canvas (and the headless runner) to a local [Docker Model
Runner](https://docs.docker.com/ai/model-runner/) (DMR) over
`host.docker.internal:12434`. No cloud credentials and no external LLM — the
model runs on your host.

| | |
|---|---|
| Surfaces | `agent-canvas` (browser UI + backend, port 8000) + headless `openhands` |
| LLM | Docker Model Runner (`host.docker.internal:12434`) |
| `LLM_MODEL` | `openai/ai/qwen2.5-coder` (change to whatever you pulled) |
| Credential | none |

## 1. Pull a coding model on the host

DMR serves an OpenAI-compatible endpoint. Pull a model before launching:

```bash
docker model pull ai/qwen2.5-coder
docker model ls   # confirm it's available
```

Any DMR model works — set `LLM_MODEL` to `openai/<model-name>` to match.

## 2. Run

```bash
sbx run -p 8000 --kit docker.io/ajeetraina777/sbx-openhands-kits:dmr shell
# or from a local clone:
sbx run -p 8000 --kit ./kits/dmr shell
```

`-p 8000` forwards Agent Canvas to the host. No `sbx secret` step — DMR needs no
key.

## What the kit contains

- Installs Node.js 22 + OpenHands Agent Canvas (`npm i -g
  @openhands/agent-canvas`, bin: `agent-canvas`) and the headless OpenHands
  runner (`uv tool install openhands --python 3.12`, bin: `openhands`) onto
  `PATH`.
- `permissions.network.allow` includes `host.docker.internal:12434` (DMR) plus
  the install hosts (pypi, GitHub, `nodejs.org`, `registry.npmjs.org`,
  `ghcr.io`). No cloud LLM host, no proxy-injected credential.
- `LLM_BASE_URL` points at `http://host.docker.internal:12434/engines/v1`,
  `LLM_API_KEY=dmr` (DMR ignores it), and `LLM_MODEL` uses LiteLLM's `openai/`
  provider so the OpenAI-compatible endpoint is used.

## Verify (inside the sandbox)

```console
!command -v agent-canvas && node --version
!bash ~/runbooks/smoke.sh
```

`--override-with-envs` is required for the headless runner and is passed by the
runbook. If OpenHands can't reach the model, confirm DMR is running on the host
(`docker model ls`) and that the model named in `LLM_MODEL` is pulled. For the
interactive browser UI, run `bash ~/runbooks/canvas.sh` and open
http://localhost:8000.
