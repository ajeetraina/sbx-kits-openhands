# OpenHands kit for Docker Sandboxes

A standalone [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit
(`kind: mixin`) that installs the
[OpenHands](https://github.com/OpenHands/OpenHands-CLI) V1 coding-agent CLI
(`openhands`) into any sandbox and wires it to an LLM through
[LiteLLM](https://github.com/BerriAI/litellm), plus a one-shot smoke-test
runbook. This image ships in three provider flavors, one per tag.

Source and full docs: https://github.com/ajeetraina/sbx-kits-openhands

## Image tags

| Tag | `LLM_MODEL` | LLM | Credential |
|-----|-------------|-----|------------|
| `latest`, `anthropic` | `anthropic/claude-opus-4-8` | Anthropic (`api.anthropic.com`) | API key via `sbx secret set anthropic` |
| `openai` | `openai/gpt-4o` | OpenAI (`api.openai.com`) | API key via `sbx secret set openai` |
| `dmr` | `openai/ai/qwen2.5-coder` | local Docker Model Runner | none |

`anthropic` is the default because Claude is Anthropic's recommended model for
agentic coding. `openai` is a drop-in swap; `dmr` runs entirely against a local
Docker Model Runner model with no cloud key.

## Quick start

Anthropic default. `anthropic` is a built-in sbx service — store an API key
once, then launch:

    echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic
    sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:latest claude

OpenAI:

    echo "$OPENAI_API_KEY" | sbx secret set openai
    sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:openai claude

Local Docker Model Runner (pull a model on the host first):

    docker model pull ai/qwen2.5-coder
    sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:dmr claude

No tag holds a key. The sbx proxy injects it from the stored secret, so the key
never enters the sandbox. `sbx run` has no `-e` flag by design.

## How it works

Each kit installs `uv` and the OpenHands V1 CLI (`uv tool install openhands
--python 3.12`) onto PATH, sets the `LLM_*` environment (model, key placeholder,
base URL for DMR), and — for cloud providers — routes LLM traffic through the
sbx proxy, which attaches the stored key on the wire (`x-api-key` for Anthropic,
`Authorization: Bearer` for OpenAI). It also ships a `~/runbooks/smoke.sh`
end-to-end check.

**Run OpenHands with `--override-with-envs`** — it ignores the `LLM_*` env vars
otherwise. Interactive: `openhands --override-with-envs`. Headless:
`openhands --headless --override-with-envs --exit-without-confirmation -t "…"`.

Per-provider setup, validation, and the raw `spec.yaml` for each kit live on
GitHub: https://github.com/ajeetraina/sbx-kits-openhands/tree/main/providers
