# OpenHands kit for Docker Sandboxes

A [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) **`kind: sandbox`**
kit that boots into [OpenHands](https://github.com/OpenHands/OpenHands) **Agent
Canvas** (browser UI + agent-server) on port 8000. Self-contained agent,
multi-provider via [LiteLLM](https://github.com/BerriAI/litellm).

| `LLM_MODEL` | Provider | Key |
|---|---|---|
| `anthropic/claude-opus-4-8` (default) | Anthropic | `sbx secret set anthropic` |
| `openai/gpt-4o` | OpenAI | `sbx secret set openai` |
| `gemini/gemini-2.5-pro` | Gemini | `sbx secret set google` |

## Quick start

```bash
sbx login
echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic
sbx run -p 8000 --kit docker.io/ajeetraina777/sbx-openhands-kits:latest openhands
# open http://localhost:8000
```

No key enters the sandbox: it stays proxy-managed and the sbx proxy injects it on
the wire. Switch providers in **Settings > LLM** or override `LLM_MODEL` on create.

Source: https://github.com/ajeetraina/sbx-kits-openhands
