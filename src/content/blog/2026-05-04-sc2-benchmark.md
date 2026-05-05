---
variant: post
title: "Why StarCraft 2 Is the Ideal Benchmark Platform"
tags: cognition, methodology
---

In 2012, a convolutional neural network won the ImageNet Large Scale Visual Recognition Challenge by a margin that ended the debate. AlexNet didn't invent deep learning — Hinton's group had been publishing for years. What changed was that ImageNet gave the result a stage. One number, one leaderboard, one undeniable comparison. The field reorganized around it within months.

AlexNet is remembered as the breakthrough. ImageNet is what made it visible.

### Cognitive architectures are pre-ImageNet

Soar has planning, online learning, means-ends analysis, chunking, interactive task learning. The [Thor-Soar](https://soar.eecs.umich.edu/) agent navigates a kitchen, cooks food, learns new tasks from instruction. It perceives through three levels of vision — from omniscient state to YOLO pixel recognition. It plans with iterative deepening and temporal reasoning. It learns by chunking over look-ahead.

That's real. And nobody outside this community knows.

The problem isn't capability. It's legibility. Thor-Soar results are published against Thor-Soar baselines in Thor-Soar papers read by Thor-Soar researchers. Every group builds custom evals, runs custom tasks, reports custom metrics. No outsider can tell whether Soar 9.6.5 is better than 9.6.4 — or whether Soar is better than ACT-R, or whether either is competitive with neural methods on anything. Not because the results don't exist, but because they don't share a scoreboard.

Neural nets didn't win because they were better. They won because you could watch them get better, year after year, on the same benchmark. Loss curves going down on public leaderboards. Cognitive architectures had papers.

### The right benchmark runs at machine speed

ImageNet worked because anyone could download it and run it. No lab, no robot, no custom simulator, no $50,000 GPU cluster (at the time). A research group with a good idea and a commodity GPU could produce a result the entire field had to take seriously.

The benchmark for cognitive architectures needs the same property. It has to run at machine speed on commodity hardware. Not a robotics platform — we're not all going to download and print robots. Not a household simulator with a custom task ontology. A platform anyone can access, where experiments run fast enough to iterate, and results mean something to people who've never heard of Soar.

### StarCraft 2 checks every box

SC2 is complex enough to demand real cognition. Partial observability (fog of war), real-time decision-making, long-horizon planning, opponent modeling, resource management, multi-scale reasoning from individual unit micro to global strategy. No toy problem exercises all of these simultaneously.

It runs at machine speed. [PySC2](https://github.com/google-deepmind/pysc2) and the [SC2 API](https://github.com/Blizzard/s2client-proto) exist. Thousands of experiments per day on a laptop. Fast enough to measure the effect of every architectural change.

It has public baselines. [AlphaStar](https://www.nature.com/articles/s41586-019-1724-z) reached Grandmaster level. The broader AI community already understands what a result in SC2 means.

And there's precedent. [Soar-SC](https://github.com/bluechill/Soar-SC) connected Soar to StarCraft: Brood War years ago — spatial reasoning via SVS, real-time perception, strategic play. It was never pushed to competitive levels, but it proved the interface works. The path from Soar to StarCraft isn't hypothetical.

### A different scoreboard

The point is not to beat AlphaStar's win rate. AlphaStar trained on millions of games. A cognitive architecture competing on raw win rate against a system with that much data is fighting on the wrong terms.

The scoreboard that matters is different:

**Learning speed.** How many games does it take to adapt to a new opponent's strategy? AlphaStar needed a population of agents training against each other for weeks. A cognitive architecture that adapts mid-game — or across five games instead of five million — is demonstrating something categorically different.

**Adaptation.** When the opponent switches strategies, does the agent notice and respond? Not because it was trained on that transition, but because it reasons about what changed and what to do about it.

**Explainability.** After the game, can the agent say what it learned? Can it articulate why it changed strategies? Neural nets produce win rates. Cognitive architectures can produce rationales. That's a qualitative difference that a public benchmark makes visible.

These are the things cognitive architectures claim to be good at. SC2 is where you prove it in public.

### A benchmark makes the architecture better

There's a less obvious benefit. A shared benchmark doesn't just make results visible to outsiders — it makes them visible to us.

Right now, when Soar gets a new learning mechanism, or a new memory system, or a new version release, the question "did it help?" is hard to answer. Each group runs their own eval. Improvements are demonstrated on tasks designed to show the improvement. That's not dishonest — it's just what happens without a shared baseline.

A stable benchmark turns every architectural change into a measurable experiment. Did episodic memory improve adaptation speed? Run SC2, compare the curve. Did chunking changes affect planning depth? Run SC2, measure. Every release gets a number. Progress becomes cumulative instead of anecdotal.

ImageNet didn't just make CNNs legible to the outside world. It made CNNs legible to the people building them. Every architectural innovation — dropout, batch norm, residual connections — was validated against the same task. The benchmark was the forcing function that turned intuitions into engineering.

### The ask

This isn't a product announcement. I'm not here to demo an agent. I'm here to argue that the single highest-leverage thing the cognitive architecture community could do right now is agree on a benchmark — and that SC2 is the obvious choice.

Not because SC2 is special. Because it's accessible, fast, complex, and already understood by the audience we need to reach. The game is the medium. The message is: cognitive architectures are improving, and here's how you can tell.

ImageNet created AlexNet. The benchmark came first. The breakthrough followed because the stage was already built.

We need to build the stage.
