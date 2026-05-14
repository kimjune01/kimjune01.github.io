---
variant: post-medium
title: "Pledge, turn, prestige"
tags: pageleft, coding, methodology
---

*Every great magic trick consists of three parts. The pledge: the magician shows you something ordinary. The turn: the magician takes the ordinary thing and makes it do something extraordinary. The prestige: the part where you see it and refuse to believe.*

### The pledge

Sweep and triage work. The pipeline I run scans open issues across 200 OSS repos, picks ones worth fixing, opens a fork, runs a hypothesis graph against the bug, implements with TDD, sends the diff to two adversarial reviewers, ships the PR, handles maintainer pushback, and either merges or learns from the closure. End to end, no human in the orchestration loop.

The receipts are public. [181 hypothesis graphs](https://github.com/kimjune01/sweep/tree/master/repo-hypotheses) committed and dated. 47 PRs merged this month. One pushback today against an Envoy maintainer who flagged a clock-discontinuity concern; the pipeline tested the claim against Envoy's own JWT and OAuth2 code, found four file-line citations of the same trade-off resolved the same way, posted a two-line response with the full hypothesis graph linked. Maintainer hasn't replied yet, but the position is defensible without further input from me.

This is the ordinary thing. Autonomous PR submission is, mostly, a solved problem. The trick is that nobody noticed because the receipts arrived without ceremony.

### The turn

The pipeline is mostly orchestration shape, not raw model power. The hypothesis-graph format does most of the cognitive work: claim, perturbation, classify, follow the edge. The volley discipline catches what one model misses. The patience rule keeps standing. The receipt-as-attestation pattern unforgeable by lazy agents.

These are shapes. Shapes are distillable.

Take the 184 graphs and outcomes. Format as JSONL. Fine-tune a 7B model on next-node prediction. Pair it with a sniff-guard classifier trained on the same merge/close corpus. The agent generates PRs, the detector predicts whether each would merge, the agent rewrites until the detector clears. Both run on a MacBook.

This is Karpathy's [cognitive core](https://x.com/karpathy/status/1937902205765607626) at the smallest scale. Strip world knowledge, keep reasoning shape, bolt on tools (code search, test runner, gh CLI, escalation to Opus when uncertain). The model doesn't need to know that React is a JS library; it needs to know that when the test fails, the next perturbation is to read the failing assertion, classify whether the bug is in the implementation or the test, and follow the right edge.

The detector is the durable half. Models commoditize on an eighteen-month cycle; calibrated detectors trained on per-repo merge corpora don't, because every repo is its own taste. The agent is a research artifact that proves the format is trainable. The detector is infrastructure that ratchets.

What ratchets, exactly: train the detector on today's merged corpus, it enforces today's standards on tomorrow's PRs. Tomorrow's merged corpus reflects the new floor, next iteration enforces that. No coordination required. Same dynamic that gave us `-Wall` then `-Wextra` then `-Werror`. Untyped JS then TypeScript then `strict: true`. AI didn't lower the floor. It moved the floor from implicit to explicit and turned it into something every maintainer can install.

The trick is that the bench is the artifact.

### The prestige

Every dev runs the agent and detector locally.

You write prose specifying what you want. The local agent fans out, generates twenty PR variants in parallel, the detector filters; only variants predicted to merge survive. You see a slate of curated suggestions, pick one, write more prose. Your machine is your dev team. The job stops being typing syntax and becomes writing precise specifications and selecting outputs.

Code becomes a build artifact of prose, the way assembly became a build artifact of C in the 1970s. You don't write assembly anymore unless you're working on something the compiler can't handle. You won't write code anymore unless you're working on something the local agent can't handle. The category of "things the agent can't handle" shrinks every quarter.

Reviewer attention stays the bottleneck because human time doesn't scale, but the PRs reaching maintainers are pre-filtered against the public floor. The public floor is the detector. The detector keeps ratcheting up because every merge teaches it. Maintainers get the discipline they wouldn't have built without the AI flood; juniors get a calibrated bar to train against; cheap models have to clear the bar set by the slowest human in the loop, which keeps the bar honest.

PageLeft is the venue. The pipeline I run today is the externalized prototype: a single-dev version operating on other people's repos because that's where the historic merge data lives. The local-army version is the same machinery aimed inward. Same hypothesis graphs, same receipts, same volley QA. Different audience: the dev's own backlog instead of the OSS commons.

The magician knows that the audience refuses to believe the prestige until they see the bird again. So here it is. Today, [scverse/pertpy](https://github.com/scverse/pertpy/pull/970) had two security-shaped bugs in a fix I'd already shipped. The pipeline's QA volley caught them on re-review, regenerated the fix, attested the patch, and pushed it back to the same PR branch. I read the report afterward and approved the comment. That's the bird.

It can be cheaper. It can run on your machine. It can let you direct rather than type. The infrastructure to make that real is two artifacts: a small model trained on hypothesis-graph shape, and a detector trained on what your repos actually merge. Both exist in proto form. Distillation is the engineering work that ships them.

This is what I'm building at PageLeft. Watch closely.
