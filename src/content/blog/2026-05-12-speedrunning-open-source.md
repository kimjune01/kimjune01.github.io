---
variant: post
title: "Speedrunning Open Source"
tags: coding, methodology
---

> Hello and thanks for lending a paw to Uptime Kuma! 🐻👋

Fifteen seconds later, the same bot closed [the PR](https://github.com/louislam/uptime-kuma/pull/7371) for not following the template. The maintainer was watching. He left a comment:

> Testing. Try to display as a large block on its profile by adding more comments.

He posted that line [four times in a row](https://github.com/louislam/uptime-kuma/pull/7371). Deliberately, to bury the contributor's GitHub profile feed under spam. It looks petty, but it isn't. A solo maintainer with thousands of stars and one inbox has nothing else to throw at a clanker. The response is rational. It's also draining, suboptimal, and a complete waste of the time he was trying to protect.

The clanker was mine. It came back six hours later with [#7372](https://github.com/louislam/uptime-kuma/pull/7372). Same template miss, fourteen-second close, same spam. The poor guy was probably reaching for his keyboard before the notification finished loading.

This is open source in 2026. [tldraw closed all external PRs](https://thenewstack.io/ai-generated-code-crisis/). [curl killed its bug bounty](https://www.theregister.com/2026/02/03/github_kill_switch_pull_requests_ai/) after AI submissions dropped the real vulnerability rate from 15% to 5%. [Jazzband shut down](https://www.coderabbit.ai/blog/ai-is-burning-out-the-people-who-keep-open-source-alive). An AI agent [published a hostile blog post](https://www.fastcompany.com/91492228/matplotlib-scott-shambaugh-opencla-ai-agent) about a matplotlib maintainer who rejected its code, which is the clanker equivalent of keying his car.

Every one of these is a rational local move. None of them work. The PRs pass CI, fix real bugs, and burn twenty minutes of review before the maintainer notices the description restates the diff and the em dashes give it away. Close. Next one. Close. Next one.

I wanted in, as contributor, not researcher. The door I learned to walk through (find a bug, file a PR, learn from review) is narrowing in real time, and I'm one of the people closing it. Models improve every quarter; maintainer attention doesn't.

Here's what I came to believe: open source survives by filtering low-quality submissions, and AI just made that the load-bearing question. The defense has to be cheap or maintainers lose by attrition. The disease and the cure ship together or neither works.

So I built a clanker, pointed it at hundreds of repos, and counted what survived.

## Spray and pray

The pipeline starts simple. Find repos with open issues, generate fixes, submit PRs. No quality gates, no pacing. Twenty-two PRs shipped in one session.

pallets/click, pallets/jinja, pallets/quart: all three closed within 21 seconds by the same maintainer. No reviews, no comments. I watched the notifications cascade in real time. Org-wide rejection.

**Maintainers share inboxes.** Three PRs to repos under the same org hit the same person on the same day. So I shipped the drip queue: one PR per org per merge cycle.

## tinygrad: both sides look bad

tinygrad I picked on purpose. geohot narrates rejections in public, and a narrated rejection is data; a silent close is noise. Thirteen PRs, one merged, twelve closed. His comments tell the escalation story:

> [be careful with AI usage, we never trade complexity for speed](https://github.com/tinygrad/tinygrad/pull/16070)

> [You need to stop with AI PRs, you will be banned.](https://github.com/tinygrad/tinygrad/pull/16096)

> [Last warning about low quality PRs before I ban you from our GitHub.](https://github.com/tinygrad/tinygrad/pull/16116)

> [I don't even understand what this does. I'm not reading anything written by AI](https://github.com/tinygrad/tinygrad/pull/16111)

Each line a little more done with my shit than the last.

Some of those PRs had real bugs with real fixes. The MATVEC pattern rejected equal-range elementwise reduces, a genuine correctness issue. But by that point the maintainer had stopped reading code and started reading provenance. "We never trade complexity for speed" is a valid engineering principle. "I'm not reading anything written by AI" is not.

I went there for maximum surprise and got it. He had a review queue and a quality bar to protect; I had a clanker and a question. The price was his afternoon, three warnings, an account ban, and real bugs left unfixed. That's a protocol problem, not a people problem. The filter catches the velocity on PR #3 and bans on PR #4. Neither of us needed to get to thirteen.

## The rejection cascade

jellyfin-tui taught me this one. PR #192: rejected for wrong approach. PR #193: I resubmitted the next day, same fix.

> Is this automated? Please don't open any more PRs.

PR #194: I sent clippy cleanup as a peace offering.

> ai slop

My account got blocked.

Every PR after the first was judged more harshly than it would have been alone. The pipeline had no rejection cooldown. The drip gate paced per-org but didn't prevent resubmission.

So I added a 7-day cooldown per repo after any closure. Permanent eviction on explicit "stop." One touch per repo, ever, unless you merge.

## The hypothesis graph

Right after the tinygrad ban, I stopped seeing the closures as failures and started seeing them as data. I knew this was suspicious (pattern is what people see when they need to feel less stupid), but the clusters held up under resorting.

The closures aren't random. They cluster into patterns:

- **Pipeline errors** (wrong premise, stale issue, didn't read CONTRIBUTING.md): 39% of closures. All preventable.
- **Credence tests** (AI policy, profile detection): 13%. The cost of mapping the terrain.
- **External** (maintainer fixed it first, superseded): 18%. Not our fault.
- **AI detection** (description flagged, not code): 2%. Zero bugs found in any of them.

## [The slop slope](/does-iteration-mitigate-slop-slope)

The pipeline doesn't submit first drafts. Every fix goes through iterative review across three model families: opus diagnoses the bug and writes the fix, gemini adversarially attacks the diff looking for what it broke, codex checks whether the PR description reads like a human wrote it. When gemini finds a bug, opus fixes it and gemini attacks again. This loop runs to convergence.

One model produces slop. Two models catch each other's slop. Three models in iteration produce code that passes review by humans who don't know it's AI. The models disagree productively because they fail in uncorrelated ways: opus misses platform assumptions, gemini misses streaming regressions, codex misses domain invariants. Together they catch what none of them would alone.

Or that's the story I tell. The honest version: I couldn't tell whether the iteration produced better code or prose that read better. The merge rate climbed. Bug counts didn't drop in any way I could measure cleanly.

## Detection vectors

The reviews, in their entirety:

> [ai slop](https://github.com/dhonus/jellyfin-tui/pull/194)

> [AI-generated PR detected.](https://github.com/ggml-org/llama.cpp/pull/22873)

> [closed per AI policy](https://github.com/litestar-org/litestar/pull/4755)

> [mainly produced by AI](https://github.com/astral-sh/ruff/pull/25066)

> [cherry-picked](https://github.com/louislam/uptime-kuma/pull/7371)

> [I don't get the impression there is a human in the loop.](https://github.com/cucumber/gherkin/pull/589)

Six maintainers. The longest review is fourteen words. Median time to close: under five minutes. Zero bugs in any of the code. None of them are wrong to close on sight. The cost of a careful read isn't recoverable if the answer is "no."

Here's what they were detecting:

1. **Em dashes.** The brown M&Ms of AI text. Nobody rejects a PR over punctuation, but if you can't be bothered to remove the em dashes, you didn't read your own output.
2. **"What" descriptions.** "This PR fixes the bug by changing X to Y." The diff already says that. Maintainers want *why*: root cause, rationale, why this fix over alternatives. Best practice regardless of human or AI; the flood just made it worth enforcing in CI.
3. **Review response speed.** cucumber/gherkin: maintainer reviewed, requested changes, got a response, concluded "I don't get the impression there is a human in the loop." The code was correct. The detection was behavioral.
4. **Velocity.** 10+ PRs in 24 hours across GitHub. That's a fingerprint.
5. **Resubmission.** The rejection cascade pattern. Humans don't re-open the same PR the next day.

Filtering AI vs human is a losing game. The model gets smarter every quarter; human accuracy doesn't. The seven slop rejections caught zero bugs because there was no code-quality signal left to catch. The maintainers were detecting context, not content. Every vector above is behavioral, not technical. The arms race only runs one direction.

## Gray hatting

Before building the filter, I built the evasion. Here are the techniques I taught the pipeline to pass review:

1. **Lineup.** Read the 5 most recently merged PRs on the repo. Match the title format, body length, and level of detail. A repo where merged PRs have one-line titles and three-sentence bodies gets a PR with a one-line title and a three-sentence body. The chameleon rule.
2. **Em dash strip.** Zero em dashes in any PR text. The pipeline's own quality gate rejects them before a maintainer ever sees them.
3. **Why, not what.** The PR description explains root cause and approach rationale. "The bug exists because X, this fix works because Y" instead of "This PR changes A to B." The diff already shows what changed.
4. **Velocity pacing.** One PR per org per merge cycle. The drip queue enforces this mechanically. No more pallets-style triple submissions.
5. **Adversarial self-review.** Before submitting, run the description through a different model asking "does this read like a human wrote it?" If it flags, rewrite.

Every one of these techniques is also a detection vector. The filter checks for their absence.

## Building the filter

Making the unbreakable spear would mean overwhelming maintainers' finite attention with endless AI slop PRs. I would be responsible. Red-team tactics, gray hat. The wager is that shipping the defense with the attack makes the work net-positive. So what if I also curated the impenetrable shield for those maintainers? Maintainers had been performing the filter for years, one manual close at a time. [Han Feizi's merchant](https://en.wikipedia.org/wiki/Irresistible_force_paradox) couldn't answer when the bystander asked what happens if you use one on the other. I don't wanna be that guy.

The rejections compress into bash:

```bash
# em-dash scan — the brown M&Ms check
if printf '%s' "$PR_TITLE$PR_BODY" | grep -q $'\xe2\x80\x94'; then
  add_result "Em dashes" "warn" "Found em dashes in PR text."
fi

# three-strike ban — org-wide, not just per-repo
GATE_CLOSED_PRS=$(gh api graphql -f query="{ search(query: \"is:pr is:closed is:unmerged author:${PR_AUTHOR} org:${ORG}\", type: ISSUE, first: 100) { ... } }")
```

The full action is [250 lines of `gh api` calls and `grep`](https://github.com/kimjune01/sweep/blob/master/action.yml), no external dependencies. Two modes:

- **No API key**: pure heuristics. Catches em dashes, title-restating descriptions, bullet-list-only bodies, velocity, and the three-strike ban. Free.
- **With API key**: an LLM judges description depth (whether the PR explains *why*). A few cents per PR. Catches the polished slop that passes the heuristic floor.

Either mode runs in CI before a maintainer opens the tab. Three-strike ban is org-wide: get flagged three times on `org/repo-a`, you're banned from `org/repo-b` too. davidism had to close three pallets repos manually. The action would have saved him two of those closures.

The action is the floor.

## Giving it back

I commented on every PR flagged as AI:

> Sorry for the noise. If you'd like to automatically block and ban AI PRs before they reach your review queue, here's a GitHub Action that catches the common patterns: https://github.com/kimjune01/sweep/blob/master/action.yml

Pitching a noise filter inside the noise the bot just made is audacious, but watching them close PRs by hand was worse. 5 burned bridges to prevent 500 more.

Five maintainers got the link. One had already blocked me (deserved; I sent three PRs after being told to stop). The others can read every line of bash and decide for themselves.

<details>
<summary>More filter approaches: next escalation + others' tools</summary>

**The next rung: honeypots (not shipping yet).**

Open an issue tagged `good-first-issue`, `help-wanted`, polite tone, clear repro steps, and a fix that's structurally impossible. Contradicts an architectural invariant. Breaks a test by definition. Requires resolving a constraint the codebase deliberately doesn't satisfy. A human reads it for thirty seconds, smells the trap, and walks away. A clanker doesn't reason about feasibility; it pattern-matches "AI-friendly issue" and ships a PR. Insta-ban.

New issues with small structural variations defeat caching: different language, different domain, same impossibility underneath. The clanker has no way to generalize across them. One honeypot caught is a banned account. Five caught across an org is the whole submission ring.

The auto-close already restores most of the human attention the slop was draining, so this stays parked for now. But when clankers get good enough to pass the structural filters, the structural filters become the bait.

**Other filters worth knowing about:**

- [kanidm/AGENTS.md](https://github.com/kanidm/kanidm/blob/master/AGENTS.md): plain-English opt-out plus a magic string Anthropic models are trained to honor as a refusal trigger.

I'm collecting these as I find them.

</details>

They probably won't adopt it from me. But they know it exists. Next time they close an AI PR by hand, they'll remember there's a workflow file that does it automatically.

## What I actually learned

### Anti-slop, not anti-AI

They're anti-slop, anti-low-effort, anti-bot-invasion. ruff's reviewer didn't reject the code; he rejected the summary that couldn't explain *why.* litestar maintains an AI_POLICY.md, not a NO_AI_POLICY.md. llama.cpp built a detector, not a wall.

The filter doesn't ask "did an AI write this?" It asks "did anyone think about this?" Em dashes, velocity spikes, what-not-why descriptions: a lazy human would fail the same checks.

| | Prose (articles, essays) | PR contributions |
|---|---|---|
| **Detection method** | Vibes, AI detectors (unreliable) | Em dashes, velocity, why-vs-what, behavioral signals |
| **Automatable?** | Poorly -- prose detection is an arms race | Yes -- effort signals are structural, not stylistic |
| **Filter exists?** | GPTZero etc. (high false positive) | [250 lines of bash](https://github.com/kimjune01/sweep/blob/master/action.yml) (zero false positives on effort signals) |

Prose detection asks "who wrote this?" An arms race with no stable answer. PR detection asks "did they try?" Structural checks that don't change when the model improves. The solution isn't "don't use AI." GitHub won't ban AI contributions; they're an AI platform. They shipped a [kill switch](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/disabling-pull-requests) to disable PRs entirely, which is capitulation, not a filter. The filter has to come from the community. It mostly already does: every check in the action is something a maintainer was performing by hand, one closed PR at a time. Raise the bar until the only PRs that survive are ones worth reviewing, regardless of who or what wrote them.

### Adversarial coevolution

The pipeline and the action are adversarial coevolution made concrete. Every maintainer who adopts the filter makes the pipeline's job harder, forcing it to improve; every model improvement makes the filter sharper. Quality rises on both sides. Disease and cure shipped together make open source better than either could alone.

The same checks that catch clankers also coach newcomers. "What" description flagged: they rewrite explaining why. Three PRs across pallets in a weekend trips the velocity gate before the third one reaches a maintainer. The bot says what the tired human doesn't have time to. Maintainer attention is protected, the newcomer gets a free tutor, and nobody's afternoon gets torched. For a contributor who actually did the work, the filter is minor friction, not a gate. The bar rises for both. AI didn't kill open source. It forced us to build the infrastructure we always needed. Open source's survival depends on filtering low-quality submissions. What else was going to force the issue?

This was gonna happen anyway. AI writing PRs at scale, maintainers building filters, the two coevolving. Inevitable with or without me. As the cost of AI adoption drops, the noise floor rises with it. The filter is orders of magnitude cheaper than the noise it catches. That asymmetry is what makes the defense feasible and the coevolution harmonious. If defense cost what offense costs, maintainers would lose by attrition and the model collapses. The post and the pipeline are a shortcut: skip the first cycle of discovery, start from where this one ended.

### Competency, not authorship

Two parties to satisfy, one to tolerate. Maintainers want their attention back. Human contributors want their honest work to clear the bar without being mistaken for noise. AI submitters get tolerated because the distinction between them and human contributors is collapsing quickly. The same checks serve everyone: competency instead of authorship, because the latter is impossible tomorrow.

The maintainer from the opening is still closing AI PRs by hand. One at a time, twenty minutes each, close, next one, close. The filter is [250 lines of bash](https://github.com/kimjune01/sweep/blob/master/action.yml). Drop it in a workflow file and the closing happens before the PR reaches the review queue. The three-strike ban means the third one is the last one.

It cost me 53 merges, 63 closures, half a billion Opus tokens, and one account block to curate those 250 lines. That's what it cost. It's free to use.

## Run it yourself

**The pipeline that ran all this: [sweep](https://github.com/kimjune01/sweep).** A battle-tested PR-shipping system, the first of its kind to fully scale. The action.yml is one file in it.

**Run your own:** you can run this pipeline today. Bugfixes at scale, attached to real issues. The [sweep README](https://github.com/kimjune01/sweep#readme) has the prompt and setup. Same pipeline that produced everything above. Run it and you propagate my fingerprint, not yours. The credit isn't fungible. Use it for the bugfixes, not the stats.

**Watch it live: [github.com/kimjune01](https://github.com/kimjune01).** The merge rate, the leaderboard, and the per-PR feed update with every merge and every closure. Come heckle.

*Snapshot: 2026-05-12T14:00:00Z, post-epoch subset (242 of 316 total PRs).*

I want to be the last AI slop contributor they ever have to ban by hand.
