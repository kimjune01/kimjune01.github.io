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

## What to skip

- Issues with no maintainer response — until they engage, you don't know if they want it fixed
- Issues with active discussion or assigned contributors — someone's on it
- Feature requests with no maintainer endorsement — inventing problems
- Issues that need hardware you don't have — can't verify
- **Repos with `process_depth: shallow`** in their review schema — the pipeline produces investigation-backed PRs. Shallow-review repos can't absorb them. Only add shallow repos if the issue is trivial enough that investigation depth is unnecessary (1-line fix, obvious bug, failing test with known cause).

## Output

Updated `~/.sweep/repos.json`. Log additions and removals to `~/.sweep/actionable/candidates.jsonl`.

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

## Process

1. Read `~/.sweep/repos.json` and `~/.sweep/retro/*.jsonl`.
2. Score active repos. Drop dormant ones. Respect cooldowns.
3. Search for issues: contributed repos, then adjacent, then cold.
4. Score candidates by issue quality × repo fit.
5. Select final set via diversity selection (quality × distance in feature space).
6. Write updated `repos.json` and `candidates.jsonl`.

## Rules

- **Respect cooldowns.** If retro says cooldown, don't add the repo.
- **Cap at 10 active repos.** The human needs to be able to review drip output.
- **Never your own repos.** Filter out repos where you are the owner. The pipeline is for contributing to other people's projects.
- **Cold discovery needs human approval.** Repos the agent hasn't touched before get `pending_review`.
- **Issue-first.** Don't add a repo unless there's a specific issue worth investigating. Repos without actionable issues are noise.
- **Mundane is fine.** Doc fixes, error messages, edge case handling — the agent doesn't get bored. Easy merges build contributor trust that makes harder PRs land later. Don't skip "good first issue" just because it's boring.
- **`--dry-run`** reports changes without writing.
