---
name: sweep
description: Fan out /triage across multiple repos in parallel. One triage per repo, shared cross-repo findings, unified drip queues.
argument-hint: <repos-file-or-list> [--dry-run] [--limit N]
allowed-tools: Read, Write, Edit, Bash, Agent, Glob
---

# Sweep: Multi-Repo Triage

Run `/triage` across a list of repos in parallel. Each repo gets its own triage agent, its own `TRIAGE_GRAPH.md`, and its own drip queue. Cross-repo findings propagate through a shared `SWEEP_GRAPH.md`.

## Monoidal contract

| Input | Output | Valid alone? |
|-------|--------|--------------|
| Repo list | Per-repo `TRIAGE_GRAPH.md` + `SWEEP_GRAPH.md` + drip queues | Yes — multi-repo triage with cross-refs |

**Identity:** sweep on one repo = triage on that repo. The cross-reference phase produces no edges, `SWEEP_GRAPH.md` contains one repo summary.

**Composition:** `sweep([A]) + sweep([B]) = sweep([A, B])` — per-repo triage is independent, cross-references are post-hoc. Running sweep on a superset re-triages only repos without completed graphs (idempotent).

**Preconditions:** `/review-schema` per repo (induced automatically in Phase 0, no human gate).

## Input

A list of repos, either:
- A file path containing one `owner/repo` per line (e.g., `repos.txt`)
- Inline list: `/sweep tinygrad/tinygrad google-gemini/gemini-cli withastro/compiler`
- `--dry-run` — passed through to each `/triage` invocation
- `--limit N` — max items per repo (passed through to `/triage`)
- `--add <repo>` — add a repo to the sweep. Runs `/review-schema` for it, then starts triage.
- `--remove <repo>` — remove a repo from the sweep. Stops any running triage agent for it, keeps existing results in `~/.sweep/repos/<owner>-<repo>/` for reference. Does not delete drip queues (they drain naturally).

## State file

`~/.sweep/repos.json` tracks the active repo list and per-repo status:

```json
{
  "repos": [
    {"repo": "tinygrad/tinygrad", "status": "triaged", "added": "2026-05-08"},
    {"repo": "google-gemini/gemini-cli", "status": "in_progress", "added": "2026-05-08"}
  ]
}
```

Statuses: `pending_schema` → `ready` → `in_progress` → `triaged`

Adding a repo sets it to `pending_schema`. Removing sets it to `removed` (kept for history, skipped on future runs).

## Output

- Per repo: `TRIAGE_GRAPH.md` and `~/.sweep/drip-queue/<owner>-<repo>.jsonl`
- Cross-repo: `SWEEP_GRAPH.md` in the working directory with cross-references between repos
- Punch list: unified view across all repos, sorted by score

## Process

### Phase 0: Preflight

1. `gh auth status` — fail fast on auth issues
2. Read `~/.sweep/repos.json` if it exists. These are the known repos.

### Phase 1: Fan out (concurrent)

Launch everything in parallel. Don't wait for actionable to finish before investigating known repos.

```
# Agent 1: actionable (background)
Agent({
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: "Run /actionable. Find new repos, update repos.json.
           For each new repo, run /review-schema.
           Report additions when done."
})

# Agents 2–N: triage on known repos (background, one per repo)
for repo in repos.json:
  Agent({
    subagent_type: "general-purpose",
    isolation: "worktree",
    run_in_background: true,
    prompt: "Run /triage [--dry-run] --limit N on <repo>.
             Write results to <repo-dir>/TRIAGE_GRAPH.md.
             When done, write a one-line summary per item to stdout."
  })
```

Actionable searches for new work while triage investigates existing work. When actionable finishes and adds new repos, spawn triage agents for them into the same pool. No sequential gates — the pipeline fills from the front and drains from the back simultaneously.

Each triage agent runs in its own working directory (`~/.sweep/repos/<owner>-<repo>/`). Triage creates its own worktrees for investigations within each repo.

### Phase 2: Cross-reference (post-hoc)

After all triage agents complete, scan for shared findings. This is summarization, not live propagation — each triage ran independently.

1. Read each repo's `TRIAGE_GRAPH.md`
2. Look for shared patterns across repos:
   - Same dtype (bf16 issues across repos)
   - Same algorithmic pattern (graph rewrite depth, recursive traversal)
   - Same dependency (LLVM version, CUDA toolkit)
3. Write cross-references to `SWEEP_GRAPH.md`:

```markdown
# Sweep Graph (2026-05-08)

## Cross-repo findings
- bf16 cluster: tinygrad#6909 ↔ tinygrad#11756 ↔ tinygrad#16114 (same dtype, different failure modes)
- graph rewrite depth: tinygrad#13409 (ScatterND) shares root cause pattern with any repo using recursive AST traversal

## Per-repo summaries
### tinygrad/tinygrad
[punch list from triage]

### google-gemini/gemini-cli
[punch list from triage]
```

### Phase 3: Unified punch list

Merge all repos' punch lists into one, sorted by score. Format:

```
READY TO SHIP
  tinygrad/tinygrad #6909 — bf16 autocast (score 3, fix ready)
  gemini-cli #24736 — union-find compaction (score 6, LGTM)

BLOCKED
  tinygrad/tinygrad #13409 — ScatterND (needs scatter primitive)

NO ACTION
  tinygrad/tinygrad #7020 — TinyJit wrong values (already fixed)
```

### Phase 4: Drip (full run only)

For each repo with "ready to ship" items, load its drip queue:
- `~/.sweep/drip-queue/tinygrad-tinygrad.jsonl`
- `~/.sweep/drip-queue/google-gemini-gemini-cli.jsonl`

Each repo gets its own independent drip cadence. One open PR per repo at a time. The repos don't interfere with each other's pacing.

### Phase 5: Heartbeat

After all phases complete, set up a recurring wake-up to keep the pipeline alive:

```
CronCreate({
  cron: "*/5 * * * *",
  prompt: "/sweep --check --concurrency N [--dry-run]",
  recurring: true
})
```

Pass the same flags from the original invocation into the heartbeat prompt — including `--dry-run` if set. **Always create the heartbeat, even in dry-run.** Dry-run still needs the pipeline to keep cooking — checking agent progress, re-running actionable, collecting results. The only thing dry-run skips is remote side effects (no PRs, no pushes). The heartbeat is local.

The heartbeat re-enters sweep every 5 minutes. Idempotency means re-entry is cheap — it checks for new PR outcomes, pushes the next drip entry if a slot opened, and re-runs actionable if the queue is low. Stops when the session ends (session-only, not durable).

## Eviction (runs every tick)

The roster grows via `/actionable`. Sweep prunes it. Check every heartbeat tick, before launching triage agents.

| Trigger | Action |
|---------|--------|
| All issues KILLED or BLOCKED, no PENDING/CONFIRMED items | evict |
| Cooldown active with no end date (permanent ban) | evict |
| Three consecutive PR rejections, no merges | evict |
| Repo archived or deleted upstream | evict |
| No open items AND no open PRs by user | evict |
| Status is `dormant` for >14 days | evict |

**Eviction means:** status → `evicted` in `repos.json`. Drip queue drains (don't abandon open PRs). State files kept for reference. Repo can be re-added with `--add`.

**Competing-PR eviction:** If the only actionable issue on a repo has a competing open PR, and the repo has no other items, demote to `monitoring`. Don't evict — the competing PR might stall.

**Apply now.** On each `--check` tick, scan `repos.json` for eviction triggers before doing anything else. Log evictions to `~/.sweep/actionable/candidates.jsonl`.

## Rules

- **Never ask the user.** Sweep runs autonomously. If you have a hunch, act on it. If you're uncertain, skip it and move on. Log what you skipped and why. The user reads the punch list at the end, not a questionnaire in the middle.
- **One triage per repo.** Never mix repos in a single triage run.
- **Cross-pollinate, don't duplicate.** If two repos share a finding, write the cross-reference. Don't investigate the same thing twice.
- **Independent drip queues.** Each repo has its own pacing. Getting banned from one repo doesn't affect the others.
- **Idempotent.** Running sweep twice skips repos whose triage is already complete (TRIAGE_GRAPH.md exists with all outcomes filled).
- **Auth first.** Verify access to every repo before launching any agents.
- **All PRs route through /drip.** No direct `gh pr create` during active pipeline runs. 14 manual PRs in 2 days triggered a ban warning. The drip queue exists to prevent this — enforce it.
- **Never recommend closing a stale PR.** No-review age is a signal to ping, rebase, or break up — not to close. Closing destroys optionality. Only recommend closing when a maintainer explicitly rejects it or the approach is superseded by another merged PR.
