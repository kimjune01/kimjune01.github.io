---
name: triage
description: Scan a repo's open PRs/issues, score by actionability, spawn parallel /investigate agents per item in worktrees. Shared hypothesis graph for dedup. Output is human-gated PRs.
argument-hint: <repo> [--limit N] [--label LABEL] [--dry-run]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Triage: Repo to Human-Gated PRs

Scan a repo's open items, score them, spawn parallel investigations, produce PRs that wait for human approval. The dispatcher understands the investigations — it reads the shared hypothesis graph to cross-pollinate findings and dedup perturbations.

Run `/review-schema` before first use on a new repo. Triage assumes the review culture — gates, signals, tiebreaker — has been profiled. Without the review schema, agents produce PRs that don't match the maintainer's perceive loop.

Run autonomously from scan to punch list. The only human gate is Phase 4 (ship). Everything before it is local and reversible. Don't stop to ask between phases — write state to `TRIAGE_GRAPH.md` and keep going.

## Input

A GitHub repo (owner/name or local path). Optional filters:
- `--limit N` — max items to investigate total (default 20)
- `--concurrency N` — max parallel agents (default 5)
- `--label LABEL` — only items with this label
- `--dry-run` — run the full pipeline (scan, investigate, collect, present) but don't affect any remote. No PRs created, no issues opened, no comments posted, no pushes. Agents still spawn and investigate locally. The output is `TRIAGE_GRAPH.md` with findings, failing tests, and candidate fixes — all local. Remove the flag to ship.

If no repo is given, use the current directory's `origin` remote.

## Output

- **Dry run:** Full pipeline runs locally — scan, investigate, bug-hunt, collect. `TRIAGE_GRAPH.md` with findings, failing tests, candidate fixes. No remote side effects. Readiness records in `~/.sweep/triage-dry-run/`.
- **Full run:** Same as dry run, plus: candidates added to `/drip` queue. Triage never touches remotes directly — `/drip` handles all PR creation and pacing.

Shared artifact: `TRIAGE_GRAPH.md` in the working directory — the unified hypothesis graph across all investigated items. This is the coordination file and the checkpoint for resume.

## Process

### Phase 0: Resume

Before doing anything, check for existing state:

1. Read `TRIAGE_GRAPH.md` if it exists. Parse the scan table and any investigation nodes.
2. Determine which phase to resume from:
   - No file → start at Phase 1
   - Scan table exists but no Status column → Phase 1 complete, resume at Phase 2
   - Items with Status=IN_PROGRESS → agents were interrupted, resume Phase 2 for those items only
   - Items with investigation nodes but no Outcome → resume Phase 3
   - All items have outcomes → resume Phase 4
3. Report what was found: "Resuming from Phase N. X items already classified, Y remaining."

### Phase 0.5: Load retro parameters

Before scoring, check for retro-derived parameters that adjust behavior:

1. Read `~/.sweep/retro/<owner>-<repo>.jsonl` if it exists. Parse last-value-wins per key.
2. Apply overrides to scoring and behavior:
   - `scoring.maintainer_filed_bonus` → adjusts maintainer-filed issue score
   - `scoring.skip_categories` → extends the kill list
   - `cooldown_until` → if today < cooldown date, halt with "Cooldown active until {date}"
   - `merge_rate` → informs pacing expectations (logged, not enforced)
3. Log which parameters were loaded. If no retro file exists, proceed with defaults.

### Phase 1: Scan

1. Fetch open PRs and issues. Check `repos.jsonl` for `last_fetched` timestamp. On first scan, fetch everything. On re-scan, use `--search "updated:>YYYY-MM-DD"` to pull only items with new activity:
   - `gh pr list --repo <repo> --state open --search "updated:>YYYY-MM-DD" --json number,title,author,labels,reviewDecision,statusCheckRollup,comments,updatedAt,isDraft`
   - `gh issue list --repo <repo> --state open --limit 100 --json number,title,author,labels,comments,updatedAt`
   Update `last_fetched` in `repos.jsonl` after each scan.

2. Identify the current user: `gh api user --jq .login`

3. Score each item by actionability. An item can match multiple signals — use the highest:

| Signal | Score | Rationale |
|--------|-------|-----------|
| CI failing on your PR | 10 | Blocking — fix before review |
| Reviewer commented with requested changes | 8 | Someone spent time; respond |
| Maintainer commented on your item | 7 | Engagement from someone with merge power |
| LGTM but needs rebase/update | 6 | Low effort to unblock |
| Your PR, no activity > 3 days | 4 | Might need a ping or update |
| Open issue you filed | 3 | Your problem to solve |
| Open issue, filed by maintainer | 2+ | Signal: they want this done. Bonus if labeled "good first issue" |
| Open issue, unassigned | 2 | Opportunity |
| Your PR, CI passing, under review | 1 | Nothing to do — wait |

4. **Kill list.** Before scoring, reject items that will never produce a mergeable PR. Don't spend agent time on these:

| Kill signal | Reason |
|-------------|--------|
| Needs hardware you don't own and CI doesn't have | Can't reproduce, can't verify |
| Feature request with no maintainer endorsement | Inventing problems, not solving them |
| Design proposal / TIP (unless you're a core contributor) | Architecture decisions belong to maintainers |
| Vague issue, no repro steps, no error message | Nothing to test against |
| Already fixed on master | Verify first, close if true |
| Someone else has an open PR for it | Don't compete, link to theirs |
| Milestone / tracking issue | Not a bug, not actionable |
| You got banned or warned on this repo | Cooldown active (check retro parameters) |
| Heuristic / performance tuning without device-diverse CI | Can't validate across hardware. geohot: "no on all heuristic changes" |
| Net-addition performance optimization | "We never trade complexity for speed." Only perf work that deletes lines |
| Requires pre-discussion or design alignment | Politics. If the fix isn't obvious from the issue, skip it |
| Requires off-platform communication (Discord, mailing list, etc.) | Pipeline only speaks GitHub. If the contribution process routes through another channel, skip the repo |

Mark killed items as `SKIP` in the scan table with the reason. They don't enter Phase 2.

5. Categorize remaining items into groups:
   - **Your items** — PRs and issues you authored
   - **Software bugs** — reproducible without specific hardware (testable locally or on NULL device)
   - **Maintainer-filed** — issues filed by repo owners/maintainers (signal: they want these done)
   - **Stale/vague** — old but might have a clear repro buried in the comments

5. For software bugs, assess reproducibility:
   - Read the issue body for repro steps
   - Note if it needs specific hardware, specific backend, or runs on NULL/CPU
   - Flag cross-references: issues that share root causes or affect the same code

6. Write `TRIAGE_GRAPH.md` with:
   - Scored scan table per category
   - Cross-references between related items
   - Recommended investigation order (prioritize: reproducible locally > correctness > maintainer filed > stale = forgotten = opportunity)

7. **Gemini volley.** Send the scan table and kill decisions to `/gemini`: "Review these triage decisions. Any items killed that should be investigated? Any items kept that are a waste of time? Any cross-references missed?" Apply feedback, re-send. Five rounds max.

8. Proceed to Phase 2.

### Phase 2: Investigate (parallel)

**Resume check:** Read `TRIAGE_GRAPH.md`. Skip items marked CONFIRMED, KILLED, BLOCKED, or SHIPPED. Only spawn agents for PENDING or IN_PROGRESS items.

Use a worker pool with `--concurrency` slots (default 5). The pool processes items from the ranked list up to `--limit` total.

1. **Launch initial batch.** Spawn up to `--concurrency` agents in parallel from the top of the ranked list. Each agent gets a worktree.

2. **Build context per agent.** For each item, gather:
   - PR diff or issue body (full text, not summary)
   - CI failure logs (if applicable)
   - Review comments
   - Related nodes in `TRIAGE_GRAPH.md` (dedup check)
   - Cross-referenced items from Phase 1
   - **Prior failed PRs.** Search `gh pr list --repo <repo> --search "<issue-number>" --state closed`. For each closed PR that addressed this issue, read the diff and review comments. These are free signal: what approach was tried, what the maintainer rejected, what was too large or wrong-direction. Three failed PRs on the same issue means three mapped failure modes. The fourth attempt should avoid all three.

3. **Spawn agent.**

   ```
   Agent({
     subagent_type: "general-purpose",
     isolation: "worktree",
     run_in_background: true,
     prompt: "Run /investigate on [item]. Read TRIAGE_GRAPH.md for context.
              [context]. After investigation, run /bug-hunt on any candidate fix.
              Write YOUR results to TRIAGE_RESULT.T<number>.md (not TRIAGE_GRAPH.md).
              Test before fix: write a failing test first, then the fix."
   })
   ```

   Each agent writes to its own result file (`TRIAGE_RESULT.T<number>.md`) — never to the shared `TRIAGE_GRAPH.md`. This prevents parallel write conflicts. Phase 3 merges results into the graph.

   Each agent's prompt includes:
   - The item's full context (diff, CI logs, comments)
   - A snapshot of `TRIAGE_GRAPH.md` at spawn time (read-only context, not a write target)
   - Instructions to run the full pipeline: `/investigate` → `/codex` review → `/bug-hunt` → readiness record
   - The test-before-fix rule

4. **Refill on completion.** When an agent finishes, merge its `TRIAGE_RESULT.T<number>.md` into `TRIAGE_GRAPH.md`, then immediately launch the next PENDING item from the ranked list into the freed slot. The pool stays at `--concurrency` until `--limit` is reached or the list is exhausted. Each new agent gets the latest merged graph state, including findings from agents that just completed (cross-pollination for free).

5. **Dedup rule.** Before designing a perturbation, the agent reads `TRIAGE_GRAPH.md` and checks: is there a node with the same hypothesis already classified? If yes, cite it and skip. If the node is from a different item, that's cross-pollination.

6. **Update status.** As each agent starts, mark its item IN_PROGRESS. When it finishes, mark CONFIRMED, KILLED, or BLOCKED. Write to `TRIAGE_GRAPH.md` immediately on every transition.

### Phase 3: Collect

**Resume check:** Read `TRIAGE_GRAPH.md`. Items with investigation nodes but no Outcome need collection. Items already collected are skipped.

As agents complete:

1. Read each agent's result file (`TRIAGE_RESULT.T<number>.md`).
2. Merge into `TRIAGE_GRAPH.md`. Each result file maps to a distinct T<number> section, so merges are conflict-free. Delete result files after merging.
3. For each item that produced a candidate fix:
   - Verify the agent ran `/codex` (structural review)
   - Verify the agent ran `/bug-hunt` (adversarial verification)
   - If either was skipped, run it now on the candidate fix
4. Update the scan table with status and outcome:

```markdown
| # | Score | Title | Signal | Status | Outcome |
|---|-------|-------|--------|--------|---------|
| 6909 | 2 | bf16 autocast | Maintainer filed | CONFIRMED | Failing test + fix ready |
| 12296 | 2 | max backward underflow | Correctness bug | KILLED | Not reproducible on current master |
| 13409 | 2 | ScatterND infinite loop | Stale bug | IN_PROGRESS | Agent investigating |
```

### Phase 4: Present

**Resume check:** If the scan table already has outcomes for all items and a punch list exists at the end of `TRIAGE_GRAPH.md`, present it. Otherwise, generate from current state.

For each candidate, write a readiness record to `~/.sweep/triage-dry-run/<number>-pr.md`:
- Branch name
- Base commit (master SHA at time of investigation)
- Test command that fails on base: `python3 -m pytest <test> -k <name>`
- Test command that passes on branch
- Verified: fail on master, pass with fix (both checked locally)
- Files changed
- PR title and body (draft — `/drip` handles tone matching before creation)

Triage never creates PRs, opens issues, or pushes branches. It produces candidates. `/drip` handles all remote operations.

Surface only what needs human attention:

1. **Ready to ship** — failing tests + fixes ready, codex clean, bug-hunt converged. Readiness record written. In full run: add to drip queue.
2. **Blocked** — items that need human judgment (architectural decision, maintainer relationship, ambiguous requirement).
3. **No action needed** — items where the investigation found nothing to do (CI passing, no comments, under review).

Format as a punch list, not a report. One line per item, action verb first.

### Phase 5: Drip (full run only)

**Skip if `--dry-run`.**

For each "ready to ship" item, add it to the `/drip` queue:

1. Write the PR description to `~/.sweep/triage-dry-run/<number>-pr.md` (same as dry run).
2. Add the entry to `~/.sweep/drip-queue/<owner>-<repo>.jsonl` with the branch, title, body, and status `queued`.
3. Run `/drip --check` to push the first item if no open PRs exist.

The drip queue handles pacing from here. One PR at a time, 15-minute heartbeat, tone-matched to the repo. Triage's job is done when the queue is loaded.

## Coordination via TRIAGE_GRAPH.md

The graph file is the shared state. Convention:

- **Node IDs:** `T<issue_number>.H<hypothesis_number>` (e.g., `T16107.H0.6a`)
- **Cross-references:** When one investigation's finding affects another, add an edge: `T16109.H0 → T16107.H0.6a (same root cause)`
- **Statuses:** PENDING, IN_PROGRESS, CONFIRMED, KILLED, BLOCKED, SHIPPED, SKIP. Use these exact strings in the scan table's Status column and section headers — the dashboard parses them. Don't use OPEN/CLOSED/other variants. Items we're not acting on (hardware-only, external PRs, tracking issues, stale) get SKIP, not PENDING.
- **Concurrency:** Agents write to per-item result files (`TRIAGE_RESULT.T<number>.md`), never to the shared graph. Phase 3 merges results into `TRIAGE_GRAPH.md` sequentially. No concurrent writes.

No database. No service. The file is the data structure.

## Rules

- **Never merge.** Triage produces draft PRs. The human ships.
- **Run autonomously.** Don't stop between phases to ask. Write state to the graph file and keep going. The human can redirect at any time — the graph is always readable.
- **Score before investigating.** Don't waste agent time on items that score 1 (nothing to do).
- **Cross-pollinate.** If agent A discovers something that affects agent B's item, write it to the graph. Agent B reads it before its next perturbation.
- **Full pipeline per item.** Every candidate fix must pass through `/codex` (structural) and `/bug-hunt` (adversarial) before being presented. No shortcuts.
- **CI is a perturbation surface.** In full run, agents can push draft PRs to trigger CI on hardware they don't own. In dry run, agents investigate locally only — no pushes, no CI. Test what you can on NULL/CPU/local GPU; note what needs CI validation in the graph.
- **Graph-first on new evidence.** Write to `TRIAGE_GRAPH.md` before doing anything else when new evidence arrives.
- **Fail fast.** If an item's investigation hits depth 3 with no progress (all hypotheses killed, no new edges), mark it BLOCKED and move on.
- **Fail on master, pass with fix.** Every candidate must satisfy: test fails on master, test passes with the fix. Verify both locally before adding to the drip queue. This is the assertion every PR makes. A test that passes on master proves nothing.
- **Idempotent.** Running triage twice produces the same output. Every phase checks existing state before acting. Completed work is never redone.
