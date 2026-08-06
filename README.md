# sbx kits for OpenHands

A standalone [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit
(`kind: mixin`) that installs the
[OpenHands](https://github.com/OpenHands/OpenHands-CLI) V1 coding-agent CLI
(`openhands`) into any sandbox and wires it to an LLM through
[LiteLLM](https://github.com/BerriAI/litellm), plus a one-shot smoke-test
runbook.

**Anthropic Claude** is the zero-config default. The provider is swappable to
OpenAI or to a local [Docker Model Runner](https://docs.docker.com/ai/model-runner/).
See [providers/](./providers/) for copy-paste config.

## Quickstart (Anthropic)

```bash
# 1. Sign in to Docker Hub
sbx login

# 2. Store your Anthropic key on the host (once) — it never enters the sandbox
sbx secret set-custom --host api.anthropic.com --env LLM_API_KEY --value "$ANTHROPIC_API_KEY"

# 3. Launch the kit — run from a repo clone, NOT your home directory
git clone https://github.com/ajeetraina/sbx-kits-openhands.git
cd sbx-kits-openhands
sbx run --kit ./kits/anthropic claude

# 4. Inside the sandbox: prove it end-to-end
bash ~/runbooks/smoke.sh                 # headless one-shot task through OpenHands

# 5. Or start an interactive OpenHands session
openhands --override-with-envs
```

`env | grep LLM_API_KEY` inside the sandbox shows a placeholder, never your real
`sk-ant-…` key. Full walkthrough and the `openai` / `dmr` providers are below.

## What the kit does

Layered onto an agent, the mixin does four observable things:

1. Installs `uv` and then the OpenHands V1 CLI (`uv tool install openhands
   --python 3.12`) onto `~/.local/bin`, which it adds to `PATH`.
2. Sets `LLM_MODEL` / `LLM_API_KEY` (/ `LLM_BASE_URL` for the local model
   runner) so OpenHands knows which model to drive.
3. For cloud providers, routes LLM traffic through the sbx proxy so the key is
   attached on the wire (`x-api-key` for Anthropic, `Authorization: Bearer` for
   OpenAI) and never enters the sandbox.
4. Ships a `~/runbooks/smoke.sh` end-to-end check and injects a memory note so
   the sandbox's own agent knows OpenHands is available.

**No key lives in the sandbox.** `sbx run` has no `-e` flag: you store the key
once with sbx's secret manager and the proxy injects it into outbound LLM
requests, so it never enters the microVM, shell history, or `ps`.

> **OpenHands ignores the `LLM_*` env vars unless you pass `--override-with-envs`.**
> Always run `openhands --override-with-envs` (the smoke-test runbook does this
> for you). This is an OpenHands design choice, not a kit limitation.

## Prerequisites

### 0. Log in to Docker Hub

```console
sbx login
```

### 1. Get an LLM key (cloud providers)

- **Anthropic** (default): an `sk-ant-…` key from the
  [Claude Console](https://platform.claude.com/).
- **OpenAI**: an `sk-…` key from the
  [OpenAI platform](https://platform.openai.com/api-keys).
- **Docker Model Runner** (`dmr`): no key — pull a model on the host with
  `docker model pull ai/qwen2.5-coder`.

### 2. Store the key with sbx (never on the command line)

The key is never baked into the kit; you store it once on the host with
`sbx secret set-custom` (custom because the LLM host is not a built-in sbx
service), keyed on the provider host and the `LLM_API_KEY` env var. The sbx
proxy then swaps the placeholder for the real key on outbound requests, so it
never enters the sandbox. Secrets are global by default:

```console
# Anthropic
sbx secret set-custom --host api.anthropic.com --env LLM_API_KEY --value "$ANTHROPIC_API_KEY"
# OpenAI
sbx secret set-custom --host api.openai.com --env LLM_API_KEY --value "$OPENAI_API_KEY"

sbx secret ls   # confirm the secret is stored
```

**Self-managed sbx? Allow egress once.** If you are *not* under centralized AI
governance, permit the kit's hosts so sandbox requests are not denied by the
network policy (with org-managed governance an admin allows these for you):

```console
sbx policy init balanced   # one-time, only if you have never initialized a policy
sbx policy allow network "api.anthropic.com,pypi.org,files.pythonhosted.org,github.com,objects.githubusercontent.com,release-assets.githubusercontent.com,astral.sh"
```

`sbx policy log <sandbox>` shows any host that was blocked, so you can allow
exactly that one.

### 3. Launch the sandbox with the kit

Each provider is published as its own image tag — pick the one matching your
setup.

```console
# Anthropic / Claude (default, recommended) — :latest == :anthropic
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:latest claude

# OpenAI
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:openai claude

# Local Docker Model Runner (no cloud key)
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:dmr claude
```

Or straight from this repo over git (uses the default anthropic provider):

```console
sbx run --kit "git+https://github.com/ajeetraina/sbx-kits-openhands.git" claude
```

Or from a local clone (the default kit lives at the repo root):

```console
git clone https://github.com/ajeetraina/sbx-kits-openhands.git
sbx run --kit ./sbx-kits-openhands/ claude
```

#### Choosing the agent

The trailing argument (`claude` above) is the **coding agent** that runs the
sandbox session — a separate axis from the OpenHands CLI the kit installs. The
tag decides which LLM OpenHands drives; the trailing agent decides which
assistant you interact with in the sandbox shell. `sbx run --help` lists them:

```
claude, claude-bedrock, codex, copilot, cursor, docker-agent, droid, gemini, kiro, opencode, shell
```

`shell` is a good choice if you only want to drive OpenHands directly:

```console
sbx run --kit docker.io/ajeetraina777/sbx-openhands-kits:latest shell
```

### 4. Confirm the kit installed correctly

Inside the agent session, use `!` shell escapes to prove the mixin is really
inside.

**4a. The OpenHands CLI is installed:**

```console
!command -v openhands
!openhands --help | head -20
```

**4b. The mixin's env is present** (a fingerprint that the kit wired things up):

```console
!env | grep -E 'LLM_MODEL|LLM_API_KEY'
```

`LLM_API_KEY` holds a placeholder for cloud providers; the real key lives only on
the host and is injected on the wire.

**4c. End-to-end functional proof** — run a headless one-shot task through
OpenHands. This exercises the installed binary, the env vars, the proxy-injected
key, and a live round-trip to the model, so if you only run one check, run this:

```console
!bash ~/runbooks/smoke.sh
```

### 5. Use OpenHands

Start an interactive session (remember `--override-with-envs`):

```console
openhands --override-with-envs
```

Or drive it headlessly for scripting / CI:

```console
openhands --headless --override-with-envs --exit-without-confirmation -t "Add tests for utils.py"
openhands --headless --override-with-envs --exit-without-confirmation -f task.md
```

### 6. Try the runbook

The kit ships a runnable demo under `~/runbooks/`. It is a plain file under
[`files/home/runbooks/`](./files/home/runbooks/) (the
[sbx-kits-contrib][contrib] `files/home/` convention — everything under it is
mirrored into `/home/agent/`), **not** hard-coded into `spec.yaml`:

```console
!bash ~/runbooks/smoke.sh
!bash ~/runbooks/smoke.sh "write a Python function that reverses a string, with a test"
```

To add a runbook, drop a file in `files/home/runbooks/` — it ships
automatically, no `spec.yaml` change.

[contrib]: https://github.com/docker/sbx-kits-contrib

## Switching the LLM provider

| Provider | `LLM_MODEL` | LLM | Credential | Doc |
|---|---|---|---|---|
| anthropic (default) | `anthropic/claude-opus-4-8` | Anthropic `api.anthropic.com` | API key | [providers/anthropic.md](./providers/anthropic.md) |
| openai | `openai/gpt-4o` | OpenAI `api.openai.com` | API key | [providers/openai.md](./providers/openai.md) |
| dmr | `openai/ai/qwen2.5-coder` | local Docker Model Runner | none | [providers/dmr.md](./providers/dmr.md) |

Each page has the exact `LLM_MODEL`, run command, and setup notes. Overview:
[providers/README.md](./providers/README.md).

## Troubleshooting

**`mount policy denied: /Users/<you>`** when running `sbx run --kit docker.io/..`:
the sbx runtime refuses to mount your home directory into the sandbox. Run
`sbx run` from any directory other than your home directory.

**`openhands: command not found`:** the CLI installs to `~/.local/bin` via `uv
tool install`. The kit adds that to `PATH`; if a custom shell rc overrode `PATH`,
run `export PATH=/home/agent/.local/bin:$PATH` or re-check the install step
(`uv tool list`).

**OpenHands seems to ignore the model / key:** you almost certainly forgot
`--override-with-envs`. OpenHands ignores the `LLM_*` env vars without it. The
smoke-test runbook passes it for you.

**Network policy denied a request** (egress blocked reaching `api.anthropic.com`
or the install hosts): if you self-manage sbx policy and have no centralized
governance, allow the kit's hosts once (global scope):

```console
sbx policy allow network "api.anthropic.com,pypi.org,files.pythonhosted.org,github.com,objects.githubusercontent.com,release-assets.githubusercontent.com,astral.sh"
```

Under org-managed governance a local allow cannot widen egress — an admin must
add the allow. `sbx policy log <sandbox>` names the exact blocked host.

**`401`/authentication error from the LLM:** confirm the secret is stored
(`sbx secret ls`) and keyed on the right host (`api.anthropic.com` for Anthropic,
`api.openai.com` for OpenAI) with `--env LLM_API_KEY`.

**DMR: OpenHands can't reach the model:** confirm Docker Model Runner is running
on the host (`docker model ls`) and that the model named in `LLM_MODEL` is
pulled (`docker model pull ai/qwen2.5-coder`).
