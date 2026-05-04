---
variant: post-medium
title: "Abduction"
tags: cognition, methodology
---

*Part of the [cognition](/cognition) series. Sequel to [Modes of Reason](/modes-of-reason).*

The [previous post](/modes-of-reason) named the third mode and mapped it across six fields. This post asks: can it be encoded?

### The existence argument

Suppose no computation for generating follow-up hypotheses exists. Hypotheses would be random, their order arbitrary. But the knowledge graph of science does expand, and our attention drives connections from one experiment to another. So the class of such computations must exist.

This is a computability claim, not just an existence claim. Cognition is computation — the bet six decades of cognitive architecture research is built on. Under CTM, the procedures that generate non-random hypotheses are computable.

Evolution found inhabitants before brains existed. Chemotaxis is proto-abduction: observe a gradient (figure), ignore everything else (ground), move toward the source (hypothesis). No nervous system required.

### The minimal invariant

Abduction from two samples: one before, one after. Diff. What flipped is figure; what held is ground. If that operation is encodable, the loop closes.

Everything after the minimal diff is optimization: more samples (Ernst/Daikon), autonomous frame inference (bi-abduction), flipped polarity (incorrectness), branching (tri-abduction), n-ary. Each step in the [lineage table](/modes-of-reason#prior-art) is more efficient, not more fundamental. The primitive is already running at two samples.

### The structure

The intuition underneath is **diff**. Snapshot before, snapshot after, XOR. The prefixes are degrees of freedom:

- Unary diff (one before, one after) → one frame
- Bi-abduction → infer frame autonomously from observation
- Incorrectness → flip polarity (attend to failure, not success)
- Tri-abduction → diff across branches (cause vs counterfactual)

Each step adds an operand. One snapshot pair → one frame. Two pairs (actual and counterfactual) → one causal edge. N pairs across N branches → a typed subgraph. The operation is always XOR; the arity grows. More diffs, more freedom, sharper attention.

### Who's already doing this

**Voyager** (Wang et al. 2023): GPT-4 observes failure, proposes fix, self-verifies, commits to skill library. 180 verified skills in Minecraft — a demo, not production, but it proves the loop closes autonomously. LLM-everywhere as the abduction engine.

**Infer** (Facebook, from Calcagno et al. 2009): bi-abduction running in production on millions of lines of code. Formal observation + formal goal → formal hypothesis. Deployed constructive witness.

**IRM** (Arjovsky et al. 2019): invariant feature separation across training environments. The ML field's version — use environment variation as the lever to force figure/ground separation.

### The monad move

Instead of arguing philosophically about whether SOAR's chunking and bi-abduction are "the same operation," encode abduction as a typed primitive, run it, let the results settle the debate. The engineering artifact is the crosswalk.

Don't reason about the effect at the meta-level — encode it into the type system and compute with it. `abduct_candidates(observation, target) → list[Candidate]`. The test isn't evidence for the argument. The test *is* the argument.

What happens when you point it at a human playthrough, or ten thousand RL rollouts?

---

### Refs

**PL / separation logic**: Calcagno, Distefano, O'Hearn, Yang, "Compositional Shape Analysis by Means of Bi-Abduction," POPL 2009. O'Hearn, "Incorrectness Logic," POPL 2020. Zilberstein, Saliling, Silva, "Outcome Separation Logic," OOPSLA 2024. Ernst, Cockrell, Griswold, Notkin, "Dynamically Discovering Likely Program Invariants," ICSE 1999.

**Engineering witnesses**: Wang, Xie, Jiang et al., "Voyager: An Open-Ended Embodied Agent with Large Language Models," arXiv:2305.16291, 2023. Arjovsky, Bottou, Gulczynski, Lopez-Paz, "Invariant Risk Minimization," arXiv:1907.02893, 2019.

**Philosophy**: Peirce, "Harvard Lectures on Pragmatism," 1903 (Collected Papers, vol. 5). Chauviré, "Peirce, Popper, Abduction, and the Idea of a Logic of Discovery," Semiotica, 2005. Paavola, "Abduction as a Logic of Discovery," University of Helsinki, 2006.
