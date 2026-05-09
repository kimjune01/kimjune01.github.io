# Pipeline Manifest

Canonical paths, schemas, and side-effect policy for the skill pipeline.

## Canonical paths

| Artifact | Path | Format | Owner (writes) | Readers |
|----------|------|--------|----------------|---------|
| Drip queue | `~/.sweep/drip-queue/<owner>-<repo>.jsonl` | JSONL, append-only | triage (enqueue), drip (status transitions) | drip, retro |
| Retro parameters | `~/.sweep/retro/<owner>-<repo>.jsonl` | JSONL, append-only, last-value-wins per key | retro | triage, drip |
| Structured event log | `~/.sweep/sweep-log/<owner>-<repo>.jsonl` | JSONL, append-only | triage, investigate, drip, sweep | retro |
| Sweep repo list | `~/.sweep/repos.json` | JSON (single object) | actionable, sweep | actionable, sweep, dashboard |
| Discovery candidates | `~/.sweep/actionable/candidates.jsonl` | JSONL, append-only | actionable | retro |
| Per-repo sweep dir | `~/.sweep/repos/<owner>-<repo>/` | directory | sweep, triage | sweep, retro |
| Triage graph | `TRIAGE_GRAPH.md` (working dir) | Markdown | triage (Phase 3 merge) | triage, investigate, retro |
| Per-agent results | `TRIAGE_RESULT.T<number>.md` (worktree) | Markdown | investigate (per-agent) | triage (Phase 3, then deleted) |
| Hypothesis graph | `HYPOTHESIS_GRAPH.md` (working dir) | Markdown | investigate | retro |
| Readiness records | `~/.sweep/triage-dry-run/<number>-pr.md` | Markdown | investigate, triage | drip |
| Sweep graph | `SWEEP_GRAPH.md` (working dir) | Markdown | sweep | retro |

## JSONL schemas

### Drip queue entry

```jsonl
{"ts":"ISO8601","action":"enqueue|push|outcome","branch":"str","title":"str","body":"str","status":"queued|open|merged|closed|error|needs_rebase","pr_number":null|int}
```

### Retro parameter entry

```jsonl
{"ts":"ISO8601","key":"dotted.key.name","value":"any","reason":"str"}
```

Known keys: `merge_rate`, `cooldown_until`, `scoring.maintainer_filed_bonus`, `scoring.skip_categories`, `drip.title_format`.

### Structured event log entry

```jsonl
{"ts":"ISO8601","skill":"triage|investigate|drip|sweep","event":"str","repo":"owner/repo",...event-specific fields}
```

Events: `item_scored`, `item_killed`, `agent_spawned`, `hypothesis_classified`, `ci_result`, `pr_pushed`, `pr_outcome`, `tone_rewrite`, `repo_added`, `repo_removed`.

## Side-effect policy

| Skill | Local | Remote |
|-------|-------|--------|
| `/review-schema` | writes review schema to `~/.sweep/repos/<owner>-<repo>/review-schema.md` | none |
| `/triage` | writes `TRIAGE_GRAPH.md`, readiness records, event log | none (dry-run default). Full run: enqueues to drip only |
| `/investigate` | writes `HYPOTHESIS_GRAPH.md`, per-agent results, event log | **standalone**: push + PR (Phase 8, human-gated). **pipeline**: readiness record only |
| `/drip` | writes queue transitions, event log | push branches, create PRs (human-gated or `--push`) |
| `/sweep` | writes `SWEEP_GRAPH.md`, repos.json, event log | none directly. Delegates to triage/drip |
| `/retro` | writes memory entries, parameter files, skill patches, worklog | none |

Only `/drip` and standalone `/investigate` touch remotes. Everything else is local.

## Naming conventions

- **`.jsonl`** for append-only logs, queues, and parameter files (machine-readable, greppable).
- **`.json`** for single-object state files (sweep repos list).
- **`.md`** for human-readable artifacts (graphs, readiness records, blog drafts).
- **`<owner>-<repo>`** for per-repo file/directory names (dash-separated, e.g., `tinygrad-tinygrad`).
