# OpenAI

Wires the OpenHands CLI to OpenAI through LiteLLM. The API key is injected by the
sbx proxy as an `Authorization: Bearer` header on the wire, so it never enters
the sandbox.

| | |
|---|---|
| CLI | `openhands` (OpenHands V1, installed via `uv tool install openhands`) |
| LLM | OpenAI (`api.openai.com`) |
| `LLM_MODEL` | `openai/gpt-4o` (swap for any OpenAI chat model you have access to) |
| Credential | OpenAI API key via `sbx secret set-custom` |

## 1. Create an OpenAI API key

In the [OpenAI platform](https://platform.openai.com/api-keys) → create a secret
key. Copy the `sk-…` value.

## 2. Store the key as a secret

Keyed on the OpenAI host and the `LLM_API_KEY` env var OpenHands reads:

```bash
sbx secret set-custom --host api.openai.com --env LLM_API_KEY --value "$OPENAI_API_KEY"
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
sbx secret set-custom --host api.openai.com --env LLM_API_KEY --value "$OPENAI_API_KEY"
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:openai claude
# or from a local clone:
sbx run --kit ./kits/openai claude
```

## What the kit contains

- Installs `uv` (pip) and then the OpenHands V1 CLI (`uv tool install openhands
  --python 3.12`) onto `~/.local/bin`, which the kit adds to `PATH`.
- `network.allowedDomains` includes `api.openai.com` plus the install hosts.
- `network.serviceDomains` maps `api.openai.com` to a local `llm` service, and
  `serviceAuth` sets `Authorization: Bearer %s`, so the proxy attaches the real
  key on the wire while `LLM_API_KEY` in the sandbox stays a placeholder.

## Verify (inside the sandbox)

```console
!command -v openhands
!bash ~/runbooks/smoke.sh
```

`--override-with-envs` is required and is passed by the runbook — OpenHands
ignores the `LLM_*` env vars without it. For an interactive session, run
`openhands --override-with-envs`.
