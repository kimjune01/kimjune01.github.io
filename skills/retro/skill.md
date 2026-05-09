---
name: retro
description: Read logs from the pipeline, lossy-compress into durable artifacts. The backward pass that reshapes how the pipeline processes next cycle.
argument-hint: <repo> [--since YYYY-MM-DD]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Retro: Lossy Compression of Logs into Lessons

Read the logs. Compress what happened into what matters. Write it where the pipeline reads it next time.

In the [Natural Framework](/the-natural-framework), Consolidate reads from Transmit and writes to the substrate. The substrate is what persists across cycles: memory files, scoring parameters, skill definitions, the blog. `/retro` is not a live feedback loop. It runs after the cycle, reads the full trail, and extracts the durable signal.

## Monoidal contract

| Input | Output | Valid alone? |
|-------|--------|--------------|
| Logs from any subset of pipeline skills | Memory entries, parameter files, skill patches | Yes — lessons from whatever logs exist |

**Identity:** retro on an empty log set is a no-op. No logs, no lessons, no writes.

**Composition:** `retro(A) + retro(B) = retro(A ∪ B)` — parameter files are last-value-wins per key, memories dedup by topic, skill patches are idempotent edits.

**Standalone use:** Run `/retro <repo>` with only a worklog and `gh pr list` output. No triage graph, no drip queue, no sweep state required. Retro compresses whatever logs it finds.

## What it reads

Every skill in the pipeline emits logs. `/retro` reads them all:

| Skill | Log location | What to look for |
|-------|-------------|-----------------|
| `/sweep` | worklog | Repos added/removed, review-schema decisions |
| `/triage` | `TRIAGE_GRAPH.md` + worklog | Items scored, killed, investigated. Kill reasons. |
| `/investigate` | `HYPOTHESIS_GRAPH.md` + worklog | Hypotheses classified, perturbations run, CI results, trajectory shapes |
| `/drip` | `~/.sweep/drip-queue/<owner>-<repo>.jsonl` + worklog | PRs pushed, merged, rejected, timing |
| GitHub | `gh pr list --author @me --state all` | Reviewer comments, merge/close reasons, time to response |

Also reads: memory files (existing lessons), skill definitions (current parameters).

## What it writes

Three kinds of durable artifacts, in decreasing volatility:

### 1. Memory entries (cross-session)

Lessons that apply to future conversations. Written to the auto-memory system.

- Feedback memories: "fail on master, pass with fix", "one PR at a time", "tone match before push"
- Project memories: "tinygrad bans AI PRs if volume is high", "gemini-cli rmedranollamas is responsive"
- Reference memories: repo locations, token configs, maintainer names

Only write a memory if the lesson transfers across sessions. If it's repo-specific and ephemeral, use a parameter file instead.

### 2. Parameter files (per-repo)

Written to `~/.sweep/retro/<repo>.jsonl`. One object per parameter update, append-only. Read by triage and drip on the next cycle (last value wins per key).

```jsonl
{"ts":"2026-05-09T01:00:00Z","key":"merge_rate","value":0.09,"reason":"1/11 PRs merged"}
{"ts":"2026-05-09T01:00:00Z","key":"cooldown_until","value":"2026-05-22","reason":"ban warning from geohot"}
{"ts":"2026-05-09T01:00:00Z","key":"scoring.maintainer_filed_bonus","value":2,"reason":"maintainer-filed issues merge 3x more"}
{"ts":"2026-05-09T01:00:00Z","key":"scoring.skip_categories","value":["hardware","design_proposals"],"reason":"can't reproduce, can't verify"}
{"ts":"2026-05-09T01:00:00Z","key":"drip.title_format","value":"terse","reason":"matched repo voice from merged PRs"}
```

### 3. Skill definition patches

When a lesson changes how a skill should operate, edit the skill file directly. This is the strongest form of consolidation: the lesson becomes code.

Examples from this session:
- Added "fail on master, pass with fix" rule to `/investigate`, `/triage`, `/drip`
- Added kill list to `/triage`
- Added tone matching to `/drip`
- Added auth preflight to `/drip`

## Process

1. **Gather logs.** Read worklog, triage graphs, hypothesis graphs, drip queues, and GitHub PR outcomes since `--since` date.

2. **Classify outcomes.** For each PR or investigation:
   - Merged: extract what worked (format, timing, scope, test style)
   - Rejected: extract the reviewer's objection (verbatim if possible)
   - Ignored: note the timing and scope
   - Banned/warned: extract the exact quote and trigger

3. **Diff against existing parameters.** What changed since the last retro? If merge rate dropped, why? If a new category appeared in the kill list, what triggered it?

4. **Compress into artifacts.**
   - Cross-session lessons → memory entries
   - Repo-specific parameters → parameter files
   - Operational changes → skill definition patches

5. **Log the retro itself.** Append to worklog: what was read, what was written, what changed. The retro is itself a loggable event.

## Logging contract for upstream skills

Each skill must emit structured log entries at decision points. `/retro` can only consolidate what was logged.

| Event | Who logs |
|-------|----------|
| Item scored | `/triage` |
| Item killed | `/triage` |
| Agent spawned | `/triage` |
| Hypothesis classified | `/investigate` |
| CI result | `/investigate` |
| PR pushed | `/drip` |
| PR outcome | `/drip` |
| Tone rewrite | `/drip` |
| Repo added/removed | `/sweep` |

All structured events append to `~/.sweep/sweep-log/<repo>.jsonl` as one JSON object per line:

```jsonl
{"ts":"2026-05-08T22:30:00Z","skill":"triage","event":"item_killed","repo":"tinygrad/tinygrad","number":16086,"reason":"hardware_only"}
{"ts":"2026-05-08T22:31:00Z","skill":"investigate","event":"hypothesis_classified","node":"T6909.H0","status":"CONFIRMED","trajectory":"divergent"}
{"ts":"2026-05-08T22:45:00Z","skill":"drip","event":"pr_pushed","repo":"tinygrad/tinygrad","number":16116,"branch":"matvec-test-and-fix"}
```

JSONL is appendable, greppable, parseable without loading the whole file. `/retro` reads these directly. Human-readable summaries still go to the worklog via `/log`.

## When to run

- After a PR cycle completes (merged or closed)
- After a ban or warning
- Weekly, as a habit
- Before the next `/sweep` cycle

## Rules

- **Read everything, write little.** The compression ratio is the point. Ten log entries become one memory. A hundred become one parameter file.
- **Don't overfit.** One rejection doesn't change the scoring model. Three rejections for the same reason do.
- **Lessons decay.** Parameter files have a TTL. If no new outcomes in 30 days, reset to defaults.
- **Bans are permanent until manually cleared.** `cooldown_until` prevents the pipeline from pushing to a repo after a warning.
- **The retro is logged.** Every parameter change, every memory written, every skill patched — append to worklog with the outcome that triggered it.
