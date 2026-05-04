---
variant: post-medium
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

Holmes calls this deduction. It isn't. There's no syllogism, no chain of premises. He observed what *didn't* happen — the dog didn't bark — separated that absence from everything that did happen normally, and proposed the explanation: the intruder was known to the dog. The absence is the figure. The normal night is the ground. The hypothesis falls out of the diff.

That operation has a name. It's not deduction. It's the neglected third mode of reasoning.

### Three modes

All three from Latin *ducere* ("to lead"):

- **Deduction** (*de-ducere*, "to lead from"): given premises, derive consequences. Millennia of formal logic. Solved — theorem provers, type checkers, SAT solvers. Zero uberty: the conclusion is already in the premises.
- **Induction** (*in-ducere*, "to lead toward"): given examples, generalize a pattern. The entire ML scaling curve. Next-token prediction pushing into diminishing returns at the compute frontier. Moderate uberty.
- **Abduction** (*ab-ducere*, "to lead away"): given an observation, propose what matters. The neglected third. Highest uberty, lowest security.

Peirce's term for the expected fertility of a reasoning mode: **uberty** — how much new knowledge the mode can produce.

### The crosswalk

Six fields independently formalized abduction: given an observation, simultaneously separate what's relevant from what's irrelevant. None of them recognize each other's word.

| Field | The operation | Figure (what changed) | Ground (what didn't) | Branching version | Key ref |
|---|---|---|---|---|---|
| **PL / separation logic** | Bi-abduction | Anti-frame (missing precondition) | Frame (untouched heap fragment) | Tri-abduction | Calcagno et al. POPL 2009; Zilberstein et al. OOPSLA 2024 |
| **Cognitive arch (SOAR)** | Chunking (impasse resolution) | Result (WMEs resolving the impasse) | Superstate conditions (tested WMEs → chunk LHS) | Operator-tie impasse | Laird et al. 1987 |
| **Cognitive arch (BPL)** | Type inference | Type (structural program) | Token-level variance (marginalized out) | Implicit | Lake et al. Science 2015 |
| **Gestalt (Rubin/Koffka)** | Figure-ground segregation | *Figur* (bounded, salient) | *Grund* (formless, extending) | Multistability | Rubin 1915; Koffka 1935 |
| **Developmental (Piaget)** | Equilibration | Perturbation (novel element) | Schema (assimilates without changing) | Reflective abstraction | Piaget 1975/1985 |
| **Causal inference (Pearl)** | Intervention / identification | Treatment variable (*do(X=x)*) | Background variables *U* (held fixed) | Counterfactual contrast *Y₁ - Y₀* | Pearl 2009 |
| **Philosophy (Peirce)** | Abduction (retroduction) | Surprising fact *C* | Settled expectations | Economy of research | Peirce 1903; CP 5.189 |
| **ML/RL** | Invariant feature separation | Invariant features (stable across envs) | Spurious features (env-specific) | Counterfactual policy evaluation | Arjovsky et al. 2019 (IRM) |

### Prior art

- **Aristotle (~350 BC)**: deduction only. Syllogistic logic.
- **Francis Bacon (1620)**: *Novum Organum*. Named induction as a formal method. Two modes now.
- **Peirce (1903)**: the trichotomy. Deduction, induction, abduction. Three and only three, argued on mathematical grounds (monadic, dyadic, triadic relations are irreducible).
- **Popper (1934)**: rejected induction entirely. All science is deduction from conjectures. Conjectures come from... he doesn't say. (They come from abduction, but Popper didn't use the word.)
- **Zilberstein et al. (2024)**: tri-abduction. Abduction gains a branching degree of freedom.

Aristotle (1 mode) → Bacon (2) → Peirce (3) → Zilberstein (2024). Two thousand years to get to three. Still sharpening the third.

### Compositions

Three primitives. Everything else decomposes:

- **Analogy** = abduction (observe surprising similarity across domains) + induction (generalize the structural correspondence). Peirce saw it this way; Brewer's legal account agrees.
- **Diagnosis** = abduction (propose what's wrong) + deduction (trace consequences)
- **Scientific method** = abduction (hypothesize) + deduction (predict) + induction (test)
- **Debugging** = abduction (propose cause) + deduction (if this, then that) + abduction again (it wasn't — next cause)
- **Legal precedent** = abduction (match to prior case) + induction (generalize principle) + deduction (apply rule)

Holmes, House, Semmelweis, Darwin — all running the same compositions. Doyle misnamed the mode; the characters perform it correctly.

### The triangle

The three modes map onto the three morphisms of the [memory monoid](/functor-wizardry):

- **Abduction**: epmem → smem. Episodes become knowledge. Observe what happened, separate figure from ground, propose what's true.
- **Deduction**: smem → pmem. Knowledge becomes procedure. Given what's true, derive how to act.
- **Induction**: pmem → epmem. Procedure produces episodes. Run the procedure, accumulate evidence, produce new observations.

<div style="max-width:min(460px, 100%); margin:1.5em auto;">
<img src="/assets/modes-of-reason-triangle.svg" alt="Triangle: epmem → smem (abduction), smem → pmem (deduction), pmem → epmem (induction). Three modes, three morphisms, one monoid." style="width:100%; display:block;">
</div>

The monoid [broke in Soar](/diagnosis-soar) because the abductive morphism (epmem → smem) was missing. [`cons`](/cons) closed it manually. The [Natural Framework](/the-natural-framework) gave the interface. The question is whether the third edge can be automated.

That's a [different post](/abduction).

---

### Refs

**PL / separation logic**: Calcagno, Distefano, O'Hearn, Yang, "Compositional Shape Analysis by Means of Bi-Abduction," POPL 2009. O'Hearn, "Incorrectness Logic," POPL 2020. Reynolds, "Separation Logic," LICS 2002. Zilberstein, Saliling, Silva, "Outcome Separation Logic," OOPSLA 2024. Ernst, Cockrell, Griswold, Notkin, "Dynamically Discovering Likely Program Invariants," ICSE 1999.

**Cognitive architectures**: Laird, Newell, Rosenbloom, "SOAR: An Architecture for General Intelligence," AI 33(1), 1987. Anderson, "How Can the Human Mind Occur in the Physical Universe?" Oxford, 2007. Lake, Salakhutdinov, Tenenbaum, "Human-level Concept Learning through Probabilistic Program Induction," Science 350(6266), 2015.

**Perception / cognitive science**: Rubin, "Synsoplevede Figurer," 1915. Koffka, "Principles of Gestalt Psychology," 1935. Gibson, "The Ecological Approach to Visual Perception," 1979. Piaget, "The Equilibration of Cognitive Structures," 1975/1985.

**Causal inference**: Pearl, "Causality," Cambridge, 2000. 2nd ed. 2009.

**ML**: Arjovsky, Bottou, Gulczynski, Lopez-Paz, "Invariant Risk Minimization," arXiv:1907.02893, 2019.

**Philosophy of abduction**: Peirce, "Harvard Lectures on Pragmatism," 1903 (Collected Papers, vol. 5). Lipton, "Inference to the Best Explanation," Routledge, 1991. 2nd ed. 2004. Chauviré, "Peirce, Popper, Abduction, and the Idea of a Logic of Discovery," Semiotica, 2005.
