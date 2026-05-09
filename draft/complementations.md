# Complementations

There are people out there using AI to contribute to open source. They submit PRs with passing CI to repos they don't own, across multiple projects, without compensation. Some get merged. Some get "DO NOT SUBMIT AI SLOP." They keep going.

I know they exist because I found them in the graveyard. GitHub PR comments are searchable. The rejection language is consistent: "AI slop", "do not use AI", "I'm not reading anything written by AI." Behind each rejection is a diff that passed CI. The code was correct. The prose was wrong.

But the graveyard is just one source. The signal these people emit is detectable without looking at rejections:

1. PRs with passing CI on repos they don't own
2. Contributions across multiple projects, not just one
3. No visible compensation — no bounty, no contract, no employer mandate
4. Depth — not typo fixes, but investigations, bug finds, performance work

They have excess attention. Their AI codegen pipeline is cheap enough to spend without return. Their interests are adjacent to the repos they contribute to. They are early.

I am one of them. I submitted [14 PRs to tinygrad in 48 hours](/sweep-and-triage#case-study-tinygrad). One merged. The rest taught me more about open source review culture than a year of reading about it would have. I built a [pipeline](https://github.com/kimjune01/sweep) that finds issues, investigates them, shapes PRs to match the review culture, and ships one at a time. It runs while I sleep.

The pipeline is [copyleft](/general-intelligence). Anyone can run it. But running it alone is lonely. I went looking for others.

## What complementation means

Neither pipeline is complete alone. The AI can perceive, cache, triage, and transmit. The human can filter, attend, and consolidate. Together they [cover every slot](/general-intelligence#complementation). The curve cups upward because each cycle sharpens the next.

These people figured that out. Not from reading about it — from shipping PRs and getting rejected and shipping more. The proof of work is the contribution history. Not a blog post about AI workflows. The diffs.

## The index

This is a reading list, not a database. People who use AI openly, contribute to open source, and leave a public trail. Proof of work: PRs with passing CI. No self-nomination. No leaderboard. No score.

If you're on this list and want off, open an issue or email me. If you should be on it, the diffs will speak for themselves.

| Who | Writes at | About |
|---|---|---|
| [bones7456](https://github.com/bones7456) | [luy.li](https://luy.li) | Claude Code, self-hosted AI infra |
| [AkiKurisu](https://github.com/AkiKurisu) | [akikurisu.com](https://www.akikurisu.com) | agent harness design |
| [frankxai](https://github.com/frankxai) | [frankx.ai](https://frankx.ai) | multi-agent systems, sovereign AI |
| [leecalcote](https://github.com/leecalcote) | [layer5.io](https://layer5.io) | AGENTS.md, Claude Code, Gemini CLI |
| [corvid-agent](https://github.com/corvid-agent) | [corvidlabs](https://corvidlabs.github.io/corvid-agent/blog.html) | decentralized AI agents |
| [imran-siddique](https://github.com/imran-siddique) | [imransiddique.com](https://imransiddique.com) | agentic architecture, safety |
| [karlb](https://github.com/karlb) | [karl.berlin](https://www.karl.berlin) | LLMs + simpler software |
| [nooscraft](https://github.com/nooscraft) | [noos.blog](https://noos.blog) | AI-assisted PRs, agent news |
| [pbakaus](https://github.com/pbakaus) | [paulbakaus.com](https://paulbakaus.com) | Claude Code, creative coding |
| [Puppo](https://github.com/Puppo) | [delpuppo.net](https://blog.delpuppo.net) | local vs cloud AI |
| [pdurlej](https://github.com/pdurlej) | [pdurlej.pl](https://pdurlej.pl) | AI workflows, prompt engineering |
| [kimjune01](https://github.com/kimjune01) | [june.kim](https://june.kim) | cognition, contribution pipeline |

6045 GitHub contributors crawled. 76 had blogs. 16 posted in the last 6 months. 12 write about AI. The filter: rejected for AI-assisted contributions, active blog, at least one post substantially about LLMs or agents. The [crawler](https://github.com/kimjune01/june.kim/blob/master/scripts/complementations-crawler.sh) and [data](https://github.com/kimjune01/june.kim/blob/master/data/complementations.jsonl) are public.
