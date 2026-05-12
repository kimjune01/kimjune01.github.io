---
name: drip
description: Run process gates on qa_passed branches. Advances qa_passed → dripped. Refuses triaged entries (run /qa first). Does not create PRs. Use /ship for PRs.
argument-hint: <repo> [--check] [--list] [--watch]
allowed-tools: Read, Write, Edit, Bash, Glob
---

# Drip: Quality Gates

Run process gates on `qa_passed` branches. Advance entries from `qa_passed` to `dripped` (gates passed, ready to ship). **Refuses `triaged` entries — run `/qa` first.** Does not create PRs. `/ship` handles PR creation as a separate, human-gated step.

## Why

Eleven PRs in two days gets you banned. One PR per merge cycle builds contributor gravity. The code quality is the same — the pacing is different. This skill is the pacing.

## Monoidal contract

| Input | Output | Valid alone? |
|-------|--------|--------------|
| Queue file (JSONL) | Gate-passed entries (`dripped`) | Yes — quality validation from any source |

**Identity:** drip on an empty queue is a no-op. Drip on a queue with no `triaged` entries and no open PRs is a no-op.

**Composition:** `drip; drip = drip` — the queue file is the checkpoint. Running drip twice transitions at most one entry per run (idempotent within a pacing window).

**Standalone use:** The queue file is the interface. Any process that appends valid JSONL entries to `~/.sweep/drip-queue/<owner>-<repo>.jsonl` can feed drip — triage, manual `drip add`, a script, or another skill. Drip doesn't care who enqueued the entry.

**Pipeline composition:** `sweep(repos) = foreach(repo, ship(drip(triage(review_schema(repo)))))`. Each function is idempotent. Queue is per-repo. No shared mutable state between repos. `/drip` gates, `/ship` publishes.

## Artifact formats

- **`.md`** for human-readable artifacts: `TRIAGE_GRAPH.md`, `HYPOTHESIS_GRAPH.md`, readiness records, blog drafts
- **`.jsonl`** for machine-readable state: drip queues, structured logs, parameter files

## State file

`~/.sweep/drip-queue/<owner>-<repo>.jsonl` — one JSON object per queue entry, append-only:

```jsonl
{"ts":"2026-05-09T00:00:00Z","action":"enqueue","branch":"matvec-test-and-fix","title":"fix MATVEC: reject equal-range elementwise reduces","body":"I'm learning","status":"triaged"}
{"ts":"2026-05-09T00:15:00Z","action":"push","branch":"matvec-test-and-fix","pr_number":16116,"status":"open"}
{"ts":"2026-05-09T01:00:00Z","action":"outcome","pr_number":16116,"status":"merged"}
```

Statuses: `triaged` → `qa_passed` (code review by `/qa`) → `dripped` (process gates by `/drip`) → `shipped` (PR created by `/ship`) → `merged` | `closed` | `rejected`

Also: `test_passes_on_master`, `test_fails_on_fix`, `issue_closed`, `superseded`, `needs_rebase`, `error`, `gate_fail` (set by failure checks, never by hand).

## Commands

### `--list`

Show the queue. For each entry: branch, title, status, PR number if open.

### `--check`

Two jobs: run process gates on `qa_passed` entries, and respond to reviewer feedback on shipped PRs.

**Gate advancement:**
1. For each `qa_passed` entry: run process gates (staleness, tone, org gate, em dash, PR description). If all pass, mark `dripped`. If any fail, mark `gate_fail` with reason. Skip `triaged` entries — those need `/qa` first.
2. Update statuses: check if any `shipped` PRs were merged or closed since last check. Transition them in the queue.

**Review response (for each shipped PR):**
1. Fetch new comments/reviews: `gh pr view <number> --repo <repo> --json comments,reviews,reviewDecision`
2. Classify each new comment:
   - **CHANGES_REQUESTED or inline code comment**: read the feedback, implement the fix, push a follow-up commit. Reply acknowledging the change.
   - **Question**: spawn agent to answer based on the code and PR context.
   - **Style nit**: apply if trivial, explain if not.
   - **APPROVED**: log, check merge readiness.
3. After addressing feedback: run gemini volley on the updated diff before pushing.
4. **Capture maintainer preferences**: if the reviewer's feedback reveals a pattern (e.g., "use CHECK-NEXT not CHECK-DAG", "return failure not fallthrough"), write it to the MAINTAINER PREFERENCES section of `~/.sweep/repos/<owner>-<repo>/TRIAGE_GRAPH.md`. Future triage agents read this before implementing — prevents repeating the same feedback.
5. A PR with unanswered reviewer comments older than 24 hours is a driveby. Don't ship new PRs to the repo while feedback is unaddressed.

### (no flag)

Same as `--check`. The default action is: run gates and respond to reviews.

## Process

### Adding to the queue

Triage's Phase 4 (or manual use) adds entries:

```bash
# From triage dry run results or manual prep
/drip add --repo tinygrad/tinygrad --branch matvec-test-and-fix --title "fix MATVEC: reject equal-range elementwise reduces" --body "I'm learning"
```

Triage writes branch pointers directly to `~/.sweep/drip-queue/<owner>-<repo>.jsonl`. Manual `add` is for ad-hoc entries.

### Check cycle

0. **Repo status gate (hard block).** Run `~/.sweep/bin/repo-status <owner/repo>`. If verdict is not `"clear"`, halt with the reason. This single script checks DENYLIST.md, permanent eviction, cooldown expiry, and 7-day rejection cooldown. No need to reimplement these checks — the script is the source of truth.
1. Read `~/.sweep/drip-queue/<owner>-<repo>.jsonl`
2. For each entry with status `shipped`:
   - Check if the PR was merged or closed. Update status.
   - **AI slop detection response (on closure).** When a PR is closed without merge, run `~/.sweep/bin/ai-detect <owner/repo> <pr-number>`. If `detected: true`, run `~/.sweep/bin/slop-recommend <owner/repo> <pr-number>` to post the filter recommendation, then write `permanent_eviction` to the repo's retro params. This must fire on the FIRST AI-detection closure — by the second, you may already be blocked. jellyfin-tui taught this: blocked after 3 PRs, couldn't comment the recommendation manually.
   - **Checkup.** Fetch reviewer comments since last check: `gh pr view <number> --repo <repo> --json comments,reviews,reviewDecision`. If there are new comments or requested changes:
     1. Read the feedback. Classify: requested change, question, style nit, or approval.
     2. For requested changes and questions: address them. Push a follow-up commit to the same branch. Reply to the comment acknowledging the change.
     3. For style nits: apply if trivial, reply explaining if not.
     4. Run the gemini volley on the updated PR before pushing the follow-up.
     5. Log the interaction to the event log.
   - A PR with unanswered reviewer comments older than 24 hours is a driveby. Don't ship new PRs to a repo while an existing one has unaddressed feedback.
3. For each `qa_passed` entry (skip `triaged` — those need `/qa` first; skip if any shipped PR has unaddressed feedback):
   - Take the next `qa_passed` entry
   - **Attestation verification (hard block).** Before anything else, verify the QA attestation fields exist in the queue entry's `gates` object: `gemini_verdict`, `gemini_first` (>20 chars), `gemini_last` (>20 chars), `codex_verdict`, `test_attestation`. If any field is missing or `NOT_RUN`, demote back to `triaged` for QA to re-run. This is cheap and catches attestation gaps before they reach the gate hook.
   - **Staleness check (hard block).** Before pushing, verify the issue is still open: `gh issue view <number> --repo <repo> --json state`. If closed, mark `status: "issue_closed"`, skip. Check for competing PRs: `gh pr list --repo <repo> --search "<keywords>"`. If someone else landed a fix, mark `status: "superseded"`, skip. The gap between triage and push can be days — the world moves.
   - **CONTRIBUTING.md compliance gate (hard block).** Read CONTRIBUTING.md (or .github/CONTRIBUTING.md) from the repo's default branch. Extract: target branch (if not default), max commits per PR, required PR template fields, CLA requirements. Check retro params for `contributing.*` overrides. Verify the PR will comply before creating it. If the target branch is not default, use `--base <branch>`. If max commits exceeded, squash. If CLA required, check if already signed. Three pipeline errors from open-webui (#24545, #24546) taught this — bot-rejected PRs are noise on the contributor surface.
   - **Org gate (hard block).** Run `~/.sweep/bin/org-gate <repo>`. If verdict is `"blocked"`: a sibling repo has an open/recent PR, wait. If verdict is `"hostile"`: multiple PRs closed without merge across the org recently, surface to the human before pushing. `max_open_per_org` defaults to 1. Override via retro params.
   - **Test gate (hard block).** The queue entry must include a test command. Run it:
     1. Checkout the repo's default branch. Run the test. It must **fail**. If it passes, mark `status: "test_passes_on_master"`, skip, report. The bug is already fixed or the test is wrong.
     2. Checkout the fix branch. Run the test. It must **pass**. If it fails, mark `status: "test_fails_on_fix"`, skip, report. The fix is broken.
   - **PR description (generated from diff + hypothesis graph).** Read the diff from the fix branch. Then read `~/.sweep/repos/<owner>-<repo>/TRIAGE_GRAPH.md` and any `HYPOTHESIS_GRAPH.md` for the issue — these contain the root cause analysis, competing approaches considered, and why this specific approach was chosen. The PR body must lead with *why*, not *what*: why this root cause, why this approach over alternatives, why this is the minimal correct fix. The diff already shows *what* — repeating it in prose is waste. Tone-match against 5 recent merged PRs from the repo. The description is a drip artifact — triage doesn't write it, but triage's investigation artifacts are the source of the reasoning.
   - **Why gate (hard block).** The PR body must lead with *why* this change is needed, not *what* changed. Verify the first paragraph answers "why does this problem exist and why is this the correct fix?" If the body only describes what the diff does, rewrite it. The issue describes what's broken; the PR body explains why the fix is correct.
   - **Em dash gate (hard block).** Zero em dashes (`—`) in the PR body. Em dashes are the easiest visual tell for AI-generated text. Replace with periods, commas, or restructure the sentence. No exceptions.
   - **Summary reasoning check.** Verify the PR body contains independent technical rationale — not "based on review feedback" or "as suggested." If the body can't explain *why* without referencing a reviewer, the agent didn't understand the problem deeply enough. Rewrite until it can. ruff#25066 was closed for "mainly produced by AI" because the summary referenced reviewer feedback instead of stating independent reasoning.
   - **Write gate attestation (hard block).** Before pushing, write `~/.sweep/gates/<owner>-<repo>.gate` as JSON. Copy the QA attestation fields (gemini_verdict, gemini_first, gemini_last, codex_verdict, test_attestation) from the queue entry's `gates` object. Add the PR title and body. The `gh pr create` hook validates this file exists. Format:
     ```json
     {
       "ts": "2026-05-09T23:05:00Z",
       "repo": "owner/repo",
       "branch": "fix/123-thing",
       "gemini_verdict": "pass",
       "gemini_first": "No logic errors found in the extractvalue type seeding.",
       "gemini_last": "Recommend merge as-is.",
       "codex_verdict": "pass",
       "codex_first": "PR #3 matches repo voice.",
       "codex_last": "Cannot distinguish from human-written.",
       "test_attestation": "main:FAIL fix:PASS go test ./pkg/foo/... 2026-05-09T23:04:50Z"
     }
     ```
     **Receipt fields:** `gemini_first` and `gemini_last` are the first and last sentences from gemini's actual review output. They prove the review ran and reached a conclusion. The hook requires both fields, each >20 characters. Fabricating plausible review sentences that match the diff context is harder than running the review.
     
     Test attestation is a string with both legs: `"main:FAIL fix:PASS <test cmd> <timestamp>"`. Both results required — a fix that doesn't flip a test from fail to pass isn't a fix. If skipped: `"skipped: <reason>"`. The hook checks the field is not empty.
   - **DO NOT PUSH.** Drip never runs `git push`. That's `/ship`'s job. Drip validates the branch and writes the gate attestation. Ship reads the attestation, pushes the branch, and creates the PR.
   - Update entry: status → `dripped`, dripped_at → now, gates → `{gemini_verdict, codex_verdict, test_attestation}` (copied from the gate file)
   - Store the generated PR title and body in the gate attestation file so `/ship` can use them directly.
4. Report: what was dripped, what's still triaged, what's blocking, what's waiting for `/ship`.

### Tone matching

Before creating the PR, read the 5 most recently merged PRs on the repo. Match the title format, body length, and level of detail. If the entry's title or body doesn't match, rewrite it to fit. The chameleon rule from `/triage` applies here too.

### Codex crosscheck (moved to /qa)

Code review gates (gemini volley on the diff, codex adversarial review) are now `/qa`'s responsibility. Drip only processes `qa_passed` entries. The codex crosscheck on PR *descriptions* (AI-likeness detection on the prose, not the code) remains in drip as part of tone matching.

## Integration with /qa and /triage

Triage writes branch pointers to `~/.sweep/drip-queue/<owner>-<repo>.jsonl` with `status: "triaged"`. `/qa` validates the code (volley + bug hunt) and advances to `status: "qa_passed"` with attestation fields. Drip only processes `qa_passed` entries.

Drip generates PR descriptions from the diff at push time, not from triage artifacts. This ensures the description matches the final code (which QA may have improved), not an earlier plan.

## Heartbeat mode

`/drip --watch` runs the check cycle on a 15-minute heartbeat as a background agent. It:

1. Runs process gates on `qa_passed` entries every 15 minutes
2. Advances passing entries to `dripped`
3. Checks shipped PR status (merges, closures, reviews)
4. Updates the queue file after each transition
5. Stops when no `qa_passed` or shipped entries remain

Use `/loop 15m /drip` or set up a cron. The skill is stateless between invocations — the queue file is the checkpoint.

## Preflight

Before any operation, verify GitHub auth:

```bash
gh auth status
```

If this fails, stop immediately with: "GitHub auth not established. Run `gh auth login` or set GITHUB_TOKEN." Do not attempt any PR operations without confirmed auth. This catches stale tokens, missing env vars, and permission issues before wasting time on branch prep.

## Rules

- **Auth first.** Every invocation starts with `gh auth status`. Fail fast on auth issues.
- **One at a time by default.** `max_open` defaults to 1. Override with `--max-open N` on first use.
- **One per org by default.** Repos under the same GitHub org share a maintainer surface. Push to one org repo at a time. Override with `max_open_per_org` in retro params. Three batch-closes taught this: click, jinja, and quart hit davidism's inbox on the same day.
- **Never push.** Drip never runs `git push`. Only `/ship` pushes to forks and creates PRs. Drip validates and writes attestations. Session 5 lesson: drip agents pushed QA-fixed code directly to live PR branches, bypassing ship's PR description regeneration and tone matching.
- **Never force push.** If the branch needs a rebase, do it before adding to the queue.
- **Fail on master, pass with fix.** Before pushing any candidate, checkout master's code and run the test. It must fail. Then checkout the fix and run the test. It must pass. If either check fails, do not push. This is the assertion that every PR makes — verify it locally before asking a reviewer to verify it for you.
- **Idempotent.** Running `/drip` twice with no state change produces the same output. Merged/closed PRs get their status updated but nothing else happens.
- **No PR creation.** Drip never runs `gh pr create`. That's `/ship`'s job. Drip gates; ship publishes.
- **Log transitions.** When an entry moves from triaged → qa_passed → dripped or shipped → merged/closed, append to the worklog via `/log` if available.

## Failure behavior

- **Gate fail (gemini/codex reject):** mark `status: "gate_fail"`, write the specific findings to the `reason` field as actionable text (not just "failed" — list what to fix). The pipeline counit reads these findings and spawns a triage agent to apply fixes and re-queue. Drip doesn't fix code — it gates. The volley loop is: drip finds issues → counit spawns fixer → fixer re-queues → drip re-gates. Max 3 recovery attempts tracked in the queue entry's `gate_fail_count` field.
- **Auth fails:** stop immediately, report which token/scope is missing.
- **Branch missing locally:** skip the entry, mark `status: "error"`, report. Don't block the queue.
- **Branch needs rebase:** skip the entry, mark `status: "needs_rebase"`, report. The user rebases manually, then `/drip` picks it up next cycle.
- **Test passes on master:** skip the entry, mark `status: "test_passes_on_master"`, report. The bug was already fixed upstream, or the test is wrong. Don't push.
- **Test fails on fix:** skip the entry, mark `status: "test_fails_on_fix"`, report. The fix is broken. Don't push.
- **Issue already closed:** skip the entry, mark `status: "issue_closed"`, report. Someone else fixed it.
- **Superseded by another PR:** skip the entry, mark `status: "superseded"`, report with link to the competing PR.
- **Fork remote missing:** stop, report. The user sets up the fork.
- **PR closed by maintainer:** mark `status: "closed"`, advance to next entry. Don't reopen.
- **Org-level rejection:** Multiple PRs closed without review across repos in the same org within 24 hours = org-level rejection. Set cooldown on **all repos in that org**, not just the closed one. Log the cross-repo pattern to each repo's retro file. Don't push to any repo in the org until the cooldown expires or the human overrides.
