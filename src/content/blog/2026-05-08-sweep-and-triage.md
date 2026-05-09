---
variant: post-wide
title: "Sweep & Triage"
tags: coding, methodology
---

When I got [investigate](/investigate) working, I got excited. The [hypothesis graph](/the-hypothesis-graph), [fan-out](/fan-out) competing hypotheses, classify [evidence trajectories](/evidence-has-a-trajectory), run [prework](/prework), [bug-hunt](/bug-hunt) until convergence. It had produced a one-number PR with a 62-105% speedup and full provenance. I was eager to apply directly to a well-maintained repo. So I did.

A maintainer batch-closed everything and said "I'm not reading anything written by AI." The fixes were correct (net zero lines, 47-59% speedup) but the communication was wrong. Eleven PRs in two days. No tests. No tone matching. Any reasonable self-respecting engineer would take their attention elsewhere.

I am not reasonable and don't respect myself a lot. But I am tenacious. I knew the PRs weren't mergeable because my skills were weak, not because the methodology was wrong. I had the [evidence](/does-iteration-mitigate-slop-slope) that iterative review pushes merge-readiness from 43% to 91%. I had investigate for engineering automation. They weren't composing. What if they could?

## The turn

Then I scaled to five agents on five bugs in parallel, and the tree broke. Agent A discovered RDNA4's [WMMA](https://gpuopen.com/learn/using_matrix_core_amd_rdna4/) has different operand lane mapping than RDNA3. Agent B was about to push a perturbation assuming all AMD GPUs share the same mapping. Without the agents talking, B would waste a CI run discovering what A already knew.

Nodes are shared across investigations.

![Pipeline flow: sweep → triage → parallel investigate agents → hypothesis graph → lineup gate → drip, with retro reading logs from all stages](/assets/sweep-and-triage-pipeline.svg)

### Independent investigations aren't

The naive dispatcher is a router: read the issue list, assign each to an agent, collect results.

In one session I had two PRs open against the same heuristic in tinygrad. PR #16107 changed the post-tensor-core optimization from UPCAST M+N to UPCAST N only. PR #16109 tried a reduced UNROLL factor on the same code path. When CI showed UPCAST N alone broke AMD [gfx1201](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html), that finding applied to both PRs. The root cause was WMMA operand lane mapping, and any post-TC optimization that changed axis coverage would hit the same wall.

A dumb router would have two agents burning two CI runs on identical perturbations. The graph needs a single source of truth.

### The file is the data structure

A markdown file with named nodes. If another agent already classified the hypothesis, it skips the experiment and cites the existing node. If it discovers something affecting another investigation, it writes a cross-reference edge.

Agents don't write to the shared graph directly. Each agent gets a [git worktree](https://git-scm.com/docs/git-worktree) (its own branch, its own working copy) and writes to `TRIAGE_RESULT.T<number>.md`. When it completes, the dispatcher reads the result, merges the node into `TRIAGE_GRAPH.md` on the main branch, and spawns the next agent with the updated graph as context. Git branches give you isolation, checkpointing, and dedup via named node IDs.

### CI as a remote lab

CI is the lab. I don't own AMD RDNA4 hardware. tinygrad's CI does. Each perturbation is a commit on a draft PR: push, wait for CI, read the logs, classify the trajectory, update the graph, push again.

The cost model inverts. Locally, experiments are cheap: run the test, see the result in seconds. With CI-as-lab, each experiment costs 10 minutes and one CI run. Every perturbation you skip because another agent already classified the node saves a CI run.

### Pacing

The dispatcher can produce perfect work (failing tests, one-line fixes, full provenance) and still fail completely. Eleven PRs in two days got me banned from a repo.

The riskiest part of parallel agent triage is flooding a maintainer's inbox and triggering the "AI slop" reflex before anyone reads the code. One clean PR per week earns trust. Five PRs per day earns a ban.

The dispatcher needs a throttle. That throttle is `/drip`: one open PR per repo, 15-minute heartbeat, queue drains at the maintainer's pace. The pacing is encoded in the skill, not left to human discipline.

There's a subtler version of the same problem: tone mismatch. A repo where merged PRs are terse one-liners ("fix X") will reject a three-paragraph explanation with benchmark tables, even if the content is correct. `/drip` samples recently merged PRs and matches the voice before creating each PR: length, formatting, level of detail.

Scale introduced three problems the single-agent version didn't have: shared state, CI cost, and social pacing. The shared graph solved the first. Dedup solved the second. Drip solved the third. The question is whether it can run unattended.

## The prestige

The pipeline starts from issues, not repos. `/actionable` searches for maintainer-acknowledged problems with mechanical acceptance criteria: bugs with reproducers, performance regressions with benchmarks, "help wanted" labels on items nobody claimed. It reads retro's parameters to decide where to look next. Repos where PRs merge get more attention. Repos on cooldown get skipped.

Sweep finds candidates within each repo. Triage kills the weak ones. What survives gets an [investigation](/investigate). Drip throttles publication. Retro reads the logs after each cycle and compresses lessons into the substrate.

### Gemini at every interface

No human is watching. Every handoff between pipeline stages gets a gemini volley: send the output, apply feedback, re-send, up to five rounds. After triage scores items, gemini reviews the kill decisions. After investigate diagnoses, gemini checks the causal chain. After prework builds a fix, gemini checks it against the original issue. Before drip pushes, gemini reads the full PR package as if it were a maintainer seeing it cold. Each volley improves the work before it moves on.

### The lineup

"I'm not reading anything written by AI." Matching format isn't enough. The goal is to remove prose habits that make reviewers evaluate the author instead of the patch. Claude writes "clean" prose that's its own tell: no typos, no shortcuts, perfect parallel structure, hedges like "it's worth noting."

After tone matching, the PR body goes through a lineup: shuffle it in with 5 real PRs from the repo, unlabeled, and ask a second model to guess which one is AI. If it can't tell, the candidate passes. If it can, the explanation names the tells: "this one hedges where the others assert," "this one explains what the diff already shows." Rewrite to fix the specific tells, re-shuffle, re-test. Five rounds max. No rubric, no checklist. [Detection is a wasting asset under feedback](/slop-detection): any checklist you give the rewriter becomes the exploit surface. The lineup works because it diagnoses, not prescribes. If it's still detectable, surface to the human. Some repos have a voice Claude can't fake.

### The bottleneck shifts

The gemini volleys, the lineup, the test gate, the staleness check. Each one pushes the PR closer to what a maintainer would merge on first read. I [measured this](/does-iteration-mitigate-slop-slope): without a review loop, 43% of LLM-generated PRs are merge-ready. With iterative cross-model review, 91%. Same code, same spec. The loop is the difference. The adversarial reviewer never converges to zero findings; it oscillates. But the independent reviewer approves anyway. You don't finish kneading dough. You just knead enough that the structure is sound.

Run this on enough machines across enough repos and the bottleneck is no longer investigation, pacing, or review readiness. The bottleneck is issue creation. Maintainers filing bugs, users reporting regressions, benchmarks exposing performance gaps. That's the supply of work the pipeline consumes. Everything downstream of a well-filed issue is automatable. The issue itself is not.

The pipeline is [copyleft](https://github.com/kimjune01/sweep). Anyone can run it. An army of contributors all running sweep concurrently, each with their own seeds, their own review schemas, their own standing progression — issues get found and fixed at a rate no single maintainer could match. The merge history becomes a trust graph. Standing compounds across repos. The pipeline is the contributor.

Every phase checks existing state before acting. Kill the process, restart tomorrow. The graph is the resume point. The [experiment artifacts](https://github.com/kimjune01/tinygrad-experiments) from the tinygrad investigations are public. Every skill emits structured logs, so a dashboard snapshots the pipeline state at any point.

I am still not reasonable. I haven't hit the hard cases. Once I do, the logs will show it and the skills, improved.

## Case study: tinygrad

14 PRs in 48 hours. 1 merged. The data:

| PR | Lines | Title | Outcome |
|---|---|---|---|
| #16069 | +52/-3 | add Ops.WARP_REDUCE for GROUPTOP reductions | self-closed (behind master) |
| #16070 | +52/-3 | add Ops.WARP_REDUCE for GROUPTOP reductions | "we never trade complexity for speed" |
| #16072 | +3/-3 | increase matvec MV_ROWS_PER_THREAD 4→16 | "tuning this stuff is really annoying" |
| **#16085** | **-34** | **onnx: deduplicate simple proto parsers** | **MERGED in 56 seconds. "Cool!"** |
| #16094 | +3/-3 | contiguous weights + rollout prune (12.4x speedup) | closed, no reviewer comment |
| #16096 | +73/-7 | skip redundant root op check | "stop with AI PRs, you will be banned" |
| #16104 | +78/-14 | improve post-TC heuristic | self-closed (failing tests) |
| #16107 | +8/-11 | improve post-TC heuristic | "no on all heuristic changes" |
| #16108 | +4/-1 | fix is_dtype_supported | "no regression tests" |
| #16109 | +8/-11 | post-TC: UPCAST N + UNROLL K on gfx12 | closed, no comment |
| #16111 | +1/-1 | fix MATVEC pattern | "I'm not reading anything written by AI" |
| #16113 | +23/-0 | failing tests | "you are close to getting banned" |
| #16116 | +12/-1 | MATVEC test and fix | "last warning before I ban you" |
| #16117 | +11/-1 | PTX test and fix | "test passes in master too" (Qazalin) |

The merge (#16085): -34 lines, obvious dedup, zero questions needed. Merged in under a minute. The rejection trajectory: volume → AI detection → "I'm not reading" → ban warning. By PR #10, the maintainer was evaluating the contributor, not the code. #16094 had an [18-hypothesis investigation](https://github.com/kimjune01/tinygrad-experiments/blob/master/realize/HYPOTHESIS_GRAPH.md) behind it, 12.4x speedup verified across backends and architectures, multi-turn correctness tested. Closed without a word.

I wasn't the first. A search for "AI slop" in tinygrad's PR comments turns up a graveyard: #15491 (29% scheduling speedup, +46/-18, benchmarked, 434 tests passing — "DO NOT SUBMIT AI SLOP"), #14364 (kernel optimizer — "AI slop not worth considering"), #15553 (CDNA4 fix — "AI slop, just close"), and a dozen more. The [style filter fires before the substance lands](/allergic-to-slop). One PR (#15576, +3/-3) got through with "lol early AI wrote those tests, but since there's tests, merged." He knows. He merges when the diff is cheap enough to verify by inspection, regardless of tooling. The gate isn't AI — it's attention cost.

## The hypothesis graph

The pipeline itself is a hypothesis. Here's the graph:

```
H0: Issue-first PRs merge at a higher rate than unsolicited PRs
  evidence for: 14 PRs to tinygrad, all unsolicited. 1 merged (7%).
    the merge (#16085, -34 lines) was a simplification — no issue, but the
    maintainer said "that old code never should have been merged." He was
    pre-committed to the problem even without an issue.
  falsification: unsolicited PR merges faster than issue-linked PR,
    same repo, same contributor
  test: first 20 PRs from /sweep — track issue-linked vs unsolicited
  status: UNCONFIRMED

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
  escalation trajectory across 14 PRs in 48 hours:
    #16070 — "be careful with AI usage" (warning from contributor)
    #16096 — "you need to stop with AI PRs, you will be banned"
    #16111 — "I'm not reading anything written by AI"
    #16113 — "you are close to getting banned"
    #16116 — "last warning about low quality PRs before I ban you"
  by #16116 the standing gate was closed. The PR's technical merit
    was irrelevant — he was evaluating the pattern, not the patch.
  falsification: burned-standing contributor submits schema-conforming PR
    and it merges
  dependency: H1
  status: UNCONFIRMED

H3: Drip pacing prevents standing damage
  evidence for: 14 PRs in 48 hours preceded the ban warning.
    the escalation tracked volume, not quality — #16085 merged between
    the warnings, proving the code could pass. the volume couldn't.
  falsification: drip-paced contributor (1 PR per merge cycle) still
    warned for volume
  test: first 3 repos through /sweep — track time between PRs and
    maintainer sentiment
  status: UNCONFIRMED

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
  #16085 merged in 56 seconds. -34 lines, obvious dedup, zero questions.
  #16108 rejected: "I don't understand what this does." 1-line fix, correct,
    but required the reviewer to build context. Cost him attention.
  #16113: "a PR means I have spent serious human time." He's telling you
    the scarce resource. It's not code quality. It's his time.
  #16094: contiguous+prune fix for quantized GGUF inference. 12.4x speedup
    (10.5 → 130 tok/s). Tested across Q4_K_M and Q6_K, Metal and CUDA,
    MoE and SSM architectures. Multi-turn correctness verified. Memory
    impact benchmarked. 18 hypotheses in the investigation graph, most
    confirmed. Closed without a single reviewer comment. The most
    comprehensive performance fix in the batch, treated identically to
    the least.
  falsification: a maintainer spends significant time reviewing and merging
    a PR that requires context-building to understand
  status: UNCONFIRMED

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
