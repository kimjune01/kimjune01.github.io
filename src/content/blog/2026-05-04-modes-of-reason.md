---
variant: post-wide
title: "Modes of Reason"
tags: cognition, methodology
---

*Part of the [cognition](/cognition) series.*

> "Is there any other point to which you would wish to draw my attention?"
>
> "To the curious incident of the dog in the night-time."
>
> "The dog did nothing in the night-time."
>
> "That was the curious incident."
>
> — Arthur Conan Doyle, [*The Adventure of Silver Blaze*](https://en.wikipedia.org/wiki/The_Adventure_of_Silver_Blaze) (1892)

The Holmes canon calls this deduction. It isn't. No syllogism, no chain of premises. He noticed what *didn't* happen: the dog didn't bark. He separated that silence from the ordinary night and landed on an explanation: the intruder was someone the dog knew. Absence is the figure; the quiet night, the ground. The hypothesis falls out of the diff.

That operation has a name. It's the neglected third mode of reasoning.

### Three modes

All three from Latin *ducere* ("to lead"):

- **Deduction** (*de-ducere*, "to lead from"): given premises, derive consequences. Millennia of formal logic. Solved: theorem provers, type checkers, SAT solvers. Zero uberty: the conclusion is already in the premises.
- **Induction** (*in-ducere*, "to lead toward"): given examples, generalize a pattern. The ML scaling curve. Next-token prediction, pushing toward diminishing returns at the compute frontier. Moderate uberty.
- **Abduction** (*ab-ducere*, "to lead away"): given an observation, propose what matters. The neglected third. Highest uberty, lowest security.

Peirce's term for the expected fertility of a reasoning mode: **uberty**, how much new knowledge the mode can produce.

### The crosswalk

Eight entries across six fields circle the same pattern: given an observation, separate signal from noise. Each coined its own word. None recognize each other's.

<div class="table-wrap">
<table style="max-width:70%; margin:1em auto; font-size:14px;">
<colgroup><col style="width:10em"><col style="width:10em"><col style="width:10em"><col style="width:10em"><col style="width:9em"><col style="width:10em"></colgroup>
<thead><tr>
<th style="background:#f0f0f0">Field</th>
<th style="background:#f0f0f0">The operation</th>
<th style="background:#f0f0f0">Figure (what changed)</th>
<th style="background:#f0f0f0">Ground (what didn't)</th>
<th style="background:#f0f0f0">Branching version</th>
<th style="background:#f0f0f0">Key ref</th>
</tr></thead>
<tr><td><strong>PL / separation logic</strong></td><td>Bi-abduction</td><td>Anti-frame (missing precondition)</td><td>Frame (untouched heap fragment)</td><td>Tri-abduction</td><td>Calcagno et al. POPL 2009; Zilberstein et al. OOPSLA 2024</td></tr>
<tr><td><strong>Cognitive arch (SOAR)</strong></td><td>Chunking (impasse resolution)</td><td>Result (WMEs resolving the impasse)</td><td style="white-space:nowrap">Superstate conditions (tested WMEs → chunk LHS)</td><td>Operator-tie impasse</td><td>Laird et al. 1987</td></tr>
<tr><td><strong>Cognitive arch (BPL)</strong></td><td>Type inference</td><td>Type (structural program)</td><td>Token-level variance (marginalized out)</td><td>Implicit</td><td>Lake et al. Science 2015</td></tr>
<tr><td><strong>Gestalt (Rubin/Koffka)</strong></td><td>Figure-ground segregation</td><td><em>Figur</em> (bounded, salient)</td><td><em>Grund</em> (formless, extending)</td><td>Multistability</td><td>Rubin 1915; Koffka 1935</td></tr>
<tr><td><strong>Developmental (Piaget)</strong></td><td>Equilibration</td><td>Perturbation (novel element)</td><td>Schema (assimilates without changing)</td><td>Reflective abstraction</td><td>Piaget 1975/1985</td></tr>
<tr><td><strong>Causal inference (Pearl)</strong></td><td>Intervention / identification</td><td>Treatment variable (<em>do(X=x)</em>)</td><td>Background variables <em>U</em> (held fixed)</td><td style="white-space:nowrap">Counterfactual contrast <em>Y₁ - Y₀</em></td><td>Pearl 2009</td></tr>
<tr><td><strong>Philosophy (Peirce)</strong></td><td>Abduction (retroduction)</td><td>Surprising fact <em>C</em></td><td>Settled expectations</td><td>Economy of research</td><td>Peirce 1903; CP 5.189</td></tr>
<tr><td><strong>ML/RL</strong></td><td>Invariant feature separation</td><td>Invariant features (stable across envs)</td><td>Spurious features (env-specific)</td><td>Counterfactual policy evaluation</td><td>Arjovsky et al. 2019 (IRM)</td></tr>
</table>
</div>

### Prior art

- **Aristotle (~350 BC)**: formalized deduction (syllogistic logic). Discussed induction (*epagoge*) but didn't elevate it to a method.
- **Francis Bacon (1620)**: *Novum Organum*. Foregrounded induction as systematic method. Two modes now.
- **Peirce (1903)**: the trichotomy. Three and only three, argued on mathematical grounds (monadic, dyadic, triadic relations are irreducible).
- **Popper (1934)**: rejected induction entirely. All science is deduction from conjectures, but where conjectures come from, he doesn't say. (Abduction. Popper just didn't use the word.)
- **Zilberstein et al. (2024)**: tri-abduction. Abduction gains a branching degree of freedom.

Aristotle (1 mode) → Bacon (2) → Peirce (3) → Zilberstein (2024). Two millennia to reach three, and the third is still sharpening.

### Compositions

Three primitives; everything else decomposes:

- **Analogy** = abduction (observe surprising similarity across domains) + induction (generalize the structural correspondence). Peirce saw it this way; Brewer's legal account confirms it.
- **Diagnosis** = abduction (propose what's wrong) + deduction (trace consequences)
- **Scientific method** = abduction (hypothesize) + deduction (predict) + induction (test)
- **Debugging** = abduction (propose cause) + deduction (if this, then that) + abduction again (it wasn't; next cause)
- **Legal precedent** = abduction (match to prior case) + induction (generalize principle) + deduction (apply rule)

Holmes, House, Semmelweis, Darwin. All running the same compositions. Doyle misnamed the mode; his characters perform it anyway.

### The triangle

The three modes map onto the three morphisms of the [memory monoid](/functor-wizardry):

- **Abduction**: epmem → smem. Episodes become knowledge. Observe an episode, separate figure from ground, and propose what's true.
- **Deduction**: smem → pmem. Knowledge becomes procedure. Given what's true, derive how to act.
- **Induction**: pmem → epmem. Procedure produces episodes. Run the procedure, accumulate evidence, and feed new observations back in.

<div style="max-width:min(460px, 100%); margin:1.5em auto;">
<img src="/assets/modes-of-reason-triangle.svg" alt="Triangle: epmem → smem (abduction), smem → pmem (deduction), pmem → epmem (induction). Three modes, three morphisms, one monoid." style="width:100%; display:block;">
</div>

The monoid [broke in Soar](/diagnosis-soar) because the abductive morphism (epmem → smem) was missing. [`cons`](/cons) closed it manually; the [Natural Framework](/the-natural-framework) gave the interface. Whether the third edge can be automated remains open.

That's a [different post](/abduction).

---

### Refs

**PL / separation logic**: Calcagno, Distefano, O'Hearn, Yang, "Compositional Shape Analysis by Means of Bi-Abduction," POPL 2009. O'Hearn, "Incorrectness Logic," POPL 2020. Reynolds, "Separation Logic," LICS 2002. Zilberstein, Saliling, Silva, "Outcome Separation Logic," OOPSLA 2024. Ernst, Cockrell, Griswold, Notkin, "Dynamically Discovering Likely Program Invariants," ICSE 1999.

**Cognitive architectures**: Laird, Newell, Rosenbloom, "SOAR: An Architecture for General Intelligence," AI 33(1), 1987. Anderson, "How Can the Human Mind Occur in the Physical Universe?" Oxford, 2007. Lake, Salakhutdinov, Tenenbaum, "Human-level Concept Learning through Probabilistic Program Induction," Science 350(6266), 2015.

**Perception / cognitive science**: Rubin, "Synsoplevede Figurer," 1915. Koffka, "Principles of Gestalt Psychology," 1935. Gibson, "The Ecological Approach to Visual Perception," 1979. Piaget, "The Equilibration of Cognitive Structures," 1975/1985.

**Causal inference**: Pearl, "Causality," Cambridge, 2000. 2nd ed. 2009.

**ML**: Arjovsky, Bottou, Gulczynski, Lopez-Paz, "Invariant Risk Minimization," arXiv:1907.02893, 2019.

**Philosophy of abduction**: Peirce, "Harvard Lectures on Pragmatism," 1903 (Collected Papers, vol. 5). Lipton, "Inference to the Best Explanation," Routledge, 1991. 2nd ed. 2004. Chauviré, "Peirce, Popper, Abduction, and the Idea of a Logic of Discovery," Semiotica, 2005.
