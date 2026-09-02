# OpenHands Agent Canvas (standalone sandbox)

A self-contained [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
**`kind: sandbox`** kit that boots straight into
[OpenHands](https://github.com/OpenHands/OpenHands) **Agent Canvas** — the
browser UI + agent-server — on port 8000.

Unlike the mixin variants at the repo root (which layer onto a base agent), this
is a standalone agent: it owns its image, entrypoint, and credentials, so there
is no base-agent coupling and no credential collision. It supports Anthropic,
OpenAI, and Gemini from a single spec.

## Quickstart

```bash
sbx login

# Store a key once (Anthropic default; also: openai, google)
echo "$ANTHROPIC_API_KEY" | sbx secret set anthropic

# Launch — forward port 8000, then open http://localhost:8000
sbx run -p 8000 --kit ./openhands-canvas openhands-canvas
```

The model defaults to `anthropic/claude-opus-4-8` and is pre-seeded into Canvas'
settings. Switch providers in **Settings > LLM** or recreate with `LLM_MODEL`
overridden and the matching `sbx secret set <service>`.

Keys stay **proxy-managed** — the sbx proxy injects the real key on the wire
(`x-api-key` / `Bearer` / `x-goog-api-key`); nothing enters the sandbox.

## Notes

- Built on `docker/sandbox-templates:shell-docker` (Node.js 22 + uv already
  present); the kit adds `@openhands/agent-canvas` and the headless `openhands`
  runner.
- The sbx proxy is **not** bypassed — `HTTP_PROXY`/`HTTPS_PROXY` are left intact
  so credential injection and egress enforcement keep working.
