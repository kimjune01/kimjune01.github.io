---
name: discover
description: Feed repos into sweep. Reads retro parameters, scores active repos, finds new ones. Closes the retro → sweep loop.
argument-hint: [--dry-run]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Discover

Read retro parameters. Decide which repos to sweep next. Write `repos.json`.

## The loop

```
discover → sweep → triage → investigate → drip → retro
    ↑                                              │
    └──────────────── lessons ─────────────────────┘
```

## Process

1. Read `/tmp/sweep/repos.json` and `/tmp/retro/*.jsonl`.
2. Score active repos. Drop dormant ones. Respect cooldowns.
3. Look for new repos — contributed repos, adjacent repos, GitHub search. Use retro's data to guide what "good" looks like.
4. Write updated `repos.json`. Log additions and removals to `/tmp/discover/candidates.jsonl`.

## Rules

- **Respect cooldowns.** If retro says cooldown, don't add the repo.
- **Cap at 10 active repos.** The human needs to be able to review drip output.
- **Cold discovery needs human approval.** Repos the agent hasn't touched before get `pending_review`.
- **`--dry-run`** reports changes without writing.
- **Run daily.** `/loop 24h /discover`.
