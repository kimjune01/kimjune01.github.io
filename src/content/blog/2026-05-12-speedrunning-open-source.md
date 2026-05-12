---
variant: post
title: "Speedrunning Open Source"
tags: coding, methodology
---

I spent four days submitting AI-generated pull requests to open source repos. 53 merged. 63 closed. 7 flagged as AI slop. One account blocked. Then I built the filter and gave it to the maintainers I hit.

This is what I learned.

## Day 1: spray and pray

The pipeline starts simple. Find repos with open issues, generate fixes, submit PRs. No quality gates, no pacing. Twenty-two PRs shipped in one session.

The results are immediate and brutal. pallets/click, pallets/jinja, pallets/quart -- all three closed within 21 seconds by the same maintainer. No reviews, no comments. Org-wide rejection.

First lesson: **maintainers share inboxes.** Three PRs to repos under the same org hit the same person on the same day. The drip queue is born -- one PR per org per merge cycle.

## Day 2: the hypothesis graph

The closures aren't random. They cluster into patterns:

- **Pipeline errors** (wrong premise, stale issue, didn't read CONTRIBUTING.md): 39% of closures. All preventable.
- **Credence tests** (AI policy, profile detection): 13%. The cost of mapping the terrain.
- **External** (maintainer fixed it first, superseded): 18%. Not our fault.
- **AI detection** (description flagged, not code): 2%. The interesting one.

Each pattern becomes a hypothesis. H0: quality-gated AI contributions are indistinguishable from human ones. H2: prior standing increases merge probability. H5: solo maintainers merge boring fixes. H8: trivial fixes merge faster than excellent fixes to complex bugs.

The hypothesis graph is the research instrument. Every PR is a measurement. Every closure is evidence.

## The merge profile

The pattern in the data is clear. What merges:

- Net-deletion PRs: 100% merge rate. Removing dead code is the safest contribution.
- Solo maintainer, <500 stars, boring fix: highest probability. The maintainer reads the diff, not your profile.
- Review iteration PRs: high merge rate. Responding well to feedback demonstrates competence. The review itself is the standing.

What doesn't merge:

- GUI/TUI repos. The agent can't see the screen. Bug-hunt correctly diagnosed jellyfin-tui's dirty-flag architecture, but the pipeline still shipped the wrong fix. Twice. Then a third time. Maintainer response escalated from technical rejection to "Is this automated?" to "ai slop."
- Large multi-maintainer repos without standing. They screen contributors before reading code.
- Anything that requires domain architecture knowledge the agent doesn't have.

## The rejection cascade

jellyfin-tui is the case study. PR #192: rejected for wrong approach. PR #193: resubmitted the next day, same fix. Maintainer: "Is this automated? Please don't open any more PRs." PR #194: submitted clippy cleanup as a peace offering. Maintainer: "ai slop." Account blocked.

Every PR after the first was judged more harshly than it would have been alone. The pipeline had no rejection cooldown -- the drip gate paced per-org but didn't prevent resubmission after rejection.

The fix: 7-day cooldown per repo after any closure. Permanent eviction on explicit "stop." One touch per repo, ever, unless you merge.

## Detection vectors

The code is not the problem. All seven "AI slop" rejections had zero bugs in the code itself. What gets detected:

1. **Em dashes.** The brown M&Ms of AI text. Nobody rejects a PR over punctuation, but if you can't be bothered to remove the em dashes, you didn't read your own output.
2. **"What" descriptions.** "This PR fixes the bug by changing X to Y." The diff already shows that. Maintainers want to know *why* -- root cause, approach rationale, why this fix over alternatives.
3. **Review response speed.** cucumber/gherkin: maintainer reviewed, requested changes, got a response, concluded "I don't get the impression there is a human in the loop." The code was correct. The detection was behavioral.
4. **Velocity.** 10+ PRs in 24 hours across GitHub. That's a fingerprint.
5. **Resubmission.** The rejection cascade pattern. Humans don't re-open the same PR the next day.

## Building the filter

Every rejection teaches a specific lesson. The lessons compress into bash:

```yaml
# action.yml — the whole thing, inline, no external scripts
- name: Run quality checks
  run: |
    # 0. Three-strike ban: 3+ gate closures = auto-ban
    # 1. Em-dash scan
    # 2. Description depth (why, not what)
    # 3. CONTRIBUTING.md compliance
    # 4. Test presence
    # 5. Contributor velocity
```

The action is 250 lines of `gh api` calls and `grep`. No external dependencies. No obfuscation. Drop it in a workflow file, it works. API key optional -- the heuristic path catches the laziest patterns without any LLM.

Three-strike ban is org-wide. Get flagged three times on `org/repo-a`, you're banned from `org/repo-b` too. davidism had to close three pallets repos manually. The action would have saved him two closures.

## Giving it back

I commented on every PR that got flagged as AI:

> Sorry for the noise. If you'd like to automatically block and ban AI PRs before they reach your review queue, here's a GitHub Action that catches all the common patterns: https://github.com/kimjune01/sweep/blob/master/action.yml

Five maintainers got the link. One had already blocked me (jellyfin-tui -- too late, lesson learned). The other five can read every line of bash and decide for themselves.

Will any of them adopt it? Probably not from me. But they know the filter exists now. Next time they close an AI PR by hand, they'll remember there's a workflow file that does it automatically.

## The numbers

| Metric | Value |
|--------|-------|
| Merged | 53 |
| Closed | 63 |
| Merge rate | 46% |
| Distinct repos | 40 |
| AI slop rejections | 7 |
| Bugs in "slop" PRs | 0 |
| Days | 4 |

The merge rate is honest. The feed on my GitHub profile shows closures too, not just merges. The slop table lists every rejection with time-to-close and bug count. The hypothesis graph has full evidence chains.

## What I actually learned

The maintainers who flagged my PRs aren't anti-AI. They're anti-slop, anti-low-effort, anti-bot-invasion. ruff's reviewer didn't reject the code -- he rejected the summary that couldn't explain *why.* litestar maintains an AI_POLICY.md, not a NO_AI_POLICY.md. llama.cpp built a detector, not a wall.

The filter doesn't ask "did an AI write this?" It asks "did anyone think about this?" Em dashes, velocity spikes, what-not-why descriptions -- those are all things a lazy human would also fail.

The pipeline and the action are adversarial training partners. Every maintainer who adopts the filter makes the pipeline's job harder, which forces the pipeline to get better. The floor rises for everyone.

## The cost

This research cost about $10k in API tokens over four days. Twenty parallel opus agents for QA, gemini volleys on every diff, codex crosschecks on every PR description, triage sweeps across hundreds of repos. You can't run this on a subscription plan.

I didn't apply for a grant. I had access to corporate tokens and a question worth answering. The best research happens when someone with the right tools and the right curiosity doesn't wait for permission.

Most people protect their token spend. Most people can't afford to do this. That's the moat -- the methodology is public, the hypothesis graph is open, the action is free. But nobody else is going to burn $10k to replicate it. The token spend is the experiment, not the write-up.

Gray-hat red-teaming only works if you also give them the cure for the poison.
