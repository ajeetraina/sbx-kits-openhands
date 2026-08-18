# Runbooks

Runnable demos shipped with the OpenHands kit. They live at `~/runbooks/` in the
sandbox and use the `LLM_*` environment the kit sets up. For cloud providers the
credential in the sandbox is always a placeholder (stored on the host with
`sbx secret set anthropic` / `sbx secret set openai`) — the sbx proxy overwrites
the auth header with the real key on the wire.

OpenHands' interactive CLI/TUI is deprecated in favour of **Agent Canvas** (a
browser UI + backend server); the **headless** runner remains fully supported
for automation. This kit ships both — a launcher for each.

## canvas.sh

Starts **Agent Canvas** (`agent-canvas`) — the primary, interactive surface — on
port 8000.

```console
bash ~/runbooks/canvas.sh
PORT=3000 bash ~/runbooks/canvas.sh
```

The server is long-running (Ctrl-C to stop). Port 8000 must be forwarded to the
host: start the sandbox with `sbx run -p 8000 …`, then open
http://localhost:8000.

Agent Canvas does **not** read the `LLM_*` environment variables — its LLM
config normally lives in the web UI. `canvas.sh` works around this: once the
backend is healthy it seeds `LLM_MODEL` / `LLM_API_KEY` (and `LLM_BASE_URL` for
DMR) into Canvas via its local settings API, so the model is preconfigured and
you should not need to touch **Settings > LLM**. For cloud providers the key it
stores is just the placeholder; the sbx proxy injects the real key on the wire.
If the seed ever fails (e.g. the Canvas API changed), the script prints a hint
to set the model manually — any placeholder API key works, since the proxy
supplies the real one.

## smoke.sh

The flagship end-to-end check, and the recommended way to verify the kit works
in a headless/non-interactive shell (e.g. `sbx exec`, where a browser UI can't
be driven). Runs the headless `openhands` runner against a tiny task and prints
the result — exercises the installed binary, the `LLM_*` env, the proxy-injected
key, and a live round-trip to the model in one shot.

```console
bash ~/runbooks/smoke.sh
bash ~/runbooks/smoke.sh "add a docstring to every function in app.py"
```

`--override-with-envs` is passed for you — **the headless runner ignores the
`LLM_*` environment variables without it**. `--headless` requires a task, and
`--exit-without-confirmation` keeps the run non-interactive (headless always
runs in always-approve mode).

---

To add a runbook, drop a file in `files/home/runbooks/` — it ships automatically
(the [sbx-kits-contrib][contrib] `files/home/` convention mirrors everything
under it into `/home/agent/`), no `spec.yaml` change.

[contrib]: https://github.com/docker/sbx-kits-contrib
