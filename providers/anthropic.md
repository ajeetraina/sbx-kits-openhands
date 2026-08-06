# Anthropic / Claude (default, recommended)

Wires the OpenHands CLI to Anthropic Claude through LiteLLM. The API key is
injected by the sbx proxy as the `x-api-key` header on the wire, so it never
enters the sandbox.

| | |
|---|---|
| CLI | `openhands` (OpenHands V1, installed via `uv tool install openhands`) |
| LLM | Anthropic Claude (`api.anthropic.com`) |
| `LLM_MODEL` | `anthropic/claude-opus-4-8` (swap for `anthropic/claude-sonnet-4-6` for a cheaper/faster loop) |
| Credential | Anthropic API key via `sbx secret set-custom` |

## 1. Create an Anthropic API key

In the [Claude Console](https://platform.claude.com/) → **API keys** → create a
key. Copy the `sk-ant-…` value.

## 2. Store the key as a secret (never baked into the kit)

The LLM host isn't a built-in sbx service, so use `set-custom`, keyed on the
Anthropic host and the `LLM_API_KEY` env var OpenHands reads:

```bash
sbx secret set-custom --host api.anthropic.com --env LLM_API_KEY --value "$ANTHROPIC_API_KEY"
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
sbx secret set-custom --host api.anthropic.com --env LLM_API_KEY --value "$ANTHROPIC_API_KEY"
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:latest claude   # :latest == :anthropic
# or from a local clone:
sbx run --kit ./kits/anthropic claude
```

## What the kit contains

- Installs `uv` (pip) and then the OpenHands V1 CLI (`uv tool install openhands
  --python 3.12`) onto `~/.local/bin`, which the kit adds to `PATH`.
- `network.allowedDomains` includes `api.anthropic.com` plus the install hosts
  (pypi, GitHub for the uv-managed Python).
- `network.serviceDomains` maps `api.anthropic.com` to a local `llm` service,
  and `serviceAuth` sets `x-api-key: %s`, so the proxy attaches the real key on
  the wire while `LLM_API_KEY` in the sandbox stays a placeholder.

## Verify (inside the sandbox)

The CLI is installed:

```console
!command -v openhands
!openhands --help | head -20
```

End-to-end (the single most useful check) — headless one-shot task:

```console
!bash ~/runbooks/smoke.sh
```

`--override-with-envs` is required and is passed by the runbook — OpenHands
ignores the `LLM_*` env vars without it. For an interactive session, run
`openhands --override-with-envs` in the sandbox shell.
