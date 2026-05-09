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

**Preconditions:** `/review-schema` per repo (checked in Phase 0, interactive).

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

### Phase -1: Discover

Run `/actionable`. Read retro parameters, score active repos, find new candidates, update `repos.json`. This is what closes the loop — retro's lessons feed back into which repos get swept next. Skip if `repos.json` was provided explicitly via argument. In `--dry-run`, actionable reports changes without writing.

Also re-run actionable between phases if active work runs low: fewer than 3 PENDING items across all repos triggers a mid-sweep pass to refill the queue.

### Phase 0: Preflight

1. `gh auth status` — fail fast on auth issues
2. For each repo in `repos.json`, verify access: `gh repo view <repo> --json name`
3. For each repo, check if `/review-schema` has been completed (look for `~/.sweep/repos/<owner>-<repo>/review-schema.md`). If missing, run `/review-schema` for that repo — this induces the review culture from PR history, then validates with the user. Run review-schema **serially**, one repo at a time, since each requires user validation. Do not fan out triage until all repos have a review schema.

### Phase 1: Fan out

Launch one `/triage` agent per repo, in parallel:

```
Agent({
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: "Run /triage [--dry-run] --limit N on <repo>.
           Write results to <repo-dir>/TRIAGE_GRAPH.md.
           When done, write a one-line summary per item to stdout."
})
```

Each agent runs in its own working directory (`~/.sweep/repos/<owner>-<repo>/`). No worktree needed since triage creates its own worktrees for investigations.

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

## Rules

- **One triage per repo.** Never mix repos in a single triage run.
- **Cross-pollinate, don't duplicate.** If two repos share a finding, write the cross-reference. Don't investigate the same thing twice.
- **Independent drip queues.** Each repo has its own pacing. Getting banned from one repo doesn't affect the others.
- **Idempotent.** Running sweep twice skips repos whose triage is already complete (TRIAGE_GRAPH.md exists with all outcomes filled).
- **Auth first.** Verify access to every repo before launching any agents.
