---
name: dashboard
description: Live pipeline dashboard. Serves a self-refreshing page showing sweep status, drip queues, retro params, and recent events. Default port 8321.
argument-hint: [<repo-or-sweep-dir>] [--port N] [--once]
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Dashboard

Spin up a tiny HTTP server that reads pipeline state on each request and serves a live view.

## Usage

```
/dashboard              # serve on localhost:8321, open browser
/dashboard --port 9000  # custom port
/dashboard --once       # print snapshot to terminal, no server
```

Default: start server on port 8321, open `http://localhost:8321` in the browser. The page auto-refreshes every 10 seconds via JS fetch — each refresh reads the latest state files server-side.

## Sources

- `/tmp/sweep/repos.json` — repo statuses
- `/tmp/drip-queue/*.jsonl` — queue entries by status
- `/tmp/retro/*.jsonl` — active parameters (last-value-wins per key)
- `/tmp/sweep-log/*.jsonl` — last 20 events
- `TRIAGE_GRAPH.md` / `HYPOTHESIS_GRAPH.md` — grep status markers

## Targeting

- **No argument:** read `/tmp/sweep/repos.json` for the active repo list.
- **`<owner/repo>`:** show state for one repo only.
- **`<path>`:** treat as a sweep directory containing `repos.json`.

## Server

Python `http.server` — no dependencies. One handler:

- `GET /` — read all state files, render HTML, return it. Fresh data on every request.
- `GET /api` — return the same data as JSON (for scripting or custom UIs).

The HTML includes a `setInterval(fetch, 10000)` that swaps the page body. No full-page reload flicker.

Kill with Ctrl-C or close the terminal. No state to clean up.

## Process

1. Kill any existing process on the port.
2. Read the repo list. Fan out to per-repo state files.
3. For each repo: count drip entries by status, read retro params, count triage items by status.
4. Tail the event logs (last 20 across all repos, sorted by timestamp).
5. Serve. Generate HTML on each request from the current state.

## Rules

- Read-only. Never modify state files.
- Degrade gracefully. Missing files = empty sections.
- One file. The server is a single Python script written to `/tmp/sweep-dashboard-server.py`. No package installs.
