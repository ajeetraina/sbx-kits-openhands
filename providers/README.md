# LLM providers for the OpenHands kit

The kit installs [OpenHands](https://github.com/OpenHands/OpenHands) **Agent
Canvas** (`agent-canvas`, the browser UI + backend server on port 8000) plus the
still-supported headless `openhands` runner into a sandbox, and points both at an
LLM through [LiteLLM](https://github.com/BerriAI/litellm). What changes per
provider is *which model* the agent drives and *how the credential reaches it*.

## Provider matrix

| Provider | `LLM_MODEL` (default) | Runs where | Credential | How it reaches the LLM |
|---|---|---|---|---|
| [anthropic](./anthropic.md) (default) | `anthropic/claude-opus-4-8` | Cloud (`api.anthropic.com`) | `sbx secret set anthropic` | proxy injects `x-api-key` on the wire |
| [openai](./openai.md) | `openai/gpt-4o` | Cloud (`api.openai.com`) | `sbx secret set openai` | proxy injects `Authorization: Bearer` on the wire |
| [dmr](./dmr.md) | `openai/ai/qwen2.5-coder` | Local ([Docker Model Runner](https://docs.docker.com/ai/model-runner/)) | none | direct over `host.docker.internal:12434` |

## Why `anthropic` is the default

OpenHands is model-agnostic (it routes through LiteLLM), and Claude is
Anthropic's recommended default for agentic coding. The `openai` provider is a
drop-in swap for teams standardized on OpenAI, and `dmr` runs entirely locally
against a Docker Model Runner model — no cloud key, useful for offline or
cost-sensitive work — at the cost of using a smaller local model.

## Two notes that apply to every provider

1. **The kit never holds a key.** `sbx run` has no `-e` flag by design. Both
   `anthropic` and `openai` are built-in sbx services, so you store the key once
   with a plain `sbx secret set <service>`. The sbx proxy then injects the real
   key on outbound requests, so it never enters the sandbox, shell history, or
   `ps` — `LLM_API_KEY` in the sandbox stays a placeholder. Secrets are global
   by default (scope one with `--sandbox`).

   ```bash
   # Anthropic
   echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic
   # OpenAI
   echo "$OPENAI_API_KEY" | sbx secret set openai

   sbx secret ls   # confirm the secret is stored
   ```

   `dmr` needs no key — it talks to a local Docker Model Runner.

2. **Two surfaces, one config.** The kit sets `LLM_MODEL` / `LLM_API_KEY` (/
   `LLM_BASE_URL` for dmr) once. **Agent Canvas** (`bash ~/runbooks/canvas.sh`,
   http://localhost:8000) picks them up on startup — forward the port with
   `sbx run -p 8000 …`. The **headless** `openhands` runner needs
   `--override-with-envs` to honour those same env vars (an OpenHands design
   choice, not a kit limitation); `~/runbooks/smoke.sh` passes it for you.

## Switching provider

Each provider is published as an image tag (`:anthropic`, `:openai`, `:dmr`), and
the same specs live under [`kits/`](../kits). Pick one, store its key if it's a
cloud provider, and run it with port 8000 forwarded for Agent Canvas:

```bash
echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic
sbx run -p 8000 --kit docker.io/ajeetraina777/sbx-openhands-kits:anthropic claude
# or from this repo: sbx run -p 8000 --kit ./kits/anthropic claude
```

See each provider's page for the exact `LLM_MODEL`, run command, and setup notes.
