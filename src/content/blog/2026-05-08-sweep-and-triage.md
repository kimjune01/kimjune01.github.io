---
variant: post-wide
title: "Sweep & Triage"
tags: coding, methodology
---

When I got [investigate](/investigate) working, I got excited. [Hypothesis graph](/the-hypothesis-graph), [fan-out](/fan-out) competing hypotheses, classify [evidence trajectories](/evidence-has-a-trajectory), run [prework](/prework), [bug-hunt](/bug-hunt) until convergence. One PR fell out: a single number change, 62-105% speedup, full provenance. I pointed it at a well-maintained repo.

The maintainer batch-closed everything. "I'm not reading anything written by AI." The fixes were correct (net zero lines, 47-59% speedup) but the communication was wrong. Eleven PRs in two days. No tests. No tone matching. Any self-respecting engineer would look away.

Unreasonable, tenacious. The PRs failed because my skills were weak. The methodology was sound. Iterative review pushes merge-readiness from [43% to 91%](/does-iteration-mitigate-slop-slope). Investigate automates engineering. The pieces existed separately. What if they composed?

## Closed loop

Five agents on five bugs in parallel. The tree broke. Agent A discovered RDNA4's [WMMA](https://gpuopen.com/learn/using_matrix_core_amd_rdna4/) maps operands differently than RDNA3. Agent B was about to push a perturbation assuming all AMD GPUs share the same mapping. Without the agents talking, B wastes a CI run discovering what A already knew.

Nodes are shared across investigations.

<div style="width:95vw;margin-left:calc(-47.5vw + 50%)">

![Pipeline flow: sweep → triage → parallel investigate agents → hypothesis graph → lineup gate → drip, with retro reading logs from all stages](/assets/sweep-and-triage-pipeline.svg)

</div>

### Shared state

The naive dispatcher routes: read the issue list, assign each to an agent, collect results.

In one session I had two PRs open against the same heuristic in tinygrad. PR [#16107](https://github.com/tinygrad/tinygrad/pull/16107) changed the post-tensor-core optimization from UPCAST M+N to UPCAST N only. PR [#16109](https://github.com/tinygrad/tinygrad/pull/16109) tried a reduced UNROLL factor on the same code path. When CI showed UPCAST N alone broke AMD [gfx1201](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html), that finding applied to both PRs. The root cause was WMMA operand lane mapping, and any post-TC optimization that changed axis coverage would hit the same wall.

A dumb router would have two agents burning two CI runs on identical perturbations. The graph needs a single source of truth.

### The file is the data structure

A markdown file with named nodes. If another agent already classified the hypothesis, it skips the experiment and cites the node. If it discovers something affecting another investigation, it writes a cross-reference edge.

Agents don't write to the shared graph directly. Each gets a [git worktree](https://git-scm.com/docs/git-worktree) and writes to `TRIAGE_RESULT.T<number>.md`. On completion, the dispatcher merges the node into `TRIAGE_GRAPH.md` and spawns the next agent with the updated graph as context. Worktrees give you isolation, checkpointing, and dedup via named node IDs.

### CI as a remote lab

CI is the lab. I don't own AMD RDNA4 hardware; tinygrad's CI does. Each perturbation is a commit on a draft PR: push, wait for CI, read the logs, classify the trajectory, update the graph, push again.

Locally, experiments are cheap: run the test, see the result in seconds. With CI-as-lab, each costs 10 minutes and one CI run. Every perturbation you skip because another agent already classified the node saves a run.

### Pacing

Perfect work can still fail. Flood a maintainer's inbox and the "AI slop" reflex fires before anyone reads the code. One clean PR per week earns trust; five per day earns a ban. [`/drip`](https://github.com/kimjune01/june.kim/blob/master/skills/drip/skill.md) throttles: one open PR per repo, 15-minute heartbeat, queue drains at the maintainer's pace.

Tone mismatch is subtler. A repo where merged PRs are terse one-liners ("fix X") rejects a three-paragraph explanation with benchmark tables, even if the content is correct. [`/drip`](https://github.com/kimjune01/june.kim/blob/master/skills/drip/skill.md) samples recently merged PRs and matches the voice: length, formatting, level of detail.

Scale added three problems: shared state, CI cost, social pacing. The graph solved the first; dedup the second; drip the third. Can it run unattended?

## Concurrent scale

The pipeline starts from issues. [`/actionable`](https://github.com/kimjune01/june.kim/blob/master/skills/actionable/skill.md) searches for maintainer-acknowledged problems with mechanical acceptance criteria:

- Bugs with reproducers
- Performance regressions with benchmarks
- "Help wanted" labels nobody claimed

Retro's parameters decide where to look next. Repos where PRs merge get more attention; repos on cooldown get skipped.

- **Sweep** finds candidates
- **Triage** kills the weak ones
- What survives gets an [**investigation**](/investigate)
- **Drip** throttles publication
- **Retro** compresses logs into the substrate

### Gemini at every interface

No human watches. Every handoff gets a gemini volley: send the output, apply feedback, re-send, up to five rounds.

- Triage scores items; gemini reviews the kill decisions
- Investigate diagnoses; gemini checks the causal chain
- Prework builds a fix; gemini checks it against the original issue
- Drip pushes; gemini reads the full PR as a maintainer seeing it cold

### The lineup

"I'm not reading anything written by AI." Format matching falls short. The goal: remove prose habits that make reviewers evaluate the author instead of the patch. Claude writes "clean" prose that's its own tell. No typos, no shortcuts, perfect parallel structure, hedges like "it's worth noting."

After tone matching, the PR body goes through a lineup: shuffle it with 5 real PRs from the repo, unlabeled, and ask a second model which one is AI. If it can't tell, pass. If it can, the explanation names the tells: "this one hedges where the others assert," "this one explains what the diff already shows." Fix the tells, re-shuffle, re-test. Five rounds max. [Detection is a wasting asset under feedback](/slop-detection): any checklist you give the rewriter becomes the exploit surface. The lineup diagnoses. If it's still detectable after five rounds, surface to the human. Some repos have a voice Claude can't fake.

### The bottleneck shifts

Without a review loop, [43% of LLM-generated PRs are merge-ready](/does-iteration-mitigate-slop-slope). With iterative cross-model review, 91%. Same code, same spec. The adversarial reviewer never converges to zero findings; it oscillates. The independent reviewer approves anyway. You don't finish kneading dough. You knead enough that the structure holds.

At scale, the bottleneck moves to issue creation. Maintainers filing bugs, users reporting regressions, benchmarks exposing gaps. That's the supply. Everything downstream of a well-filed issue is automatable. The issue itself is not.

The pipeline is [copyleft](https://github.com/kimjune01/sweep). Anyone can run it. Contributors running sweep concurrently, each with their own seeds, schemas, standing. Issues get found and fixed faster than any single maintainer could review. The merge history becomes a trust graph. Standing compounds. The pipeline is the contributor.

Every phase checks existing state before acting. Kill the process, restart tomorrow. The graph is the resume point. The [experiment artifacts](https://github.com/kimjune01/tinygrad-experiments) and the [pipeline state](https://github.com/kimjune01/sweep) (repos, triage graphs, drip queues, retro parameters) are public. Every skill emits structured logs; a dashboard snapshots pipeline state at any point.

The skills are public:

- [`/sweep`](https://github.com/kimjune01/june.kim/blob/master/skills/sweep/skill.md) — multi-repo triage
- [`/triage`](https://github.com/kimjune01/june.kim/blob/master/skills/triage/skill.md) — score, kill, investigate
- [`/investigate`](/investigate) — hypothesis graph on an engineered system
- [`/drip`](https://github.com/kimjune01/june.kim/blob/master/skills/drip/skill.md) — one PR at a time
- [`/retro`](https://github.com/kimjune01/june.kim/blob/master/skills/retro/skill.md) — compress logs into lessons
- [`/actionable`](https://github.com/kimjune01/june.kim/blob/master/skills/actionable/skill.md) — find work worth doing
- [`/review-schema`](https://github.com/kimjune01/june.kim/blob/master/skills/review-schema/skill.md) — profile a repo's review culture
- [`/dashboard`](https://github.com/kimjune01/june.kim/blob/master/skills/dashboard/skill.md) — live pipeline scoreboard

I am still unreasonable. When I hit the hard cases, the logs will show it and the skills, improved.

---

## Case study: tinygrad

14 PRs in 48 hours. 1 merged. The data:

| PR | Lines | Title | Outcome |
|---|---|---|---|
| [#16069](https://github.com/tinygrad/tinygrad/pull/16069) | +52/-3 | add Ops.WARP_REDUCE for GROUPTOP reductions | self-closed (behind master) |
| [#16070](https://github.com/tinygrad/tinygrad/pull/16070) | +52/-3 | add Ops.WARP_REDUCE for GROUPTOP reductions | "we never trade complexity for speed" |
| [#16072](https://github.com/tinygrad/tinygrad/pull/16072) | +3/-3 | increase matvec MV_ROWS_PER_THREAD 4→16 | "tuning this stuff is really annoying" |
| **[#16085](https://github.com/tinygrad/tinygrad/pull/16085)** | **-34** | **onnx: deduplicate simple proto parsers** | **MERGED in 56 seconds. "Cool!"** |
| [#16094](https://github.com/tinygrad/tinygrad/pull/16094) | +3/-3 | contiguous weights + rollout prune (12.4x speedup) | closed, no reviewer comment |
| [#16096](https://github.com/tinygrad/tinygrad/pull/16096) | +73/-7 | skip redundant root op check | "stop with AI PRs, you will be banned" |
| [#16104](https://github.com/tinygrad/tinygrad/pull/16104) | +78/-14 | improve post-TC heuristic | self-closed (failing tests) |
| [#16107](https://github.com/tinygrad/tinygrad/pull/16107) | +8/-11 | improve post-TC heuristic | "no on all heuristic changes" |
| [#16108](https://github.com/tinygrad/tinygrad/pull/16108) | +4/-1 | fix is_dtype_supported | "no regression tests" |
| [#16109](https://github.com/tinygrad/tinygrad/pull/16109) | +8/-11 | post-TC: UPCAST N + UNROLL K on gfx12 | closed, no comment |
| [#16111](https://github.com/tinygrad/tinygrad/pull/16111) | +1/-1 | fix MATVEC pattern | "I'm not reading anything written by AI" |
| [#16113](https://github.com/tinygrad/tinygrad/pull/16113) | +23/-0 | failing tests | "you are close to getting banned" |
| [#16116](https://github.com/tinygrad/tinygrad/pull/16116) | +12/-1 | MATVEC test and fix | "last warning before I ban you" |
| [#16117](https://github.com/tinygrad/tinygrad/pull/16117) | +11/-1 | PTX test and fix | "test passes in master too" (Qazalin) |

The merge ([#16085](https://github.com/tinygrad/tinygrad/pull/16085)): -34 lines, obvious dedup, zero questions needed. Merged in under a minute. The rejection trajectory: volume → AI detection → "I'm not reading" → ban warning. By PR #10, the maintainer was evaluating the contributor. [#16094](https://github.com/tinygrad/tinygrad/pull/16094) had an [18-hypothesis investigation](https://github.com/kimjune01/tinygrad-experiments/blob/master/realize/HYPOTHESIS_GRAPH.md) behind it, 12.4x speedup verified across backends and architectures, multi-turn correctness tested. Closed without a word.

I was the latest. A search for "AI slop" in tinygrad's PR comments turns up a graveyard:

- [#15491](https://github.com/tinygrad/tinygrad/pull/15491): 29% scheduling speedup, +46/-18, benchmarked, 434 tests passing. "DO NOT SUBMIT AI SLOP."
- [#14364](https://github.com/tinygrad/tinygrad/pull/14364): kernel optimizer. "AI slop, not worth considering."
- [#15553](https://github.com/tinygrad/tinygrad/pull/15553): CDNA4 fix. "AI slop, just close."
- [#15576](https://github.com/tinygrad/tinygrad/pull/15576): +3/-3. "lol early AI wrote those tests, but since there's tests, merged."

And a dozen more. The [style filter fires before the substance lands](/allergic-to-slop). #15576 is the tell: he knows, and merges when the diff is cheap enough to verify by inspection. The gate is attention cost.

---

## The hypothesis graph

The pipeline itself is a hypothesis. Here's the graph:

```
H0: Issue-first PRs merge at a higher rate than unsolicited PRs
  evidence for (own): 14 unsolicited PRs to tinygrad, 1 merged (7%).
    the merge (#16085, -34 lines) was a simplification — no issue, but the
    maintainer said "that old code never should have been merged." He was
    pre-committed to the problem even without an issue.
  evidence for (prior art):
    mvdan/sh: 15/15 external merges, all issue-linked or maintainer-invited.
    ruff #16519: 0/4 external attempts, all unsolicited scope creep.
    TypeScript #30408: 0/7 external attempts, no maintainer pre-commitment.
    marimo: 11/15 external merges, maintainer-acknowledged bugs.
  evidence against: gemini-cli #23341 merged (unsolicited bug fix, no issue).
  tally: 4 repos FOR, 1 AGAINST
  falsification: unsolicited PRs merge at the same rate as issue-linked,
    across 5+ repos
  status: CONFIRMED (deduced from prior art)

H1: Review schema conformance predicts merge outcome
  the one merge passed every signal: net-negative lines, obvious diff,
    no description needed. The rejections violated specific gates:
    #16108 — "there's no regression tests" (gate: tests)
    #16070, #16096 — "we never trade complexity for speed" (+39, +62 lines)
    #16107 — "no on all heuristic changes" (gate: domain — no heuristic PRs)
    #16072 — "tuning this stuff is really annoying" (gate: cross-device validation)
  evidence against: #16116 passed all technical gates, still rejected
  confound: standing (H2) may dominate after enough violations
  falsification: merge rate uncorrelated with schema conformance across 20+ PRs
  status: UNCONFIRMED

H2: Standing is a gate that supersedes technical quality
  evidence for (own): escalation across 14 PRs in 48 hours:
    #16070 — "be careful with AI usage" (warning from contributor)
    #16096 — "you need to stop with AI PRs, you will be banned"
    #16111 — "I'm not reading anything written by AI"
    #16116 — "last warning about low quality PRs before I ban you"
    by #16116 the standing gate was closed. Technical merit irrelevant.
  evidence for (prior art):
    tinygrad: octolixai — 4 PRs, all closed, never returned. Standing
      burned by volume before quality could be evaluated.
    Soar: 0/5 PRs engaged with, solo maintainer ignores externals entirely.
  analogue perturbation: antonmedv/fx — solo maintainer like tinygrad,
    but 70% external merge rate. Same review structure, opposite outcome.
    If our PR lands on fx, standing gate is maintainer-specific, not
    structural. If it doesn't, standing gate may be inherent to solo
    maintainer repos.
  falsification: burned-standing contributor submits schema-conforming PR
    and it merges
  dependency: H1
  status: UNCONFIRMED (needs fx outcome to disambiguate)

H3: Drip pacing prevents standing damage
  evidence for (own): 14 PRs in 48 hours preceded the ban warning.
    the escalation tracked volume, not quality — #16085 merged between
    the warnings, proving the code could pass. the volume couldn't.
  evidence for (prior art):
    tinygrad: octolixai submitted 4 PRs on Apr 17, all closed same day.
    click: 6-minute median review, high throughput — no volume warnings
      in history despite frequent external PRs. Fast review absorbs volume.
    mvdan/sh: steady contributor cadence (kolkov: 6 PRs over months,
      not days), zero volume warnings. Paced contributors merge.
  tally: 3 repos FOR, 0 AGAINST
  falsification: drip-paced contributor (1 PR per merge cycle) still
    warned for volume
  status: CONFIRMED (deduced from prior art)

H4: Framing affects outcome independently of code quality
  #16116 body: "I'm learning" — personal frame in a code-speaks-for-itself
    repo. Told the maintainer the repo was being used as a classroom.
  #16113 title: "Failing tests" — a PR of only tests, no fix. The maintainer
    said "a PR means I have spent serious human time reading this and 100%
    believe you are ready to just click merge." Tests alone aren't a PR.
  confound: standing was already burned by this point
  falsification: identical diffs, different framing, same outcome
  status: UNCONFIRMED

H5: Maintainers optimize for review efficiency, not correctness
  evidence for (own):
    #16085 merged in 56 seconds. -34 lines, obvious dedup, zero questions.
    #16108 rejected: "I don't understand what this does." 1-line fix, correct,
      but required the reviewer to build context. Cost him attention.
    #16094: 12.4x speedup, 18-hypothesis investigation. Closed without a word.
  evidence for (prior art):
    tinygrad #15491: 29% speedup, benchmarked, 434 tests passing. "AI SLOP."
      Quality irrelevant — review cost too high.
    TypeScript #30408: 7 external attempts, core team races externals on
      easy fixes (#21436 closed, #21435 by core team merged instead).
      Externals cost more attention than internal contributors.
    click: 6-min merges on trivial fixes. Review cost near zero = merge.
    mypy: core team merges own fixes while external PRs on same issue stall.
  tally: 5 repos FOR, 0 AGAINST
  falsification: a maintainer spends significant time reviewing and merging
    a PR that requires context-building to understand
  status: CONFIRMED (deduced from prior art)

H6: The pipeline produces higher merge rates than ad-hoc contribution
  depends on: H0, H1, H2, H3, H4, H5
  baseline: tinygrad — 1/14 merged (7%)
  target: >50% across 3+ repos
  status: UNCONFIRMED

edges:
  H0 (issue-first) → H6 (pipeline wins)
  H1 (schema) → H6
  H2 (standing) → H3 (pacing prevents damage)
  H4 (framing) → H1 (schema should include framing)
  H5 (efficiency) → H1 (schema should model reviewer cost, not just quality)
  H3 (pacing) → H6
```
