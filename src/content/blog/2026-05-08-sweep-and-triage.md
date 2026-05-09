---
variant: post
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

After tone matching, the PR body goes through a lineup: shuffle it in with 5 real PRs from the repo, unlabeled, and ask a second model to guess which one is AI. If it can't tell, the candidate passes. If it can, the explanation names the tells: "this one hedges where the others assert," "this one explains what the diff already shows." Rewrite to fix the tells, re-shuffle, re-test. Five rounds max. If it's still detectable, surface to the human. Some repos have a voice Claude can't fake.

### The bottleneck shifts

The gemini volleys, the lineup, the test gate, the staleness check. Each one pushes the PR closer to what a maintainer would merge on first read. I [measured this](/does-iteration-mitigate-slop-slope): without a review loop, 43% of LLM-generated PRs are merge-ready. With iterative cross-model review, 91%. Same code, same spec. The loop is the difference. The adversarial reviewer never converges to zero findings; it oscillates. But the independent reviewer approves anyway. You don't finish kneading dough. You just knead enough that the structure is sound.

Run this on enough machines across enough repos and the bottleneck is no longer investigation, pacing, or review readiness. The bottleneck is issue creation. Maintainers filing bugs, users reporting regressions, benchmarks exposing performance gaps. That's the supply of work the pipeline consumes. Everything downstream of a well-filed issue is automatable. The issue itself is not.

Every phase checks existing state before acting. Kill the process, restart tomorrow. The graph is the resume point. The [experiment artifacts](https://github.com/kimjune01/tinygrad-experiments) from the tinygrad investigations are public. Every skill emits structured logs, so a dashboard snapshots the pipeline state at any point.

I am still not reasonable. I haven't hit the hard cases. Once I do, the logs will show it and the skills, improved.
