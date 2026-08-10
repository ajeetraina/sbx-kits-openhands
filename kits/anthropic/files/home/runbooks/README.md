# Runbooks

Runnable demos shipped with the OpenHands kit. They live at `~/runbooks/` in the
sandbox and use the `openhands` CLI plus the `LLM_*` environment the kit sets up.
For cloud providers the credential in the sandbox is always a placeholder (stored
on the host with `sbx secret set anthropic` / `sbx secret set openai`) — the sbx
proxy overwrites the auth header with the real key on the wire.

## smoke.sh

The flagship end-to-end check. Runs the OpenHands CLI headlessly against a tiny
task and prints the result — exercises the installed binary, the `LLM_*` env,
the proxy-injected key, and a live round-trip to the model in one shot.

```console
bash ~/runbooks/smoke.sh
bash ~/runbooks/smoke.sh "add a docstring to every function in app.py"
```

`--override-with-envs` is passed for you — **OpenHands ignores the `LLM_*`
environment variables without it**. `--headless` requires a task, and
`--exit-without-confirmation` keeps the run non-interactive (headless always
runs in always-approve mode).

---

To add a runbook, drop a file in `files/home/runbooks/` — it ships automatically
(the [sbx-kits-contrib][contrib] `files/home/` convention mirrors everything
under it into `/home/agent/`), no `spec.yaml` change.

[contrib]: https://github.com/docker/sbx-kits-contrib
