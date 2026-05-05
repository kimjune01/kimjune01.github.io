---
variant: post
title: "Why StarCraft 2 Is the Ideal Benchmark Platform"
tags: cognition, methodology
---

In 2012, a convolutional neural network won the ImageNet Large Scale Visual Recognition Challenge by a margin that ended the debate. AlexNet didn't invent deep learning — Hinton's group had been publishing for years. What changed was that ImageNet gave the result a stage. One number, one leaderboard, one undeniable comparison. The field reorganized around it within months.

AlexNet is remembered as the breakthrough. ImageNet is what made it visible.

### Three problems

Soar has planning, online learning, means-ends analysis, chunking, interactive task learning. The [Thor-Soar](https://soar.eecs.umich.edu/) agent navigates a kitchen, cooks food, learns new tasks from instruction. It perceives through three levels of vision — from omniscient state to YOLO pixel recognition. It plans with iterative deepening and temporal reasoning. It learns by chunking over look-ahead.

That's real. And nobody outside this community knows.

The first problem is **legibility**. Thor-Soar results are published against Thor-Soar baselines in Thor-Soar papers read by Thor-Soar researchers. The broader AI community can't tell whether Soar is competitive with neural methods on anything — not because the results don't exist, but because they don't share a scoreboard. Neural nets didn't win because they were better. They won because you could watch them get better, year after year, on the same benchmark. Cognitive architectures had papers.

The second problem is **self-measurement**. When Soar gets a new learning mechanism or a new version release, the question "did it help?" is hard to answer. Each group runs their own eval. Improvements are demonstrated on tasks designed to show the improvement. We can't even tell ourselves whether we're making progress.

The third problem is **isolation**. Soar, ACT-R, CLARION, LIDA — each operates on its own benchmarks, in its own papers, against its own baselines. There's no honest way to compare architectures against each other, let alone against neural methods. The field fragments instead of accumulating.

One benchmark fixes all three.

### The right benchmark runs at machine speed

ImageNet worked because anyone could download it and run it. No lab, no robot, no custom simulator. A research group with a good idea and a commodity GPU could produce a result the entire field had to take seriously.

The benchmark for cognitive architectures needs the same property. It has to run at machine speed on commodity hardware. Not a robotics platform — we're not all going to download and print robots. Not a household simulator with a custom task ontology. A platform anyone can access, where experiments run fast enough to iterate, and results mean something to people who've never heard of Soar.

### StarCraft 2

SC2 is complex enough to demand real cognition. Partial observability, real-time decisions, long-horizon planning, opponent modeling, resource management, multi-scale reasoning from unit micro to global strategy. No toy problem exercises all of these simultaneously.

It runs at machine speed. [PySC2](https://github.com/google-deepmind/pysc2) and the [SC2 API](https://github.com/Blizzard/s2client-proto) exist. Thousands of experiments per day on a laptop. And there's precedent: [Soar-SC](https://github.com/bluechill/Soar-SC) connected Soar to StarCraft: Brood War years ago — spatial reasoning via SVS, real-time perception, strategic play. It was never pushed to competitive levels, but it proved the interface works.

But the real argument isn't that SC2 fits a checklist. It's that SC2 exposes exactly the axis where cognitive architectures have a structural advantage.

[AlphaStar](https://www.nature.com/articles/s41586-019-1724-z) reached Grandmaster level. It also trained on millions of games with a population of agents competing against each other for weeks. A cognitive architecture that adapts mid-game — or across five games instead of five million — is demonstrating something categorically different. Not a better score on the same test. A different kind of intelligence, measured on the same task.

**Learning speed.** How many games to adapt to a new opponent's strategy? A system that learns in real-time, from one game, is doing something RL cannot.

**Adaptation.** When the opponent switches strategies, does the agent notice and respond — not because it was trained on that transition, but because it reasons about what changed?

**Explainability.** After the game, can the agent say what it learned? Neural nets produce win rates. Cognitive architectures can produce rationales. That's a qualitative difference that becomes visible when both play the same game.

The point isn't to beat AlphaStar's win rate. It's to demonstrate that learning actually happens — visibly, measurably, in a domain the world already understands.

### One stone, three birds

**External legibility.** The ML community already knows SC2. A Soar agent that adapts mid-game on a public leaderboard produces a result anyone can interpret. No translation needed. No "well, in our eval framework..." caveats. One game, one number, one comparison.

**Internal engineering.** A stable benchmark turns every architectural change into a measurable experiment. Did episodic memory improve adaptation speed? Run SC2, compare the curve. Did chunking changes affect planning depth? Run SC2, measure. Every release gets a number. Progress becomes cumulative instead of anecdotal. ImageNet didn't just make CNNs legible to the outside world — it made CNNs legible to the people building them. Dropout, batch norm, residual connections — each validated against the same task. The benchmark was the forcing function that turned intuitions into engineering.

**Cross-community challenge.** Same scoreboard for every cognitive architecture. Soar, ACT-R, CLARION — bring your agent, run the games, publish the results. No more isolated comparisons. And when the results are public, the question stops being "is cognitive architecture X making progress?" and becomes "which cognitive architecture learns fastest, and what does that tell us about the mind?"

**Built-in generalization.** Three races, six matchups, each strategically distinct. Terran vs. Zerg plays nothing like Protoss vs. Protoss. An agent that handles multiple matchups is demonstrating transfer, not memorization — and the test is built into the game. No second dataset, no held-out distribution. Generalization is proven in-game.

**No ceiling.** A kitchen task benchmark can be beat. A lexical processing benchmark can be beat. You solve it, you move on, and the benchmark is dead. ImageNet itself saturated — top-5 error dropped below human performance and the leaderboard stopped driving progress. SC2 can't saturate because it's adversarial. Every improvement invites a counter-strategy. Every counter-strategy demands further adaptation. The benchmark stays hard precisely because the opponent learns too. There is no upper limit to what a cognitive architecture can achieve here, which means there is no point where the benchmark stops being useful.

### The ladder already exists

[AI Arena](https://aiarena.net/) runs a live SC2 bot ladder — regular tournaments, public Elo, thousands of matches. Most bots are hand-coded expert systems: scripted builds, hardcoded responses, no learning. A cognitive architecture agent can enter tomorrow.

The honest worry: what if we lose to expert systems? Good. That's informative. An agent that loses to scripts in month one and beats them in month six is a better story than a paper claiming victory on a private benchmark. The learning curve *is* the result.

This is a strategic advantage the cognitive architecture community has over industry labs. Top labs will never enter a public bot ladder — the downside is visible embarrassment, and their brand depends on the perception of dominance. They'd rather publish a paper with controlled results than ship a bot that loses on a public Elo. We don't have that problem. We're not protecting a market cap. We can afford to lose in public, learn in public, and improve in public. The ladder is a lab notebook, not a press release.

### The stage

This isn't a product announcement. There's no agent to demo. The argument is simpler: the single highest-leverage thing the cognitive architecture community could do right now is agree on a benchmark.

ImageNet created AlexNet. The benchmark came first. The breakthrough followed because the stage was already built. Every year the leaderboard updated, and every year the gap between "promising research direction" and "the future of AI" narrowed — until one result closed it.

Cognitive architectures are waiting for that result. But you can't have an AlexNet moment without an ImageNet. We need to build the stage, and see who shows up.
