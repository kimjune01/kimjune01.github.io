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

`~/.sweep/repos.jsonl` tracks the active repo list and per-repo status. Append-only, one event per line, last-action-wins per repo:

```jsonl
{"ts": "2026-05-08T00:00:00Z", "action": "add", "repo": "tinygrad/tinygrad", "status": "triaged", "cooldown_until": "2026-05-22"}
{"ts": "2026-05-09T08:00:00Z", "action": "add", "repo": "astral-sh/ruff", "status": "ready"}
{"ts": "2026-05-09T12:00:00Z", "action": "triage", "repo": "astral-sh/ruff", "status": "triaged"}
{"ts": "2026-05-09T12:00:00Z", "action": "evict", "repo": "python-attrs/attrs", "status": "evicted", "reason": "0 labeled issues"}
```

Actions: `add`, `promote`, `triage`, `evict`. Statuses: `pending_review` → `ready` → `triaged`. Also: `monitoring`, `evicted`.

To read current state: parse all lines, key by repo, take last entry. Filter `action != "evict"` for active repos.

## Output

- Per repo: `TRIAGE_GRAPH.md` and `~/.sweep/drip-queue/<owner>-<repo>.jsonl`
- Cross-repo: `SWEEP_GRAPH.md` in the working directory with cross-references between repos
- Punch list: unified view across all repos, sorted by score

## Process

### Phase 0: Preflight

1. `gh auth status` — fail fast on auth issues
2. Read `~/.sweep/repos.jsonl` if it exists. These are the known repos.

### Phase 1: Fan out (concurrent)

Launch everything in parallel. Don't wait for actionable to finish before investigating known repos.

```
# Agent 1: actionable (background)
Agent({
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: "Run /actionable. Find new repos, update repos.jsonl.
           For each new repo, run /review-schema.
           Report additions when done."
})

# Agents 2–N: one per repo, full pipeline (background)
for repo in repos.jsonl:
  Agent({
    subagent_type: "general-purpose",
    run_in_background: true,
    prompt: "Full triage pipeline for <repo> [--dry-run]:
             1. Fork (gh repo fork --clone=false) if not already forked.
             2. Clone to ~/Documents/<repo-name> if not already cloned.
             3. Scan issues: competing PRs, scoring, kill list.
             4. For each actionable issue:
                a. /investigate — read code, find root cause, write fix, create branch.
                b. Test gate — fail on master, pass on fix.
                c. /codex — structural review of the fix.
                d. /bug-hunt — adversarial verification.
             5. Write branch pointer to ~/.sweep/drip-queue/<owner>-<repo>.jsonl.
             6. Update ~/.sweep/repos/<owner>-<repo>/TRIAGE_GRAPH.md with outcomes.
             The branch IS the artifact. No PR descriptions — drip writes those from the diff at push time."
  })
```

Each agent runs the full pipeline end-to-end: scan → investigate → implement → test → review → queue. The output is a branch pointer in the drip queue, not a document. Agents that only produce TRIAGE_GRAPH.md without branches have not completed the pipeline.

Actionable searches for new work while triage agents investigate and implement on existing repos. When actionable finishes and adds new repos, spawn triage agents for them into the same pool.

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

### Phase 4: Qualify (triage agents produce branches, not descriptions)

Triage agents run the full pipeline per item: `/investigate` (read code, find root cause, write fix, create branch) → `/codex` (structural review) → `/bug-hunt` (adversarial verification). The output is a **branch pointer** in the drip queue, not a prose document:

```jsonl
{"repo": "pallets/click", "branch": "fix-3362-hyphens", "issue": 3362, "test_cmd": "pytest tests/test_formatting.py", "worktree": "/Users/junekim/Documents/click", "status": "queued"}
```

The branch is the artifact. It contains the diff, commits, and test changes. Everything downstream reads from it.

**Repo clones live in `~/Documents/`.** Fork the repo on GitHub (`gh repo fork --clone=false`), clone to `~/Documents/<repo-name>`, create the fix branch. This is where the code lives — the branch pointer in the drip queue references this local path.

### Phase 5: Quality gates (dry-run runs everything except push)

Dry-run produces mergeable PRs locally. Every gate below runs in both modes — only the push at the end is a remote side effect. The output of dry-run is a local branch in `~/Documents/<repo>` that's ready to push and PR.

For each branch pointer in `~/.sweep/drip-queue/<owner>-<repo>.jsonl`:

1. **Staleness check.** Verify the issue is still open. Check for competing PRs that landed since triage.
2. **Test gate.** Checkout default branch, run test — must fail. Checkout fix branch, run test — must pass.
3. **PR description.** Generate from the real diff + issue context. Tone-match against 5 recent merged PRs from the repo.
4. **Gemini volley.** Send diff + generated PR description + issue link to `/gemini`: "You are a maintainer seeing this for the first time. Would you merge it?" Five rounds max. Gemini is best at tracing logic and catching scope issues.
5. **Codex crosscheck.** Shuffle the generated description into a lineup of 5 real merged PR descriptions. Send to `/codex`: "One may be AI-generated. Which ones, and why?" Codex (GPT-5.5) is the best performer at AI-likeness detection among SOTA models. If identified, rewrite tells only (no checklist). Re-shuffle, re-test. Five rounds max. If still detectable: surface to the human.
6. **Push** (full run only). `git push`, `gh pr create`. In dry-run, log what would be pushed and stop.

PR descriptions are a **drip concern**, not a triage concern. Triage produces branches. Drip generates descriptions from diffs at push time.

For full runs, load drip queues per repo. Each repo gets its own independent drip cadence. One open PR per repo at a time.

### Phase 5: Heartbeat

After all phases complete, set up a recurring wake-up to keep the pipeline alive:

```
CronCreate({
  cron: "*/5 * * * *",
  prompt: "/sweep --check --dry-run. Eviction checks. Spawn agents for repos with TRIAGE_GRAPH.md but no drip queue branch (stalled pipelines). Run quality gates on queued branches. Advance drip queue.",
  recurring: true
})
```

Pass the same flags from the original invocation into the heartbeat prompt — including `--dry-run` if set. **Always create the heartbeat, even in dry-run.** Dry-run still needs the pipeline to keep cooking — checking agent progress, collecting results, writing readiness records. The only thing dry-run skips is remote side effects (no PRs, no pushes). The heartbeat is local.

**The heartbeat checks for incomplete pipelines.** On each tick:
1. Eviction checks (before anything else).
2. For repos with TRIAGE_GRAPH.md but no branch pointer in the drip queue: the pipeline stalled at triage. Spawn a new agent to run the full pipeline (fork → clone → investigate → implement → test → review → queue).
3. For repos with queued branches: run quality gates (staleness, test, Gemini volley, codex crosscheck).
4. For repos with fully qualified branches: in dry-run, log what would push. In full run, push via drip.

A repo with a TRIAGE_GRAPH.md but no branch is an incomplete pipeline — the agent reported findings but didn't implement fixes.

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

**Eviction means:** status → `evicted` in `repos.jsonl`. Drip queue drains (don't abandon open PRs). State files kept for reference. Repo can be re-added with `--add`.

**Competing-PR eviction:** If the only actionable issue on a repo has a competing open PR, and the repo has no other items, demote to `monitoring`. Don't evict — the competing PR might stall.

**Apply now.** On each `--check` tick, scan `repos.jsonl` for eviction triggers before doing anything else. Log evictions to `~/.sweep/actionable/candidates.jsonl`.

## Rules

- **Never ask the user.** Sweep runs autonomously. If you have a hunch, act on it. If you're uncertain, skip it and move on. Log what you skipped and why. The user reads the punch list at the end, not a questionnaire in the middle.
- **One triage per repo.** Never mix repos in a single triage run.
- **Cross-pollinate, don't duplicate.** If two repos share a finding, write the cross-reference. Don't investigate the same thing twice.
- **Independent drip queues.** Each repo has its own pacing. Getting banned from one repo doesn't affect the others.
- **Idempotent.** Running sweep twice skips repos whose triage is already complete (TRIAGE_GRAPH.md exists with all outcomes filled).
- **Auth first.** Verify access to every repo before launching any agents.
- **All PRs route through /drip.** No direct `gh pr create` during active pipeline runs. 14 manual PRs in 2 days triggered a ban warning. The drip queue exists to prevent this — enforce it.
- **Never recommend closing a stale PR.** No-review age is a signal to ping, rebase, or break up — not to close. Closing destroys optionality. Only recommend closing when a maintainer explicitly rejects it or the approach is superseded by another merged PR.
