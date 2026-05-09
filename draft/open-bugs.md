# Open Bugs, Not Open Source

Open source says the code is yours. Open bugs says the problems are yours — if you can solve them. The maintainer keeps the architecture, the roadmap, the taste. You get the issue queue.

## The review schema

Every repo has a review culture. Most of it is unstated. I learned this by submitting 14 PRs to tinygrad in 48 hours and getting banned.

The review culture has three layers:

**Gates** are binary. Missing tests, red CI, unrebaseable branch — fail one and the PR dies without the maintainer reading the code. These are mechanical and detectable from PR history.

**Signals** are gradient. Diff size, line delta, description length, code clarity. The maintainer weighs them together. A larger diff with great clarity can beat a smaller one that's hard to read.

**Tiebreaker** is taste. When two PRs both pass gates and score equally on signals, what wins? "Makes it simpler" vs "makes it faster" vs "helps users." The tiebreaker leaks in the language maintainers use when they're happy.

Below all three is a fourth layer: **unstated gates**. Nine categories, all deducible from PR history:

1. **Standing** — who you are matters more than what you submit
2. **Volume** — too many, too fast triggers a spam response
3. **AI detection** — prose style triggers "not reading" reflex
4. **Domain ownership** — certain code areas are off-limits to outsiders
5. **Philosophy** — do you share their values
6. **In-group** — core team vs outsider, different standards
7. **Timing** — release freeze, maintainer bandwidth, mood
8. **Channel** — real decisions happen off-platform
9. **Hiring** — PRs are auditions, not contributions

Each is a hypothesis with a falsification condition. You don't induce them — you check each one against the PR history. The categories are finite. The test is mechanical.

## The case study

tinygrad's maintainer reviews PRs the same way his optimizer searches for kernel schedules: enumerate, glance, keep the obvious winners, discard anything that requires depth. No theory formation. No model of why a PR is good. Just: is this obviously correct in under 60 seconds?

I submitted a 12.4x speedup on quantized inference. Tested across backends, architectures, quantization formats. 18 hypotheses in the investigation graph, most confirmed. Multi-turn correctness verified. Memory impact benchmarked. Closed without a comment.

The one PR that merged: -34 lines, obvious dedup. Merged in 56 seconds. "Cool!"

The rejection trajectory across 14 PRs mapped the unstated gates precisely. Standing burned by volume. AI detection triggered by prose style. Philosophy violated by trading complexity for speed. Domain ownership violated by touching heuristics without cross-device CI. Each gate was detectable from the repo's own history before I submitted my first PR.

A search for "AI slop" in tinygrad's comments turns up a graveyard. #15491: 29% scheduling speedup, +46/-18, benchmarked, 434 tests passing — "DO NOT SUBMIT AI SLOP." One PR (#15576, +3/-3) got through: "lol early AI wrote those tests, but since there's tests, merged." The gate isn't AI. It's attention cost.

## The hierarchy

Maintainers optimize for review efficiency, not correctness. The scarce resource is attention, not code quality. A correct fix to a bug they didn't know about costs them *more* attention than an okay fix to an issue they already triaged. They have to context-switch into your problem, validate it exists, decide if it matters, *then* review the code.

An issue they opened? They already did the first three steps. You're only asking for the fourth.

The pipeline starts from issues, not code. Find maintainer-acknowledged problems with mechanical acceptance criteria. The issue is the buy-in. The PR is the delivery. No pitching, no pre-negotiation, no politics. If the contribution process requires anything the pipeline can't do — off-platform communication, design pre-approval, hiring-style evaluation — skip the repo entirely.

## Process depth

Not all repos are equal targets. The pipeline measures process depth: how deep does the review process go?

**Deep** — automated gates, external complex PRs merge, multi-round reviews, substantive rejections. The pipeline's investigation-backed PRs fit. High throughput capacity.

**Shallow** — no automated gates, one person is the gate. Glance-merge or glance-close. Throughput and latency capped at the maintainer's attention budget. Only obvious, tiny PRs pass.

When the quality gates are in the infrastructure (required reviews, CODEOWNERS, branch protection), the maintainer is freed from being the gate. PRs can merge without one person glancing at every one. When the maintainer *is* the gate, throughput is capped at their reading speed.

The pipeline prefers repos where the gates are in the infrastructure, not in one person's head.

## The trust graph

PR merges are directed trust edges. Maintainer M trusted contributor C enough to accept this change. Aggregated across repos, these edges form a graph.

The trust graph doesn't collapse to a flat score. Two contributors with the same centrality can occupy different positions — one bridges communities, one is deep in a subsystem, one reviews heavily but commits little. The graph preserves these as distinct facts. A recruiter can't sort by it. A hiring manager who wants to use it has to engage with the structure, which is the validation work credentials were designed to skip.

The credence economy is a compression scheme optimized for filtering at volume. What it discards is most of what's true about a person's work. The trust graph refuses to compress along that axis.

Issues carry a different signal than commits. Commits show who earned the right to write code. Issues show who earned the right to be heard. The person who writes clear bug reports, who tests fixes across platforms, who links related issues across projects — they're high-trust to maintainers but invisible in the commit graph.

## Finding each other

The tool I want is trust-rooted traversal. I supply seeds — people whose judgment I've validated. The system walks the public graph from there. No notification, no friend ceremony, no mutual follow. Just: given my trust, who's adjacent?

Clone a seed repo bloblessly. Walk the commit metadata — authors, committers, Reviewed-by trailers, Signed-off-by chains. For each interesting node, query GitHub for their other repos. For high-scoring repos, clone those too. The graph expands lazily along edges of demonstrated trust.

The walk is only as good as the seeds. That's a feature: the tool rewards having taste. A recruiter with no domain trust to seed gets nothing useful. A researcher who knows whose work matters gets a map of their adjacent unknown.

Copyleft, no hosting, no data storage, bring your own token. A pipe, not a platform. The walk is yours, the seeds are yours, the output is yours. Other people running it with different seeds get different graphs. There's no canonical view, no leaderboard, no score.

The difference between this and Klout: Klout collapsed a graph to a number and got gamed into irrelevance. This refuses to flatten. The output is a graph you read, not a rank you sort by.

Every model release, the prose tells that trigger "AI SLOP" get harder to detect. The gate has a shelf life. But the trust graph doesn't decay — it's structural, not stylistic. Who merged whose code, who responded to whose issues, who cited whose work. Those edges persist.

The maintainers who throw bones — who label issues "help wanted," who engage with outsiders, who merge on merit — they're the ones worth finding. The pipeline finds them. The trust graph connects them. The issues are the interface.

Open bugs. Not open source.
