---
name: actionable
description: Find work worth doing. Starts from issues, not repos — finds maintainer-acknowledged problems with mechanical acceptance criteria. Reads retro parameters to score active repos and expand from what works.
argument-hint: [--dry-run]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Actionable

Find work worth doing. Start from issues, not repos.

## What makes a good candidate

An issue where:
1. **Maintainer acknowledged it** — they commented, labeled it, or opened it themselves
2. **Acceptance criteria are mechanical** — a test fails, a benchmark regresses, a conformance suite has a gap
3. **Nobody's working on it** — no assigned contributor, no open PR addressing it
4. **The repo has a harness** — CI + bench that gives a definitive yes/no before you submit
5. **Estimated fix fits the merge ceiling** — check the repo's merged PR size distribution (from review schema or retro). If the median external merge is ~30 lines and the fix looks like 500+, score it down hard. Prior PRs at 10-50x the merge ceiling don't land regardless of quality.

The ideal issue is a maintainer-acknowledged bug with a reproducer, sitting for months because it's hard. The maintainer pre-committed when they said "PRs welcome." You're claiming work from a queue, not pitching.

## Sources

Only other people's repos. Never your own — you don't need a pipeline to work on your own code.

### 1. Repos you've already contributed to

```
gh api graphql -f query='{ viewer { contributionsCollection { pullRequestContributions(first: 100) { nodes { pullRequest { repository { nameWithOwner } } } } } } }'
```

Filter: not owned by you, still active, has open issues, not on cooldown. You have context, the maintainer knows your name.

### 2. Adjacent repos (expand from what works)

For repos with high merge rates, check the same org, same dependency graph, same topic tags. Retro says what "good" looks like — actionable finds more of it.

### 3. Cold search

```
gh search issues --label "help wanted" --language <lang> --sort created
```

Use topics and languages from high-merge repos. Score by issue quality, not repo familiarity.

**Cold search limitations (retro 2026-05-09):** Generic keyword trawling (`help wanted` + language) fails for compiler/optimizer niches — 10 agents across 2 rounds yielded zero candidates. The skillset (graph rewrite, dtype handling, AST manipulation) is too narrow for generic labels. **Prefer targeted monitoring** of specific repos (ruff, pyright, cuelang, zig) over keyword searches. Adjacent-repo expansion from high-merge orgs (e.g., withastro org → prettier-plugin-astro) produces better candidates than cold search.

## What to skip

- Issues with no maintainer response — until they engage, you don't know if they want it fixed
- Issues with active discussion or assigned contributors — someone's on it
- **Issues with an existing open PR** — always run `gh pr list --repo OWNER/REPO --search "KEYWORD" --state open` before scoring. If a PR exists and was updated in the last 30 days, skip. If stale (>30 days, no reviews), note as opportunity to pick up the stalled work. Retro 2026-05-09: gemini-cli #25693 and #25689 both had competing PRs (#25728, #25729) that triage agents discovered only after full investigation.
- Feature requests with no maintainer endorsement — inventing problems
- Issues that need hardware you don't have — can't verify
- **Fix exceeds merge ceiling** — if the estimated diff is >3x the repo's median merged PR size for external contributors, skip. A 2000-line feature on a repo that merges 30-line fixes is dead on arrival.
- **Repos with `process_depth: shallow`** in their review schema — the pipeline produces investigation-backed PRs. Shallow-review repos can't absorb them. Only add shallow repos if the issue is trivial enough that investigation depth is unnecessary (1-line fix, obvious bug, failing test with known cause).

## Output

Updated `~/.sweep/repos.jsonl`. Log additions and removals to `~/.sweep/actionable/candidates.jsonl`.

**Dashboard reminder:** after every tick, remind the user to check the dashboard at `http://localhost:8321/`.

## Diversity selection

Don't just rank by quality and take the top-k. That clusters — you'd end up with 10 Python ML repos. The pipeline learns faster from diverse repos than correlated ones.

After scoring candidates, select the final set using DPP-style diversity. Each candidate repo gets a feature vector:

| Feature | Why it matters |
|---|---|
| Language | different toolchains, different review norms |
| Domain | ML, systems, web, infra, devtools |
| Process depth | mix of shallow and deep tests different hypotheses |
| Org size | solo maintainer vs large team, different dynamics |
| Issue type | bugs, perf, correctness, docs |

**Selection:** parallel with noise. Each agent scores candidates independently, then jitters each score before ranking:

```bash
jitter=$(python3 -c "import random; print(random.uniform(0.7, 1.3))")
jittered_score=$(python3 -c "print($score * $jitter)")
```

LLMs can't generate real randomness — use the shell. The noise prevents convergence: five agents with the same scoring function pick five different repos because each sees a different permutation of the ranking. Dedup at the sweep level: if two agents pick the same repo, one re-rolls.

No central coordinator. No partitioning. Just jittered scores and a dedup pass.

The result: diverse repos without a bottleneck. The noise does what DPP's repulsion kernel does, cheaper.

## Standing-gated bug hunt

When standing is high enough on a repo (3+ merged PRs, no warnings, no cooldown), the pipeline unlocks a new mode: run `/bug-hunt` on the repo blind — no issue required. Find bugs the maintainer doesn't know about, open the issue yourself, fix it yourself.

This is the endgame. The issue is your hypothesis. The PR is your fix. Your standing means the maintainer trusts your judgment about what's worth fixing.

**Threshold:** 3+ merged PRs on the repo, no active cooldown, no warnings in retro log. Check via drip queue history.

**Process:** spawn a `/bug-hunt` agent on the repo. If it finds something, open an issue with a reproducer, then file the fix as a separate PR linked to the issue. Same pipeline — issue-first — but you're creating the issue instead of claiming one.

**Risk:** this is exactly what got you banned on tinygrad — finding bugs without standing. The threshold gate prevents that. Don't skip it.

## Process

1. Read `~/.sweep/repos.jsonl` and `~/.sweep/retro/*.jsonl`.
2. Score active repos. Drop dormant ones. Respect cooldowns.
3. For repos above the standing threshold (3+ merges), run standing-gated bug hunt.
4. Search for issues: contributed repos, then adjacent, then cold.
5. Score candidates by issue quality × repo fit.
6. Select final set via diversity selection (quality × distance in feature space).
7. Write updated `repos.jsonl` and `candidates.jsonl`.

## Eviction policy

The roster grows. It shouldn't grow forever. Evict repos that aren't producing value.

**Eviction triggers** (check on every actionable tick):

| Trigger | Threshold | Action |
|---|---|---|
| No activity in 7 days | latest `repos.jsonl` entry for this repo > 7d old, no open PRs, no pending items | re-evaluate; if nothing changed upstream, evict |
| No merged PR in 30 days | last merge > 30d ago | evict |
| All issues KILLED or BLOCKED | zero PENDING or CONFIRMED items | evict |
| Cooldown active with no end date | permanent ban | evict |
| Three consecutive rejections | 3 closed-without-merge in a row | evict |
| Repo archived or deleted upstream | `gh repo view` fails | evict |
| Process depth downgraded to shallow | retro reclassified after rejections | evict |

**Eviction means:** status → `evicted` in `repos.jsonl`. Drip queue drains naturally (don't abandon open PRs). State files kept in `~/.sweep/repos/<owner>-<repo>/` for reference. The repo can be re-added manually with `--add` but doesn't come back automatically.

**Soft eviction (demotion):** repos that aren't evicted but aren't producing get deprioritized. If a repo has open issues but no progress in 14 days, it drops below new candidates in the ranking. It stays on the roster but stops getting agent time until something changes (new issue, maintainer activity, retro parameter update).

## Rules

- **Respect cooldowns.** If retro says cooldown, don't add the repo.
- **Cap at 1000 active repos.** Incremental fetching keeps API cost ~5 calls/repo/tick at steady state. **Stagger:** check 100 repos per tick, round-robin through the roster. Full cycle in 10 ticks (50 minutes at 5-minute heartbeat). Eviction keeps the roster under the cap. If at cap and a better candidate appears, evict the lowest-performing active repo to make room.
- **Never your own repos.** Filter out repos where you are the owner. The pipeline is for contributing to other people's projects.
- **Cold discovery needs human approval.** Repos the agent hasn't touched before get `pending_review`.
- **Issue-first.** Don't add a repo unless there's a specific issue worth investigating. Repos without actionable issues are noise.
- **Mundane is fine.** Doc fixes, error messages, edge case handling — the agent doesn't get bored. Easy merges build contributor trust that makes harder PRs land later. Don't skip "good first issue" just because it's boring.
- **`--dry-run`** reports changes without writing.
