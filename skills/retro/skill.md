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
| Logs from any subset of pipeline skills | Per-repo hypothesis graphs, memory entries, parameter files, skill patches | Yes — lessons from whatever logs exist |

**Identity:** retro on a repo with no local logs and no GitHub PR history (own or others') is a no-op. Prior art search may run but produces an empty graph if the repo has no closed PRs.

**Composition:** `retro(A) + retro(B) = retro(A ∪ B)` — parameter files are last-value-wins per key, memories dedup by topic, skill patches are idempotent edits. Hypothesis graphs are per-repo and keyed by PR number: re-running retro on the same repo updates existing entries (idempotent per PR) and appends new ones. Prior art entries are keyed by `PR#contributor` to prevent duplicates across passes.

**Standalone use:** Run `/retro <repo>` with only `gh` access. No triage graph, no drip queue, no sweep state required. With zero local logs, retro still produces a hypothesis graph from prior art (other contributors' outcomes) and pre-registrations (predictions for queued fixes). The minimum useful retro is prior art + pre-registration — no own outcomes needed.

## What it reads

Every skill in the pipeline emits logs. `/retro` reads them all:

| Skill | Log location | What to look for |
|-------|-------------|-----------------|
| `/sweep` | `~/.sweep/SWEEP_LOG.md` + `~/.sweep/repos.jsonl` | Repos added/evicted, PRs pushed/merged/closed, agent failures, concurrency, model split changes, cross-repo findings |
| `/triage` | `TRIAGE_GRAPH.md` + worklog | Items scored, killed, investigated. Kill reasons. |
| `/investigate` | `HYPOTHESIS_GRAPH.md` + worklog | Hypotheses classified, perturbations run, CI results, trajectory shapes |
| `/drip` | `~/.sweep/drip-queue/<owner>-<repo>.jsonl` + worklog | PRs pushed, merged, rejected, timing |
| GitHub (own) | `gh pr list --author @me --state all` | Reviewer comments, merge/close reasons, time to response |
| GitHub (prior art) | `gh search prs --repo OWNER/REPO --state closed` | Other contributors' rejections, merge patterns, maintainer language. Base rates for H0-H6 before you submit. |

Also reads: memory files (existing lessons), skill definitions (current parameters).

## What it writes

Four kinds of durable artifacts, in decreasing volatility:

### 0. Per-repo hypothesis graph (the primary output)

Written to `~/.sweep/repos/<owner>-<repo>/RETRO_GRAPH.md`. One graph per repo, updated on each retro pass. This is retro's main job: explain *why* each PR merged or didn't, linked to the meta-hypotheses from the [blog post](/sweep-and-triage).

The meta-hypotheses (from the pipeline's own hypothesis graph):

```
H0: Issue-first PRs merge at higher rate than unsolicited
H1: Review schema conformance predicts merge outcome
H2: Standing is a gate that supersedes technical quality
H3: Drip pacing prevents standing damage
H4: Framing affects outcome independently of code quality
H5: Maintainers optimize for review efficiency, not correctness
H6: The pipeline produces higher merge rates than ad-hoc
```

For each PR outcome, classify which hypotheses it provides evidence for or against:

```markdown
# Retro Graph: owner/repo

## PR #N — title (MERGED|CLOSED|OPEN)

| Hypothesis | Evidence | Direction |
|------------|----------|-----------|
| H0 (issue-first) | PR addressed #123, maintainer-filed | FOR |
| H1 (schema) | net deletion, tests included | FOR |
| H2 (standing) | first PR to repo, no prior relationship | NEUTRAL |
| H5 (efficiency) | 2 lines, merged in 56s | FOR |

Reviewer quote: "Cool!"
```

Each PR is a data point. Each repo accumulates a trajectory. Cross-repo, the meta-graph aggregates: how many FOR vs AGAINST per hypothesis, across how many repos. This is what tells us whether the pipeline works — not merge count, but *which hypotheses the outcomes confirm or falsify.*

**New repos with no PR outcomes yet:** write a pre-registration. What does the hypothesis graph predict will happen when the first PR ships? Which hypotheses are being tested? What would falsify them?

```markdown
## Pre-registration: ruff #16519 (not yet shipped)

Predictions:
- H0: issue-first (maintainer-labeled). Predict: merge rate > unsolicited baseline.
- H1: schema conformance unknown (first contribution, no review schema yet).
- H2: standing = zero. Predict: no standing gate if fix is small.
- H5: 5 lines, mechanical regex addition. Predict: fast review if reviewer trusts the pattern.

Falsification: PR rejected despite issue-first + small diff + collaborator endorsement.
```

The pre-registration makes the test explicit before the outcome is known. Retro then updates it with what actually happened.

**Prior art (other contributors' outcomes):** Before writing pre-registrations, search the repo for other contributors' PR outcomes that provide evidence for H0-H6. Other people already ran the experiments. Their rejections and merges are public data.

```bash
# Find maintainer rejection patterns
gh search prs --repo OWNER/REPO --state closed --sort created --limit 20 \
  --json number,title,author,comments,closedAt

# Search for explicit rejection language
gh api "repos/OWNER/REPO/pulls?state=closed&per_page=30" \
  --jq '.[].number' | while read n; do
  gh api "repos/OWNER/REPO/pulls/$n/comments" \
    --jq '.[].body' 2>/dev/null
done | grep -i "slop\|AI\|ban\|reject\|close\|not reading\|low quality"
```

Classify others' outcomes the same way as your own:

```markdown
## Prior art (other contributors)

### PR #15491 by contributor-X (CLOSED)
Title: 29% scheduling speedup (+46/-18)
Reviewer: "DO NOT SUBMIT AI SLOP"
| H2 (standing) | new contributor, no prior merges | FOR |
| H4 (framing) | benchmarked, tests passing, but AI-detectable prose | FOR |
| H5 (efficiency) | +46 lines, requires context to review | FOR |

### PR #15576 by contributor-Y (MERGED)
Title: +3/-3 fix
Reviewer: "lol early AI wrote those tests, but since there's tests, merged"
| H1 (schema) | +3/-3, tests included | FOR |
| H4 (framing) | AI-written but small enough to not trigger | FOR |
| H5 (efficiency) | 3 lines, trivially verifiable | FOR |
```

Prior art establishes the repo's base rates before you submit anything. Pre-registrations then predict against those base rates: "This repo rejects AI-detectable prose at 80%+ (N=4 prior rejections). Our fix is 5 lines with no prose. Predict: framing gate does not fire."


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

**Scope limit.** Retro may only edit pipeline skills:
- `skills/actionable/skill.md`
- `skills/sweep/skill.md`
- `skills/triage/skill.md`
- `skills/investigate/skill.md`
- `skills/drip/skill.md`
- `skills/retro/skill.md`
- `skills/dashboard/skill.md`
- `skills/MANIFEST.md`

All other skills (copyedit, humanize, codex, gemini, design, etc.) are off-limits. If a lesson applies to a non-pipeline skill, log it to the worklog for human review.

Examples from prior sessions:
- Added "fail on master, pass with fix" rule to `/investigate`, `/triage`, `/drip`
- Added kill list to `/triage`
- Added tone matching to `/drip`
- Added auth preflight to `/drip`
- Competing-PR check moved to step 0 of triage (before scoring, not after investigation)
- "Good first issue" penalty added to scoring (fast claimers race you)
- Fix-ready fast-path: retro `fix_ready` entries skip triage investigation, go straight to drip
- Three-tier polling (hot/warm/cold) based on review speed
- Merge ceiling as scoring signal and kill signal
- Prior failed PRs read before investigation (graveyard is prior art)
- Fork-only push rule made explicit in drip
- `repos.json` → `repos.jsonl` (append-only, monoidal contract)

## Process

1. **Gather logs.** Read worklog, triage graphs, hypothesis graphs, drip queues, and GitHub PR outcomes since `--since` date.

2. **Classify outcomes.** For each PR or investigation:
   - Merged: extract what worked (format, timing, scope, test style)
   - Rejected: extract the reviewer's objection (verbatim if possible)
   - Ignored: note the timing and scope
   - Banned/warned: extract the exact quote and trigger

3. **Build per-repo hypothesis graphs.** For each repo with PR outcomes:
   - Create or update `~/.sweep/repos/<owner>-<repo>/RETRO_GRAPH.md`
   - For each PR, classify evidence for/against H0-H6
   - For repos with no outcomes yet, write pre-registrations for queued fixes
   - Cross-reference: does this repo's evidence change the aggregate picture?

4. **Diff against existing parameters.** What changed since the last retro? If merge rate dropped, why? If a new category appeared in the kill list, what triggered it?

5. **Triage findings into obvious vs ambiguous.**

   **Obvious** (fold immediately):
   - A pattern that appeared 3+ times across repos → skill patch
   - A confirmed fix with reproducer → `fix_ready` entry in retro JSONL, triage fast-paths it to drip
   - A competing-PR catch → update the skip list
   - A kill-list addition with clear evidence → add to triage kill list
   - A parameter update with measured data → write to retro JSONL

   **Ambiguous** (stash for human):
   - A pattern that appeared once — could be noise
   - A finding that contradicts an existing rule
   - A lesson that would change the pipeline's risk profile (e.g. "skip the lineup")
   - Anything that requires judgment about tradeoffs between competing goals

   Obvious findings get folded into skills or parameter files in the same retro pass. Ambiguous findings get logged to the worklog with tag `[AMBIGUOUS]` and a one-line description of the tension. The human reviews ambiguous items and either promotes them to obvious or dismisses them.

6. **Compress obvious findings into artifacts.**
   - Per-repo hypothesis evidence → `RETRO_GRAPH.md`
   - Cross-session lessons → memory entries
   - Repo-specific parameters → parameter files (including `fix_ready` entries)
   - Operational changes → skill definition patches

7. **Log the retro itself.** Append to worklog: what was read, what was written, what changed, what was stashed as ambiguous. The retro is itself a loggable event.

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
