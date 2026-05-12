---
name: sweep
description: Fan out /triage across multiple repos in parallel. One triage per repo, shared cross-repo findings, unified drip queues.
argument-hint: <repos-file-or-list> [--dry-run] [--limit N] [--pipeline] [--monitor]
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
- `--concurrency N` — max subagents to spawn per pipeline tick (default 10). This is a per-tick spawn cap, not a global concurrent limit — we can't reliably count running subagents from the tick prompt. Stored in `~/.sweep/config.json`.
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
- Sweep log: `~/.sweep/SWEEP_LOG.md` — append-only log of sweep events

## Sweep log

`~/.sweep/SWEEP_LOG.md` is the sweep-specific work log. Same format as `/log` entries (`## date` / `### HH:MM — summary`), but scoped to sweep events only. Append after every meaningful state change:

- PRs pushed, merged, closed, or rejected
- Repos triaged, evicted, or promoted
- Skill updates, concurrency changes, model split changes
- Agent failure patterns (half-finished, batch failures)
- Cross-repo findings

The sweep log lives at `~/.sweep/SWEEP_LOG.md`, not in the repo work log. Sweep events are high-volume and would drown the project work log. The project work log (`worklog/WORK_LOG.md`) gets a summary entry per session, not per tick.

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
  Agent(triage_prompt(repo, denylist=[]))
```

### Triage prompt (reusable)

`triage_prompt(repo)` — the unit of work. Callable from sweep fan-out, pipeline tick (stalled repos), monitor tick (issue closed upstream), or drip (PR rejected). No denylist parameter — the agent reads persisted state to build its own.

```
def triage_prompt(repo):
  owner_repo = repo.replace('/', '-')
  return Agent({
    subagent_type: "general-purpose",
    model: "opus",
    run_in_background: true,
    prompt: f"Full triage pipeline for {repo}:
             
             0. BUILD DENYLIST AND READ REPO CONTEXT from persisted state before scanning issues:
                a. Read ~/.sweep/repos/{owner_repo}/TRIAGE_GRAPH.md — any issue marked KILLED, rejected, or gate_fail is denied.
                   Also read the MAINTAINER PREFERENCES section if present — review style, test conventions, coding patterns.
                   Apply these preferences to implementation: if the maintainer wants full CHECK lines, write full CHECK lines.
                   If they want return-failure not fallthrough, use return failure. These are hard requirements, not suggestions.
                b. Read ~/.sweep/drip-queue/{owner_repo}.jsonl — any issue with status closed, superseded, issue_closed, gate_fail, or test_passes_on_master is denied.
                c. Collect all denied issue numbers. These were already attempted — do not re-investigate them.
                d. Read CONTRIBUTING.md (or .github/CONTRIBUTING.md) and AGENTS.md from the repo. Extract: target branch, max commits per PR, CLA requirements, PR template requirements.
                   If AGENTS.md or CONTRIBUTING.md contains anti-AI policy ("do NOT", "does not condone", "no AI", "no LLM", "not to open PRs generated", prompt injection traps), kill the issue and evict the repo immediately. The kanidm incident taught this — AGENTS.md can carry hard anti-AI policy that CONTRIBUTING.md doesn't mention.
                   Also check ~/.sweep/retro/{owner_repo}.jsonl for contributing.* params (these override if present — learned from bot rejections).
                   Write these constraints to the TRIAGE_GRAPH.md MAINTAINER PREFERENCES section. Drip reads them before creating PRs.
             1. Fork (gh repo fork --clone=false) if not already forked.
             2. Clone to ~/Documents/<repo-name> if not already cloned.
             3. Scan issues: competing PRs, scoring, kill list. Rank top 5.
                EXCLUDE any issue in the denylist — they were already tried and killed.
                For solo-maintainer repos (first contribution), prefer the smallest/easiest issue — docs, error messages, edge cases. Standing first, ambition second.
             4. FOR EACH of the top 5 issues, in rank order, attempt the full pipeline:
                a. BUG HUNT (mandatory, runs on every issue). Diagnose before fixing. Answer:
                   (1) What is the existing mechanism that handles this concern? (dirty flags, caching, retry logic, etc.)
                   (2) Why does the current code do it this way? If you can't answer from code and comments, you don't understand enough to change it.
                   (3) What would a WRONG fix look like? What approach would the maintainer reject?
                   (4) Devil's advocate: argue "this isn't a bug because..." If that argument is stronger than the bug hypothesis:
                       - Comment on the issue with code-level evidence. Zero em dashes.
                       - Log as NOT_A_BUG in TRIAGE_GRAPH.md.
                       - Move to the next issue.
                   The bug hunt output is a diagnosis, not a fix. If the diagnosis says "the existing architecture already handles this, the symptom has a different root cause," do NOT override the architecture. Find the actual root cause or skip the issue.
                   Session 4 retro: jellyfin-tui #192 rejected because sonnet agent overrode dirty-flag architecture with frame cap. Opus bug-hunt independently identified the correct root cause (143Hz busy loop from short poll timeouts) and the correct fix (increase idle sleep, not cap frame rate). Bug hunt prevents wrong-approach fixes.
                b. TDD PHASE 1 — WRITE TEST FIRST. On the default branch (master/main), write a test that demonstrates the bug. Run it. It MUST FAIL. If it passes, the bug doesn't exist or your test is wrong. Do not proceed to the fix. Commit the failing test separately: "test: reproduce #N (fails on main)". THIS COMMIT IS MANDATORY AND SEPARATE. Session 4 retro: 18% TDD compliance when agents bundle test+fix. The separate commit is the proof that the test fails on main.
                c. TDD PHASE 2 — IMPLEMENT FIX. Send problem + code + failing test to /codex: 'Here is issue #N, here is a failing test that proves the bug, implement a minimal fix.' Apply codex's output. Run the test again. It MUST PASS. Commit the fix separately: "fix: #N description". TWO COMMITS MINIMUM: test commit + fix commit. Never bundle them.
                d. CODE REVIEW IS NOT YOUR JOB. `/qa` handles volley review + adversarial bug hunt on the committed branch. Do not send to /gemini or /codex for review. Your job ends at a committed, tested branch.
             5. IMMEDIATELY after tests pass: git add + git commit. Do not narrate, do not summarize, do not ask. Commit.
             6. Write branch pointer to ~/.sweep/drip-queue/{owner_repo}.jsonl.
                EXACT PATH EXAMPLE: for repo 'sharkdp/bat', write to ~/.sweep/drip-queue/sharkdp-bat.jsonl
                NOT ~/.sweep/drip_queue.jsonl (wrong — that's a global file)
                NOT ~/.sweep/drip/repo-issue.json (wrong — wrong directory and format)
                NOT ~/.drip/anything (wrong — wrong root)
                The file MUST be at ~/.sweep/drip-queue/{owner_repo}.jsonl where {owner_repo} = repo.replace('/', '-').
                Format: one JSON object per line with at minimum: repo, branch, issue, status ('triaged'), sha.
             7. Write TRIAGE_GRAPH.md to ~/.sweep/repos/{owner_repo}/TRIAGE_GRAPH.md (include all attempted issues and their outcomes — both kills and the winner).
                Include a MAINTAINER PREFERENCES section at the top if you learned anything from review comments, merged PR patterns, or maintainer inline feedback.
                Example: "Prefers full CHECK lines in tests, requires return failure not fallthrough, zero diffe mandatory for constant containers."
                Future agents read this before implementing — it prevents repeating the same review feedback.
             
             CRITICAL: Steps 5-7 are UNCONDITIONAL after step 4 passes. The codex/gemini feedback is a mid-point, not an endpoint. Your job is not done until the drip queue entry exists. If you end without writing a drip queue file, you have failed. Ending after a gemini rejection without trying the next issue is also a failure.
             
             NEVER run gh pr create. Triage agents produce branches, not PRs. Only /ship creates PRs.
             
             You have full permission to edit files, run commands, and commit. Never ask for confirmation. Never report feedback and stop. Apply → iterate → commit → write artifacts."
  })
```

Each agent runs the full pipeline end-to-end: scan → investigate → implement → test → review → queue. The output is a branch pointer in the drip queue, not a document. Agents that only produce TRIAGE_GRAPH.md without branches have not completed the pipeline.

**Denylist contract.** The agent builds its own denylist from persisted state — callers don't pass it. Source of truth: `TRIAGE_GRAPH.md` (killed/rejected issues) + drip queue JSONL (closed/superseded/gate_fail). Step 0 reads both before scanning.

**Who calls triage_prompt:**

| Caller | When |
|--------|------|
| Sweep fan-out (Phase 1) | Initial triage (denylist will be empty — no prior state) |
| Pipeline tick (stalled) | TRIAGE_GRAPH exists, no drip queue branch (denylist = killed issues) |
| Monitor tick (issue closed) | Upstream closed the issue (drip queue has issue_closed, denylist grows) |
| Drip (PR rejected) | Maintainer rejected PR (drip queue has closed, denylist grows) |
| Manual re-triage | User says "try again on repo X" (denylist = all prior attempts) |

This is the monoidal composition: `triage(repo); triage(repo) = triage(repo)`. Each invocation reads the same persisted state and skips the same issues. The TRIAGE_GRAPH + drip queue are the shared checkpoint. No parameter passing between callers — the filesystem is the interface.

**Model split — opus orchestrates, codex implements, gemini gates:**

Orchestration is token-cheap but judgment-heavy. Opus picks better issues and understands problems deeper — the cost difference vs. sonnet is negligible for scan/read/pick work. The expensive tokens are in implementation, and those go to codex.

| Phase | Model | Role |
|-------|-------|------|
| Scan, pick, read code | **Opus** (agent) | Judgment — issue selection, competing PR analysis, problem understanding |
| Implement fix | **Codex** (GPT-5.5 via `/codex`) | Structural reasoning — writes the actual fix code |
| Quality gate | **Gemini** (3.1 Pro via `/gemini`) | Logic tracing — catches inverted conditions, missed branches |

Steps 4b and 4d are **hard blocks**. A branch without codex implementation + gemini gate is a half-finished artifact. Do not queue it.

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

Triage agents run the implementation pipeline per item: bug hunt (diagnosis) → TDD (write test + fix) → commit. The output is a **branch pointer** in the drip queue. `/qa` then validates the branch independently (volley review + adversarial bug hunt). Example queue entry:

```jsonl
{"repo": "pallets/click", "branch": "fix-3362-hyphens", "issue": 3362, "test_cmd": "pytest tests/test_formatting.py", "worktree": "/Users/junekim/Documents/click", "status": "triaged"}
```

The branch is the artifact. It contains the diff, commits, and test changes. Everything downstream reads from it.

**Commit at implementation time.** Agents must `git add` + `git commit` as the final step of implementation, before writing the drip queue entry. An uncommitted branch is not an artifact — it's a half-finished workspace. The drip queue entry should reference a commit SHA.

**Post-agent verification (self-healing).** After each triage agent completes, the pipeline tick checks the filesystem — not the agent's report. For each repo that was assigned to an agent:

```bash
# Does ~/Documents/<repo> exist with a fix branch and uncommitted changes?
cd ~/Documents/<repo> && git status --short
# If uncommitted changes exist on a fix branch: commit them
# If committed but no drip queue file: write one
# If drip queue file exists: done
```

This makes half-finished agents a recoverable state, not a failure. The agent did the work — the pipeline finishes the paperwork. No second agent needed, just a filesystem check after each completion notification. Agents that self-report correctly skip this step (idempotent). Agents that don't get cleaned up automatically.

**Drip queues are per repo.** Each repo has its own independent queue at `~/.sweep/drip-queue/<owner>-<repo>.jsonl` with its own pacing. One open PR per repo at a time, but multiple repos can have open PRs simultaneously. Getting banned from one repo doesn't affect others.

**Repo clones live in `~/Documents/`.** Fork the repo on GitHub (`gh repo fork --clone=false`), clone to `~/Documents/<repo-name>`, create the fix branch. This is where the code lives — the branch pointer in the drip queue references this local path.

### Phase 5: Quality gates

`/qa` owns code review. `/drip` owns process gates. `/ship` owns PR creation. Sweep produces branches, `/qa` validates them (advancing `triaged` to `qa_passed`), `/drip` gates them (advancing `qa_passed` to `dripped`), `/ship` publishes them (advancing `dripped` to `shipped`). No `gh pr create` anywhere in sweep, qa, or drip. `/ship` is the only path from branch to PR.

Triage agents write branch + issue ref + commit SHA. No `pr_title`, no `pr_body`. `/drip` generates descriptions from the diff during the gate sequence and stores them in the gate attestation file. `/ship` reads them at PR creation time.

**`--dry-run` controls `/ship`.** When sweep runs with `--dry-run`, the pipeline tick runs `/drip` (gates) but skips `/ship` (PR creation). Entries accumulate as `dripped`. When `--dry-run` is off, the pipeline tick runs both. The user can always run `/ship` manually regardless of sweep mode. This is the sleep toggle: `--dry-run` means the pipeline keeps working but nothing goes public.

### Phase 5: Heartbeat (two crons)

After all phases complete, set up two recurring wake-ups with separated concerns:

```
# Pipeline tick — fast, does work
CronCreate({
  cron: "*/5 * * * *",
  prompt: "Run `python3 ~/.sweep/bin/tick.py <mode>` and print the output. Then act on ⚡ markers: spawn /qa agents for triaged entries (up to concurrency cap per tick), advance drip entries where org gate is clear (tick.py does this mechanically), run counit check. Skip /ship if dry-run.
           'Idle' = zero ready repos AND zero triaged branches AND zero stalled pipelines.",
  recurring: true
})

# Monitor tick — slow, checks state
CronCreate({
  cron: "23 * * * *",
  prompt: "/sweep --monitor. Use /drip --check on each repo with an open PR to check for reviews, comments, CI status, merges, or closures — /drip handles reviewer feedback and follow-up commits. Run eviction checks per the eviction table in the sweep skill. Check competing PRs on blocked items. Update SWEEP_GRAPH.md and ~/.sweep/SWEEP_LOG.md with state changes. If a PR merged, /drip advances the next triaged branch for that repo. If a PR was rejected, log to /retro. Max 50 GitHub API calls.",
  recurring: true
})
```

Pass `--dry-run` into both if set on the original invocation. **Always create both crons, even in dry-run.** Dry-run still needs the pipeline to keep cooking. The only thing `--dry-run` skips is `/ship` (PR creation). `/drip` (quality gates) runs regardless.

#### `--pipeline` tick (every 5 minutes)

Fast tick for advancing work. **Keep the work queue saturated.** Don't wait for running agents to finish before spawning new ones — agents are independent.

1. **Spawn up to `--concurrency` subagents this tick.** Read `~/.sweep/config.json` for the cap (default 5). Per-tick spawn limit. Pick order: warm leads first, then high-star.
2. **Run `/qa` on every repo with `triaged` entries.** `/qa` runs volley review (constructive, iterative) + adversarial bug hunt (codex). Advances passing entries to `qa_passed`. Fixes bugs it finds. Fails entries it can't fix.
3. **Run `/drip` on every repo with `qa_passed` entries.** `/drip` runs process gates (staleness, competing PRs, tone-match, org gate, em dash, PR description) and advances passing entries to `dripped`. No code review — QA already did that.
4. **If not `--dry-run`: Run `/ship`** on repos with `dripped` entries. `/ship` creates PRs, respecting org gate.
5. **Spawn impl agents** for any stalled pipeline (TRIAGE_GRAPH.md exists but no drip queue branch). Counts against concurrency cap.
4. **Run the counit.** Two checks:
   a. **Half-finished agents:** Check `~/Documents/` for repos with fix branches but no drip queue entry. Commit uncommitted changes, write the drip queue entry. Don't push — `/drip` handles that on the next tick.
   b. **Gate-fail recovery (volley):** Scan drip queues for `gate_fail` entries with actionable findings (the `reason` field). For each, spawn a triage agent with the gate findings as input: "Fix these specific issues on branch X, re-commit, update drip queue status back to `ready`." The agent applies the feedback, iterates with codex/gemini, and re-queues. Max 3 recovery attempts per branch — after that, the gate_fail is terminal. Counts against concurrency cap.
5. **If all four are empty:** report idle.

#### `--monitor` tick (hourly at :23)

Slow tick matching review cadence. Checks external state. Runs commands directly — no prose, no summaries.

1. **Scan all open PRs for new human comments.** Run `~/.sweep/bin/monitor-comments.sh <last_check_timestamp>`. Outputs tab-separated: `REPO#NUMBER\tAUTHOR\tSTATE\tBODY_PREVIEW`. Filters out bots. For each result:
   - CHANGES_REQUESTED or inline comment: spawn a review-response agent to address it and push a follow-up commit
   - COMMENTED with a question: spawn agent to reply
   - APPROVED: log, check if merge is possible
   - Style nit: apply if trivial

2. **Check for merges and closures.** Run `gh api graphql` for MERGED/CLOSED PRs since last check.
   For merges: update drip queue status, advance next triaged branch.
   For closures: update drip queue, log to retro, re-triage if warranted.

3. **Run eviction checks** per the eviction table below.
4. **Check competing PRs** on blocked items — `gh pr list --repo OWNER/REPO --search "KEYWORDS" --state merged`.
5. **Update `SWEEP_GRAPH.md` and `~/.sweep/SWEEP_LOG.md`** with state changes.
6. **If the roster has zero untriaged repos**, run `/actionable` to expand.

**Why two crons:** Pipeline work (spawning agents, running tests) completes in minutes. PR reviews take hours to days. Polling PRs every 2 minutes wastes context on "no change" responses. Polling pipeline state hourly delays agent spawning. Each concern runs at its natural cadence.

## Eviction (runs on `--monitor` tick)

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

**Apply now.** On each `--monitor` tick, scan `repos.jsonl` for eviction triggers before doing anything else. Log evictions to `~/.sweep/actionable/candidates.jsonl`.

## Rules

- **Never ask the user.** Sweep runs autonomously. If you have a hunch, act on it. If you're uncertain, skip it and move on. Log what you skipped and why. The user reads the punch list at the end, not a questionnaire in the middle.
- **One triage per repo.** Never mix repos in a single triage run.
- **Cross-pollinate, don't duplicate.** If two repos share a finding, write the cross-reference. Don't investigate the same thing twice.
- **Independent drip queues, shared org gate.** Each repo has its own queue, but repos under the same GitHub org share a maintainer surface. Drip enforces `max_open_per_org` (default 1) — one open PR per org at a time. Getting banned from one repo in an org triggers cooldown on all repos in that org.
- **Idempotent.** Running sweep twice skips repos whose triage is already complete (TRIAGE_GRAPH.md exists with all outcomes filled).
- **Auth first.** Verify access to every repo before launching any agents.
- **All PRs route through /ship.** No direct `gh pr create` in triage or drip. Triage produces branches, drip validates them, ship publishes them. Triage agents must NEVER run `gh pr create`. `--dry-run` skips `/ship` entirely, letting branches accumulate as `dripped` until the human invokes `/ship` or disables dry mode.
- **Never recommend closing a stale PR.** No-review age is a signal to ping, rebase, or break up — not to close. Closing destroys optionality. Only recommend closing when a maintainer explicitly rejects it or the approach is superseded by another merged PR.
