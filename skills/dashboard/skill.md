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

- `~/.sweep/repos.json` — repo statuses
- `~/.sweep/drip-queue/*.jsonl` — queue entries by status
- `~/.sweep/retro/*.jsonl` — active parameters (last-value-wins per key)
- `~/.sweep/sweep-log/*.jsonl` — last 20 events
- `TRIAGE_GRAPH.md` / `HYPOTHESIS_GRAPH.md` — grep status markers

## Targeting

- **No argument:** read `~/.sweep/repos.json` for the active repo list.
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

## Dopamine layer

The dashboard should feel like a scoreboard, not a log dump.

### Scoreboard header

Big numbers across the top. Always visible.

```
  3 merged    14 submitted    47% rate    🔥 3 streak    12d since last rejection
```

- **Merged / submitted / rate** — the score. Computed from all drip queues.
- **Streak** — consecutive merges without a rejection. Resets on close/reject.
- **Days since last rejection** — the inverse streak. Measures pipeline discipline.

### Ready queue (the hit list)

Table of issues ready to ship. Green rows. This is the dopamine — work that's done and waiting to land.

```
  Repo                Issue    Fix          Viability   Status
  aider               #3702    2 lines      HIGH        ready
  compiler            #1091    2 lines      HIGH        ready
```

### Repo cards with progress bars

Each repo gets a visual progress indicator, not just text counts.

```
  withastro/compiler  ████████░░  4/5 investigated   [triaged]
  google-gemini/cli   ██░░░░░░░░  1/4 investigated   [ready]
  python/cpython      ░░░░░░░░░░  0/3 investigated   [pending_schema]
```

Bar fills as items move from PENDING → IN_PROGRESS → CONFIRMED/KILLED. Color by status: green (triaged), blue (in_progress), yellow (pending_schema), grey (dormant).

### Kill feed

Replace "Recent Events: no events yet" with a scrolling log of the last 20 events, newest first. Each event is one line:

```
  11:04  aider #3702 → ready (2 lines)
  10:58  compiler #1091 → ready (2 lines)
  10:41  tinygrad #16085 → merged (-34 lines)
  10:30  gemini-cli #25459 → investigating
  10:12  mvdan/sh #813 → ready (~35 lines)
```

Merged events get green highlight. Rejections get red. Everything else is neutral.

### Status colors

Consistent across all elements:

| Status | Color |
|---|---|
| ready / merged | green |
| triaged | blue |
| in_progress / investigating | cyan |
| pending_schema / pending_review | yellow |
| dormant | grey |
| rejected / closed / cooldown | red |

## Rules

- Read-only. Never modify state files.
- Degrade gracefully. Missing files = empty sections.
- One file. The server is a single Python script written to `~/.sweep/dashboard.py`. No package installs.
