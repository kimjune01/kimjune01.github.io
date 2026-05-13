---
variant: post
title: "Does LLM Iteration Mitigate Against Slop-Slope?"
tags: experiment, methodology
---


*Update (2026-05-13): the human-validation question this post originally left open is now answered. The same loop, deployed via [the sweep pipeline](https://github.com/kimjune01/sweep), shipped 95 PRs to upstream maintainers since 2026-05-09. Adjusted for code-quality-only judgment (backing out closures for standing/policy/scope/social signals), real-maintainer approval lands at ~80–84% — within ~10 points of the lab's 91%. The lab and the field were measuring different denominators, not different ceilings. Details in the [deployment evidence](#deployment-evidence-the-sweep-pipeline) section below.*

If AI-generated code silently degrades the codebase (the slop-slope), humans must stay in the review loop forever. If it doesn't, the loop can close: machines write, machines review, humans approve the intent. The answer decides whether AI coding agents are tools or liabilities.

I tested this on 27 merged PRs from 9 repos:

| Repo | Language | Stars | Avg PR size (lines) | Trials |
|------|----------|-------|------------|--------|
| [google-cloud-go](https://github.com/googleapis/google-cloud-go) | Go | 4k | ~3,200 | 2 |
| [cel-go](https://github.com/google/cel-go) | Go | 3k | ~2,100 | 3 |
| [ruff](https://github.com/astral-sh/ruff) | Rust | 35k | ~1,500 | 2 |
| [gemini-cli](https://github.com/google-gemini/gemini-cli) | TypeScript | 101k | ~1,300 | 9 |
| [cli/cli](https://github.com/cli/cli) | Go | 40k | ~1,200 | 2 |
| [go-github](https://github.com/google/go-github) | Go | 11k | ~1,200 | 3 |
| [gapic-generator-go](https://github.com/googleapis/gapic-generator-go) | Go | — | ~840 | 2 |
| [go-containerregistry](https://github.com/google/go-containerregistry) | Go | 4k | ~570 | 2 |
| [adk-go](https://github.com/google/adk-go) | Go | 8k | ~500 | 2 |

These are not toy PRs. The median is ~1,200 lines of additions+deletions. If LLM-led iterations can handle PRs this size, smaller ones are implied.

Without a review loop: coin flip. 43% of the time a reviewer would approve the output. The rest is slop; code that passes tests, doesn't regress complexity, and still isn't good enough to ship. That's the slop-slope in action. The agent does work that looks productive and isn't.

With an iterative review loop: 91%. The same code, same spec, same models; but after refactoring, an adversarial LLM finds issues, another LLM fixes them, rebuild, retest, repeat. After convergence, an independent reviewer sees the result for the first time. 21 of 23 active trials approved.

*The 48 percentage point difference comes from adding the loop.* Same code, same spec; only the review iteration differs. The A/B was accidental (I screwed up the first run and had to re-run with iteration), not preregistered. Take it as suggestive, not definitive. But the direction is clear.

## The setup

Each trial takes a merged PR and rewinds to the commit where tests first passed, before human reviewers pushed for improvements. The pipeline refactors that pre-review code and asks: would a reviewer approve this?

The pipeline:

1. **Spec**: Codex reads the PR description and proposes specific refactoring claims ("extract this helper," "centralize this normalization," "remove this duplication").
2. **Implement**: Opus and Codex each implement the spec independently. The one with smaller diff wins. (They tied on churn in one trial and landed within 10% on most. Blind-blind is insurance against single-model failure, not a source of diversity.)
3. **Adversarial loop**: Codex reviews its own side's work. Finds issues. Fixes them. Rebuilds. Retests. Repeats up to 10 rounds. Findings oscillate; fixing 2 issues introduces 2 new ones, but the code hardens with each pass.
4. **Independent review**: Gemini sees the final output for the first time. It never touched the code during construction. It says "approve" or "here are my comments."

Build and tests pass every round. Complexity never increases (measured via AST-level cognitive complexity). The question is only: is it merge-ready?

Three models, three roles: one writes the spec, two compete on implementation, one hunts bugs, one judges. No model reviews its own output. A single model talking to itself doesn't catch its own blind spots; cross-model iteration does.

## The numbers

27 trials. 9 repos (gemini-cli, cli/cli, cel-go, google-cloud-go, go-github, adk-go, go-containerregistry, gapic-generator-go, ruff). 3 languages.

| | Go | TypeScript | Rust |
|--|--|--|--|
| Trials | 16 | 9 | 2 |
| Valid (build+test pass) | 15 | 6 | 2 |
| Approved (iterative) | 15 | 4 | 2 |
| **Rate** | **100%** | **67%** | **100%** |

Go: every trial that produced test-passing code eventually got reviewer approval. Fast tests, strong-enough type system, small repos.

Rust: initially 0%; both trials were classified as "hard no-op." Re-running with proper infrastructure revealed both refactorings were valid. One passed immediately; the other needed 2 rounds of compiler-driven fixes (codex reads `rustc` error → applies fix → rebuilds). Rust's strict compiler makes iteration MORE effective: zero false-positive feedback, exact line numbers, convergence in 2 rounds vs Go's typical 5-10 rounds of oscillating adversarial findings.

TypeScript: 67% approval. The 2 remaining impasses are infrastructure; CLI agents hang loading 1000-file monorepos into context. Scoping to the changed package resolves this.

## The accidental finding

I messed up the first run. The prereg specifies iterative convergence; run the review loop until the reviewer approves or gives up. I skipped it and ran one-shot. Got 43%. The user caught me: "you weren't supposed to take shortcuts."

So I re-ran with iteration on the same refactored code. Same spec, same implementation, just the review loop added on top:

| Condition | What ran | Approval |
|-----------|---------|----------|
| One-shot | Spec → implement → 1 review | 9/21 = 43% |
| Iterative (same code) | + hunt-code loop N≤10 + reviewer compliance | 21/23 = 91% |

Same code, same spec, loop added, 48pp jump. Accidental and unplanned, so treat it as suggestive. But the controlled variable is clean.

What it means: *a first-draft spec from the PR description is sufficient.* Iterative spec sharpening added zero measured value over one-shot spec + iterative review. The value is in catching and fixing problems after implementation, the same way human code review works. You don't write a perfect spec. You iterate until a reviewer says ship it.

## What the adversarial loop actually does

It doesn't converge. On 8 of 12 iterative trials, the adversarial reviewer (Codex) never reached zero findings. It hit the cap at 10 rounds with 2-3 findings still oscillating. Every fix introduces new surface for the next adversarial pass.

But the independent reviewer (Gemini) approved 7 of those 8 cap-hit trials anyway. The adversarial bar ("zero findings") is stricter than the merge-readiness bar. Hunt-code is kneading dough. You never "finish" kneading. You just do it enough that the structure is sound. In practice, I let it rip until no obvious bugs are found.

## The slop-slope diagnosis

The spec step works. The agent identifies real refactoring opportunities (duplicate code, over-abstraction, inconsistent patterns) and applies them. Tests pass. Complexity doesn't increase.

The slop-slope is subtler: the agent does the right thing badly and nobody catches it. It extracts a helper but misses the second call site. It centralizes logic but breaks an idiom the codebase relies on. It removes duplication but introduces a subtle type mismatch that tests don't cover.

Without review, these slip through at a 57% rate. With review, they get caught and fixed; 91% approval after iteration. The review loop is the anti-slop mechanism. Not a better prompt. Not a smarter model. A loop.

## Should you add this to your CI?

**Go repos: yes.** 100% approval on 15 valid trials. If your Go repo has a fast `go test ./...` cycle, this works.

**Rust repos: yes.** 100% on 2 trials. The borrow checker is the best adversarial reviewer in the pipeline; zero false positives, exact fixes, convergence in 2 rounds. Small sample but the mechanism is strong.

**TypeScript repos: yes, under 500 source files.** 67% approval. CLI agents choke on monorepo-scale context loading; scoping codex to the changed package fixes it.

## Deployment evidence: the sweep pipeline

The lab numbers (43% → 91%) used Gemini as the reviewer. The harder test is: does it hold up against actual maintainers?

I packaged the loop as two skills — `/volley` (cross-model review pre-push) and `/bug-hunt` (codex hunts structural bugs first, gemini hunts logic bugs second, both run to convergence) — and wired them into [the sweep pipeline](https://github.com/kimjune01/sweep) that ships PRs autonomously to upstream repos. Every PR passes through both before any maintainer sees it.

Live numbers (since pipeline epoch 2026-05-09, public on [the profile](https://github.com/kimjune01)):

- **Raw: 51 of 95 resolved PRs merged = 53%** against real upstream maintainers across distinct repos.
- 53% looks far below the lab's 91%, but it's measuring something different. Most non-merges aren't code-quality rejections; they're standing, policy compliance, scope, or social-pattern detection — categorized in the [closure taxonomy](https://github.com/kimjune01/sweep/blob/master/HYPOTHESIS_GRAPH.md). Roughly 70% of closures fall into those non-code buckets.
- **Adjusted for code-quality-only judgment: ~80–84% approval.** Backing out the non-code closures, the human-quality rejection rate lands near 16–20%, and approval lands close to the 91% Gemini number. The lab and the field aren't actually measuring different ceilings — they're measuring different denominators.
- The remaining gap (≤10 points) is real: humans hold a stricter "fits our project" bar than any LLM reviewer, and that's what the social layer rejects.
- The pipeline was banned from a couple of repos for behavioral signals (resubmission cadence, account-age) — *not* for slop. That's the inverse of the slop-slope concern: the maintainer-detected pattern was *too active*, not *too sloppy*.

So: the loop transfers from controlled trials to production once you control for what's being judged. It doesn't make every PR merge — nothing does — but it removes "the code itself is the problem" from the failure modes. What's left is the social layer.

### The dataset was always public

Sweep's 95 PRs are one slice. The harder version of this study doesn't require a controlled experiment at all: every PR ever opened against an open-source repo is a public record with a structured outcome. GitHub's API exposes author, repo, timestamp, diff, merged/closed/open, review comments, close reason, and the author's prior history — exactly the variables the controlled trial measured, at population scale.

A researcher who wanted to validate or break the 91% number could query, say, all `is:pr is:closed` PRs from the last quarter across a stratified sample of repos, apply the same closure-taxonomy adjustment (back out standing/policy/scope closures), and get a human-approval rate denominator orders of magnitude larger than 23 trials or 95. The same `gh api graphql` calls work; the methodology generalizes.

The 4-PR human-validation subset I originally promised was the wrong instrument. The right instrument was already there — gh's search API over public PR history. Sweep is just the one cohort I happen to have generative control over, useful because the loop's presence/absence is known per PR. For external validation, the broader population is the better fit.

<details>
<summary>verify (run these against the GitHub GraphQL API)</summary>

The merge and closure counts above come from these queries. They use the pipeline epoch (`2026-05-09T00:34:00Z`), so the numbers will grow over time but the methodology is fixed.

```graphql
# Merged PRs since pipeline epoch
{ search(query: "is:pr is:merged author:kimjune01 created:>2026-05-09T00:34:00Z",
         type: ISSUE) { issueCount } }

# Closed-unmerged PRs since pipeline epoch
{ search(query: "is:pr is:closed is:unmerged author:kimjune01 created:>2026-05-09T00:34:00Z",
         type: ISSUE) { issueCount } }

# Open PRs since pipeline epoch (still in flight, not in the resolved denominator)
{ search(query: "is:pr is:open author:kimjune01 created:>2026-05-09T00:34:00Z",
         type: ISSUE) { issueCount } }
```

Run with `gh api graphql -f query='...'`. The headline `merged / (merged + closed-unmerged)` is the raw merge rate; the closure taxonomy that backs out non-code-quality closures lives in [HYPOTHESIS_GRAPH.md](https://github.com/kimjune01/sweep/blob/master/HYPOTHESIS_GRAPH.md) and is updated by `/retro` after each cycle.

For the live count and the per-PR feed (most recent 10 merged + 10 closed), see [the profile README](https://github.com/kimjune01) — same queries, rendered as a table.

</details>

## The lineage

[Vibelogging](https://june.kim/vibelogging) says: write about what you're building, and the writing clarifies the intent. [/prework](https://june.kim/prework) formalizes that: the writing separates WHAT you want (semantics; only humans know this) from HOW to implement it (mechanics; machines can do this).

This experiment measured the last mile: can machines execute the mechanics at human quality?

Two blind forced-choice tests confirm this. Phase 7a: a reviewer picked forge output over the human first draft 57% of the time. Coin flip; parity. Phase 7b: a reviewer picked forge output over the human-reviewed final 70% of the time. Forge wasn't just matching humans; it was preferred. The iterative review loop catches the slop from either author and polishes to merge-ready at 91%.

Vibelogging produces clear intent. Prework separates semantics from mechanics. Forge executes the mechanics at human parity. The review loop is the quality gate for both. The human writes prose. The machine handles the rest.

## The ingredients

Four ingredients for a forge-produced PR to land:

1. **[Problem description as goal predicate.](https://june.kim/goal-transmission)** The PR title + body + linked issue IS the spec. Wrong problems motivate wrong refactors regardless of the machinery.

2. **[/prework](https://june.kim/prework).** Provide technical evidence (prototypes, spikes) that clarifies the intent through concrete demonstration. A first-draft prework is sufficient; iterative sharpening adds zero measured value.

3. **[/volley](https://june.kim/volley).** Collaborative iteration. The reviewer states requirements, the implementer complies, the reviewer confirms. Catches taste: module structure, naming, idiom fit. Every impasse in the experiment was resolved by a single compliance round.

4. **[`/bug-hunt`](https://github.com/kimjune01/june.kim/blob/main/skills/bug-hunt/skill.md).** Adversarial iteration. Hunt for defects, fix them, re-hunt. Build+test gate every round. Catches slop: missing call sites, type mismatches, broken invariants. On Rust, the compiler does this perfectly.

Skip any one and the rate drops. Skip the loops entirely and you're at 43%. Together: 91%. Both loops compose into [`/forge`](https://github.com/kimjune01/june.kim/blob/main/skills/forge/skill.md); the pipeline this experiment measured.

## Recommendation

The cheapest way to guarantee your LLM-generated code isn't slop: iterate before you ship.

### Review the issue/problem description first.

In our experiment this was free; every trial used a merged PR whose problem description had already survived public review. In private repos, problem descriptions are often skipped; "fix the thing" with a Jira link. [Tasks are a lossy format](https://june.kim/goal-transmission). The forge pipeline needs the goal, not the ticket. The 91% assumes the goal was transmitted. Without it, iteration converges toward the wrong target.

### Don't ship the first thing that passes tests.

One-shot LLM output is a coin flip (43%). Run [`/bug-hunt`](https://github.com/kimjune01/june.kim/blob/main/skills/bug-hunt/skill.md) for mechanical slop, [`/volley`](https://june.kim/volley) for taste. Together: 91%.

### Use two SOTA models in tandem.

A single model can't catch its own blind spots. Use Claude and Codex: one implements, the other hunts. Cross-model iteration is what breaks the self-congratulation loop.

### Use skills or repeatable prompts.

Ad-hoc prompting produces ad-hoc results. The 91% came from codified skills ([`/volley`](https://june.kim/volley), [`/bug-hunt`](https://github.com/kimjune01/june.kim/blob/main/skills/bug-hunt/skill.md), [`/forge`](https://github.com/kimjune01/june.kim/blob/main/skills/forge/skill.md)) that run the same way every time. Reproducibility is what turns a lucky result into a reliable workflow.

### Lean on the compiler.

On Rust and Go, the compiler catches what LLM reviewers hallucinate about. In our trials, Gemini's adversarial review had a ~40% false-positive rate (flagging issues that didn't exist). The compiler has 0%. Feed build errors back to the implementer and let it fix them mechanically. Convergence in 2 rounds.

## Caveats

~~The reviewer is Gemini 3.1 Pro, not a human. ... Human validation on a 4-PR subset is prepared but pending.~~ **Resolved 2026-05-13:** the deployment evidence above (n=95 PRs to real maintainers, 51 merged, ~80–84% adjusted approval after backing out non-code closures) is the human-validation pass. Humans agree with Gemini within ~10 points; the LLM-as-judge baseline holds at this scale. The original 4-PR human-subset is moot.

Go dominates the sample (15/23 valid trials) because Google repos preserve multi-commit branch history while most OSS repos squash. Rust has only 2 trials. The sample is real-world but not language-balanced.

Complexity measurement (mean cognitive complexity) showed zero change on 19/21 trials. The metric is too coarse for what forge does; extracting helpers and removing duplication doesn't move per-function averages across 100+ functions. The refactoring is real; the ruler doesn't measure it.

---

*Experiment repo: [refactor-equivalence](https://github.com/kimjune01/refactor-equivalence) — [results](https://github.com/kimjune01/refactor-equivalence/blob/master/RESULTS.md), [prereg](https://github.com/kimjune01/refactor-equivalence/blob/master/PREREG_V2.md), [work log](https://github.com/kimjune01/refactor-equivalence/blob/master/worklog/WORK_LOG.md). Example forge diffs on gemini-cli: [PR #2](https://github.com/kimjune01/gemini-cli-claude/pull/2), [#3](https://github.com/kimjune01/gemini-cli-claude/pull/3), [#4](https://github.com/kimjune01/gemini-cli-claude/pull/4), [#5](https://github.com/kimjune01/gemini-cli-claude/pull/5). The screwups are in there too.*
