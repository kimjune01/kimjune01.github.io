---
variant: post
title: "Sweep & Triage"
tags: coding, methodology
---

I had one agent investigating one bug. The hypothesis graph was a tree: one parent, one kill condition, one edge to the next hypothesis. The agent walked the tree until the frontier closed or a fix shipped.

Then I scaled to five agents on five bugs in parallel, and the tree broke. Agent A discovered RDNA4's [WMMA](https://gpuopen.com/learn/using_matrix_core_amd_rdna4/) has different operand lane mapping than RDNA3. Agent B was about to push a perturbation assuming all AMD GPUs share the same mapping. Without the agents talking, B would waste a CI run discovering what A already knew.

The hypothesis graph is a graph. Nodes are shared across investigations.

![Pipeline flow: sweep → triage → parallel investigate agents → hypothesis graph → lineup gate → drip, with retro reading logs from all stages](/assets/sweep-and-triage-pipeline.svg)

## Independent investigations aren't

The naive dispatcher is a router: read the issue list, assign each to an agent, collect results. This works when investigations are independent.

In one session I had two PRs open against the same heuristic in tinygrad. PR #16107 changed the post-tensor-core optimization from UPCAST M+N to UPCAST N only. PR #16109 tried a reduced UNROLL factor on the same code path. When CI showed UPCAST N alone broke AMD [gfx1201](https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html), that finding applied to both PRs — the root cause was WMMA operand lane mapping, and any post-TC optimization that changed axis coverage would hit the same wall.

A dumb router would have two agents independently discovering the same failure. One pushes a perturbation, waits 10 minutes for CI, reads the logs, classifies the trajectory. Then the other pushes the same perturbation and waits the same 10 minutes. The graph needs a single source of truth.

## The file is the data structure

A markdown file with named nodes.

Each node has an ID, a status, and edges to other nodes:

```
H₀ₘ — novel graph shapes dominate
Claim: LLaMA inference has novel graph shapes on every prompt length
Perturbation: trace both implementations through decode/prefill
Shape: divergent against — symbolic variables handle all shapes
Kill: premise is wrong. Gap is not realize overhead.
Edge → H₁ₘ: if not realize overhead, what?
```

If another agent already classified the hypothesis, it skips the experiment and cites the existing node. If it discovers something affecting another investigation, it writes a cross-reference edge.

Agents don't write to the shared graph directly. Each agent gets a [git worktree](https://git-scm.com/docs/git-worktree) — its own branch, its own working copy — and writes to `TRIAGE_RESULT.T<number>.md`. When it completes, the dispatcher reads the result, merges the node into `TRIAGE_GRAPH.md` on the main branch, and spawns the next agent with the updated graph as context. Git branches give you isolation, checkpointing, and dedup via named node IDs for free.

## CI as a remote lab

CI is the lab. I don't own AMD RDNA4 hardware. tinygrad's CI does. Each perturbation is a commit on a draft PR: push, wait for CI, read the logs, classify the trajectory, update the graph, push again.

The cost model inverts. Locally, experiments are cheap: run the test, see the result in seconds. With CI-as-lab, each experiment costs 10 minutes and one CI run. Every perturbation you skip because another agent already classified the node saves a CI run. Given those constraints, the system needs structure.

## The pipeline

Discover feeds the pipe — it reads retro's parameters (merge rates, cooldowns, maintainer responsiveness) and decides which repos to sweep next. Repos where PRs merge get more attention. Repos on cooldown get skipped. Adjacent repos in the same org get explored. The pipeline feeds itself.

Sweep finds candidates within each repo. Triage kills the weak ones — hardware-only issues, feature requests nobody endorsed, competing PRs. What survives gets a [hypothesis graph](/the-hypothesis-graph) built by [investigate](/investigate): [fan-out](/fan-out) competing hypotheses, classify [evidence trajectories](/evidence-has-a-trajectory), run [prework](/prework), [bug-hunt](/bug-hunt) until convergence. Drip throttles publication — one open PR per repo, queue drains at the maintainer's pace. Retro reads the logs after each cycle and compresses lessons into the substrate: memory entries, parameter files, skill patches. Without it, the pipeline repeats the same mistakes.

## Test before fix

The first version of this system shipped fixes without tests. A maintainer batch-closed everything and said "I'm not reading anything written by AI." The fixes were correct — net zero lines, 47-59% speedup — but the communication was wrong. That stung, but he was right: a fix without a failing test is an assertion without evidence; a failing test is a claim the reviewer can verify in one command.

The workflow is now: reproduce the bug, write a test, write the fix. The test must fail on master and pass with the fix. I learned this the hard way twice — first the fixes without tests, then a test that passed on master. A reviewer ran it and pointed out it proved nothing. It was checking the wrong code path. Now the drip queue won't push a candidate until both checks pass locally.

## The risk nobody warns you about

The dispatcher can produce perfect work — failing tests, one-line fixes, full provenance — and still fail completely. Eleven PRs in two days got me banned from a repo. The methodology was sound. The pacing was wrong.

The riskiest part of parallel agent triage is flooding a maintainer's inbox and triggering the "AI slop" reflex before anyone reads the code. One clean PR per week earns trust. Five PRs per day earns a ban.

The dispatcher needs a throttle. That throttle is `/drip`: one open PR per repo, 15-minute heartbeat, queue drains at the maintainer's pace. The pacing is encoded in the skill, not left to human discipline.

There's a subtler version of the same problem: tone mismatch. A repo where merged PRs are terse one-liners ("fix X") will reject a three-paragraph explanation with benchmark tables, even if the content is correct. `/drip` samples recently merged PRs and matches the voice before creating each PR: length, formatting, level of detail.

## The lineup

Matching format isn't enough. The goal is to remove prose habits that make reviewers evaluate the author instead of the patch. Claude writes "clean" prose that's its own tell — no typos, no shortcuts, perfect parallel structure, hedges like "it's worth noting." The format can be right and the voice still screams generated.

After tone matching, the PR body goes through a lineup: shuffle it in with 5 real PRs from the repo, unlabeled, and ask a second model to guess which one is AI. If it can't tell, the candidate passes. If it can, the explanation names the tells — "this one hedges where the others assert," "this one explains what the diff already shows." Rewrite to fix the tells, re-shuffle, re-test. Two rounds max. If it's still detectable, surface to the human. Some repos have a voice Claude can't fake.

## Dry run

The dispatcher has two modes. Full run creates PRs, opens issues, pushes to CI. Dry run does everything locally — agents spawn, investigate, write tests, produce fixes — but nothing touches a remote. Drafts land in a local directory, ready to ship when you remove the flag. Every skill emits structured logs, so a dashboard can snapshot the pipeline state at any point — repo statuses, drip queues, triage progress, recent events.

The investigation is valuable before you decide to publish it. Each agent produces a hypothesis graph, a failing test, and a candidate fix. You review locally, ship what's worth submitting. The human reviews the graph before the diff, so the diff arrives with provenance.

## Idempotent by design

Every phase checks existing state before acting. The graph file has a Status column — PENDING, IN_PROGRESS, CONFIRMED, KILLED, BLOCKED, SHIPPED. An agent that picks up a CONFIRMED node skips it. A dispatcher that resumes after a crash reads the graph and picks up where it left off.

Kill the process, restart tomorrow — the graph is the resume point.

## Open edges

I've used this for one session across two PRs, then scaled to five parallel agents across five issues. The [experiment artifacts](https://github.com/kimjune01/tinygrad-experiments) from the tinygrad investigations are public — hypothesis graphs, benchmark scripts, prework directories. Codex found real problems in the skill definitions — those are fixed now. Open questions:

- How do you garbage-collect the graph? Nodes from closed investigations are noise for future runs.
- Cross-repo findings are post-hoc summaries. Live propagation would require a feedback loop from sweep into running triage agents. I haven't built this. Post-hoc summaries haven't missed anything expensive yet.

The hypothesis graph was designed for one investigator walking one path. Extending it to parallel agents required exactly one structural change: per-agent result files merged by the dispatcher.

Everything else — trajectory classification, kill conditions generating edges, the graph as checkpoint — transferred without modification. I haven't hit the hard cases yet.
