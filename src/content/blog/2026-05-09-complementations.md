---
variant: post-medium
title: "Complementations"
tags: cognition, methodology
---

People point their AI at open source repos and contribute. PRs with passing CI, repos they don't own, multiple projects, no compensation. Some get merged. Some get "DO NOT SUBMIT AI SLOP." They keep going.

I found them in the graveyard. GitHub PR comments are searchable. The rejection language is consistent: "AI slop", "do not use AI", "I'm not reading anything written by AI." Behind each rejection, a diff that passed CI. Code correct. Prose wrong.

But the graveyard is just one source. The signal is readable without looking at rejections:

1. PRs with passing CI on repos they don't own
2. Contributions across multiple projects
3. No visible compensation — no bounty, no contract, no employer mandate
4. Depth: investigations, bug finds, performance work

Excess attention, tooling good enough to give away, interests adjacent to the repos they contribute to. Early.

One of them. [14 PRs to tinygrad in 48 hours](/sweep-and-triage#case-study-tinygrad), one merged, the rest more instructive than a year of reading. Built a [pipeline](https://github.com/kimjune01/sweep) that finds issues, investigates them, shapes PRs to match the review culture, ships one at a time. Runs while I sleep.

## What complementation means

Neither pipeline is complete alone. The AI perceives, caches, triages, and transmits; the human filters, attends, and consolidates. Together they [cover every slot](/general-intelligence#complementation). Each cycle sharpens the next. The curve cups upward.

These people figured that out by shipping PRs and getting rejected and shipping more. The proof of work is the contribution history. The diffs.

## The index

A reading list. People who use AI openly, contribute to open source, and leave a public trail. Proof of work: PRs with passing CI. No self-nomination. No leaderboard. No score.

If you're on this list and want off, open an issue or email me. If you should be on it, the diffs will speak for themselves.

| Who | Writes at | About |
|---|---|---|
| [bones7456](https://github.com/bones7456) | [luy.li](https://luy.li) | Claude Code, self-hosted AI infra |
| [AkiKurisu](https://github.com/AkiKurisu) | [akikurisu.com](https://www.akikurisu.com) | agent harness design |
| [frankxai](https://github.com/frankxai) | [frankx.ai](https://frankx.ai) | multi-agent systems, sovereign AI |
| [leecalcote](https://github.com/leecalcote) | [layer5.io](https://layer5.io) | AGENTS.md, Claude Code, Gemini CLI |
| [imran-siddique](https://github.com/imran-siddique) | [imransiddique.com](https://imransiddique.com) | agentic architecture, safety |
| [karlb](https://github.com/karlb) | [karl.berlin](https://www.karl.berlin) | LLMs + simpler software |
| [nooscraft](https://github.com/nooscraft) | [noos.blog](https://noos.blog) | AI-assisted PRs, agent news |
| [pbakaus](https://github.com/pbakaus) | [paulbakaus.com](https://paulbakaus.com) | Claude Code, creative coding |
| [Puppo](https://github.com/Puppo) | [delpuppo.net](https://blog.delpuppo.net) | local vs cloud AI |
| [pdurlej](https://github.com/pdurlej) | [pdurlej.pl](https://pdurlej.pl) | AI workflows, prompt engineering |
| [kimjune01](https://github.com/kimjune01) | [june.kim](https://june.kim) | cognition, contribution pipeline |

6045 GitHub contributors crawled on May 9, 2026. 76 had blogs. 16 posted in the last 6 months. 11 write about AI. These are the ones the crawler found so far. The filter: rejected for AI-assisted contributions, active blog, at least one post substantially about LLMs or agents. The [crawler](https://github.com/kimjune01/june.kim/blob/master/scripts/complementations-crawler.sh) and [data](https://github.com/kimjune01/june.kim/blob/master/data/complementations.jsonl) are public.
