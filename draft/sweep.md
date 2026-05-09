---
variant: post
title: "Sweep"
tags: coding, methodology
---

I had one agent investigating one bug. The hypothesis graph was a tree: one parent, one kill condition, one edge to the next hypothesis. The agent walked the tree until the frontier closed or a fix shipped.

Then I scaled to five agents on five bugs in parallel, and the tree broke. Agent A discovered RDNA4's WMMA has different operand lane mapping than RDNA3. Agent B, on a different PR, was about to push a perturbation assuming all AMD GPUs share the same mapping. Without the agents talking, B would waste a CI run discovering what A already knew.

The hypothesis graph is a graph. Nodes are shared across investigations.

## Independent investigations aren't

The naive dispatcher is a router: read the issue list, assign each to an agent, collect results. This works when investigations are independent.

In one session I had two PRs open against the same heuristic in tinygrad. PR #16107 changed the post-tensor-core optimization from UPCAST M+N to UPCAST N only. PR #16109 tried a reduced UNROLL factor on the same code path. When CI showed UPCAST N alone broke AMD gfx1201, that finding applied to both PRs — the root cause was WMMA operand lane mapping, and any post-TC optimization that changed axis coverage would hit the same wall.

A dumb router would have two agents independently discovering the same failure. One pushes a perturbation, waits 10 minutes for CI, reads the logs, classifies the trajectory. Then the other pushes the same perturbation and waits the same 10 minutes.

## The file is the data structure

The solution sounds too simple: a markdown file with named nodes.

Each node has an ID (`T16107.H0.6a`), a status (ALIVE, CONFIRMED, KILLED), and edges to other nodes. Before designing a perturbation, an agent reads the file. If another agent already classified the hypothesis, it skips the experiment and cites the existing node. If it discovers something affecting another investigation, it writes a cross-reference edge.

Agents don't write to the shared graph. Each agent gets a git worktree — its own branch, its own working copy. The agent writes to `TRIAGE_RESULT.T<number>.md` in that branch. When it completes, the dispatcher reads the result and merges the node into `TRIAGE_GRAPH.md` on the main branch, then spawns the next agent into the freed slot with the updated graph as context. No concurrent writes to the same file. Git branches are the source of truth; the dispatcher serializes the merge.

Named node IDs handle dedup. The graph file handles checkpointing. Git handles isolation.

## CI as a remote lab

CI is the lab. I don't own AMD RDNA4 hardware. tinygrad's CI does. Each perturbation is a commit on a draft PR. Push, wait for CI, read the logs, classify the trajectory, update the graph, push the next perturbation.

The cost model inverts. Locally, experiments are cheap: run the test, see the result in seconds. With CI-as-lab, each experiment costs 10 minutes and one CI run. The hypothesis graph earns its keep here: every perturbation you skip because another agent already classified the node saves a CI run.

## Six roles, five skills

The pipeline maps to six roles from the [Natural Framework](/the-natural-framework): perceive, cache, filter, attend, consolidate, transmit. The same shape that runs in neurons, immune systems, and evolution.

**Sweep** perceives: scan repos, read issues, discover what exists.

**Triage** caches and filters: score, categorize, kill what can't produce a merge, investigate what can. The kill list is the filter: hardware-only issues, feature requests nobody endorsed, competing PRs. What survives has a readiness record: branch, base commit, failing test command, passing test command.

**Drip** attends and transmits: select which candidate to push, match the repo's tone, push the PR. Attend (selection judgment) and transmit (side effect) are fused because splitting them would be overengineering.

**Retro** is the backward pass: read logs from every skill, lossy-compress into durable artifacts. Memory entries for cross-session lessons. Parameter files for repo-specific tuning. Skill definition patches when a lesson changes how the pipeline operates. Without it, the pipeline repeats the same mistakes.

The composition is: `sweep(repos) = foreach(repo, drip(investigate(triage(repo))))`, with `/retro` reading the logs after each cycle and compressing them into the substrate. Each function is idempotent. The pipeline is a chain of checkpoints.

The human reviews hypothesis graphs, not diffs. The diff is a consequence of the graph's surviving nodes — if the graph holds, so does the diff.

## Test before fix

The first version of this system shipped fixes without tests. A maintainer batch-closed everything and said "I'm not reading anything written by AI." The fixes were correct — net zero lines, 47-59% speedup — but the communication was wrong. That stung, but he was right: a fix without a failing test is an assertion without evidence; a failing test is a claim the reviewer can verify in one command.

The workflow is now: reproduce the bug, write a test, write the fix. Then verify: the test must fail on master and pass with the fix. Ship both in one PR with green CI. "Fail on master, pass with fix" is the assertion every PR makes.

I learned this the hard way twice. First by shipping fixes without tests. Then by shipping a test that passed on master — a reviewer ran it and pointed out it proved nothing. The test was checking the wrong code path. Now the drip queue won't push a candidate until both checks pass locally.

## The risk nobody warns you about

The dispatcher can produce perfect work — failing tests, one-line fixes, full provenance — and still fail completely. Eleven PRs in two days got me effectively banned from a repo. The methodology was sound. The pacing was wrong.

The riskiest part of parallel agent triage is flooding a maintainer's inbox and triggering the "AI slop" reflex before anyone reads the code. One clean PR per week builds contributor gravity. Five PRs per day builds a ban.

The dispatcher needs a throttle. That throttle is `/drip`: one open PR per repo, 15-minute heartbeat, queue drains at the maintainer's pace. The pacing is encoded in the skill, not left to human discipline.

There's a subtler version of the same problem: tone mismatch. A repo where merged PRs are terse one-liners ("fix X") will reject a three-paragraph explanation with benchmark tables, even if the content is correct. `/drip` samples recently merged PRs and matches the voice before creating each PR: length, formatting, level of detail.

But matching format isn't enough. Claude writes "clean" prose that's its own tell — no typos, no shortcuts, perfect parallel structure, hedges like "it's worth noting." The format can be right and the voice still screams generated. So after tone matching, the PR body goes through a lineup: shuffle it in with 5 real PRs from the repo, unlabeled, and ask a second model to guess which one is AI. If it can't tell, the candidate passes. If it can, the explanation names the tells — "this one hedges where the others assert," "this one explains what the diff already shows." Rewrite to fix the tells, re-shuffle, re-test. Two rounds max. If it's still detectable, surface to the human. Some repos have a voice Claude can't fake.

## Dry run

The dispatcher has two modes. Full run creates PRs, opens issues, pushes to CI. Dry run does everything locally — agents spawn, investigate, write tests, produce fixes — but nothing touches a remote. Draft descriptions land in a local directory, ready to ship when you remove the flag.

The investigation is valuable before you decide to publish it. Five agents on five bugs produce five hypothesis graphs, five failing tests, five candidate fixes. You review locally, decide which are worth submitting, and ship only those.

## Idempotent by design

Every phase checks existing state before acting. The graph file has a Status column — PENDING, IN_PROGRESS, CONFIRMED, KILLED, BLOCKED, SHIPPED. An agent that picks up a CONFIRMED node skips it. A dispatcher that resumes after a crash reads the graph and picks up where it left off.

Running the dispatcher twice produces the same output. This is what makes it safe to interrupt: kill the process, restart tomorrow, and it resumes from the checkpoint. The graph is the checkpoint.

## Open edges

I've used this for one session across two PRs, then scaled to five parallel agents across five issues. Codex reviewed the skill definitions and found eight real problems: triage was creating PRs when that job belonged to drip, state paths disagreed across skills (`.json` vs `.jsonl`, inconsistent `/tmp` locations), parallel agents wrote to the same file, and retro's output wasn't wired back into the forward pass. Those are fixed now. Open questions:

- How do you garbage-collect the graph? Nodes from closed investigations are noise for future runs.
- Cross-repo findings are post-hoc summaries. Live propagation would require a feedback loop from sweep into running triage agents. Worth building only if the post-hoc version misses something expensive.

The hypothesis graph was designed for one investigator walking one path. Extending it to parallel agents required exactly one structural change: per-agent result files merged by the dispatcher.

Everything else — trajectory classification, kill conditions generating edges, the graph as checkpoint — transferred without modification. I think the abstraction is right. I also haven't hit the hard cases yet.
