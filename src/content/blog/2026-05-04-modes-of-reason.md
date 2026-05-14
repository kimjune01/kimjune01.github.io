---
variant: post-wide
title: "Modes of Reason"
tags: cognition, methodology, epistemology
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

The Holmes canon calls this deduction. You could reconstruct one: dogs bark at strangers; the dog didn't bark; the intruder wasn't a stranger. But where did the first premise come from? Holmes knows a thousand things about dogs, night, stables, strangers. The skill is selecting which prior to test against the scene. In this case: the dog that should have barked but didn't. Absence is the figure; the quiet night, the ground. The hypothesis falls out of the diff.

That operation is the neglected third mode of reasoning. It's what people mean when they call someone *sharp*: fast figure-ground separation.

### Three modes

All three from Latin *ducere* ("to lead"):

- **Deduction** (*de-ducere*, "to lead from"): given premises, derive consequences. Millennia of formal logic. Solved: theorem provers, type checkers, SAT solvers. Zero uberty: the conclusion is already in the premises.
- **Induction** (*in-ducere*, "to lead toward"): given examples, generalize a pattern. The ML scaling curve. Next-token prediction, pushing toward diminishing returns at the compute frontier. Moderate uberty.
- **Abduction** (*ab-ducere*, "to lead away"): given an observation, propose what matters. The neglected third. Highest uberty, lowest security.

Peirce's term for the expected fertility of a reasoning mode: **uberty**, how much new knowledge the mode can produce.

### Same operation, eight names

Eight entries across six fields circle the same pattern: given an observation, separate signal from noise. Each coined its own word. None cite each other.

<div class="table-wrap">
<table>
<thead><tr>
<th>Field</th>
<th>The operation</th>
<th>Figure (what changed)</th>
<th>Ground (what didn't)</th>
<th>Branching version</th>
<th>Key ref</th>
</tr></thead>
<tr><td>PL / separation logic</td><td>Bi-abduction</td><td>Anti-frame (missing precondition)</td><td>Frame (untouched heap fragment)</td><td>Tri-abduction</td><td><a href="https://dl.acm.org/doi/10.1145/1480881.1480917">Calcagno et al. 2009</a>; <a href="https://arxiv.org/abs/2305.04842">Zilberstein et al. 2024</a></td></tr>
<tr style="background:#f8f8f8"><td>Cognitive arch (SOAR)</td><td>Chunking (impasse resolution)</td><td>Result (WMEs resolving the impasse)</td><td>Superstate conditions (tested WMEs → chunk LHS)</td><td>Operator-tie impasse</td><td><a href="https://apps.dtic.mil/sti/tr/pdf/ADA188742.pdf">Laird et al. 1987</a></td></tr>
<tr><td>Cognitive arch (BPL)</td><td>Type inference</td><td>Type (structural program)</td><td>Token-level variance (marginalized out)</td><td>Implicit</td><td><a href="https://www.science.org/doi/10.1126/science.aab3050">Lake et al. 2015</a></td></tr>
<tr style="background:#f8f8f8"><td>Gestalt (Rubin/Koffka)</td><td>Figure-ground segregation</td><td><em>Figur</em> (bounded, salient)</td><td><em>Grund</em> (formless, extending)</td><td>Multistability</td><td><a href="https://philpapers.org/rec/RUBSF">Rubin 1915</a>; <a href="https://en.wikipedia.org/wiki/Principles_of_Gestalt_Psychology">Koffka 1935</a></td></tr>
<tr><td>Developmental (Piaget)</td><td>Equilibration</td><td>Perturbation (novel element)</td><td>Schema (assimilates without changing)</td><td>Reflective abstraction</td><td><a href="https://en.wikipedia.org/wiki/Equilibration">Piaget 1975/1985</a></td></tr>
<tr style="background:#f8f8f8"><td>Causal inference (Pearl)</td><td>Intervention / identification</td><td>Treatment variable (<em>do(X=x)</em>)</td><td>Background variables <em>U</em> (held fixed)</td><td>Counterfactual contrast <em>Y₁ - Y₀</em></td><td><a href="https://www.cambridge.org/core/books/causality/B0046844FAE10CBF274D4ACBDAEB5F5B">Pearl 2009</a></td></tr>
<tr><td>Philosophy (Peirce)</td><td>Abduction (retroduction)</td><td>Surprising fact <em>C</em></td><td>Settled expectations</td><td>Economy of research</td><td><a href="https://archive.org/details/pragmatismasprin0000peir">Peirce 1903</a></td></tr>
<tr style="background:#f8f8f8"><td>ML/RL</td><td>Invariant feature separation</td><td>Invariant features (stable across envs)</td><td>Spurious features (env-specific)</td><td>Counterfactual policy evaluation</td><td><a href="https://arxiv.org/abs/1907.02893">Arjovsky et al. 2019</a></td></tr>
</table>
</div>

### Prior art

- **Aristotle (~350 BC)**: formalized deduction (syllogistic logic). Discussed induction (*epagoge*) but didn't elevate it to a method.
- **[Francis Bacon](https://en.wikipedia.org/wiki/Novum_Organum) (1620)**: *Novum Organum*. Foregrounded induction as systematic method. Two modes now.
- **[Peirce](/reading/scientific-method/peirce-1878/) (1903)**: the trichotomy. Three and only three, argued on mathematical grounds (monadic, dyadic, triadic relations are irreducible).
- **[Popper](https://en.wikipedia.org/wiki/The_Logic_of_Scientific_Discovery) (1934)**: rejected induction entirely. All science is deduction from conjectures, but where conjectures come from, he doesn't say. (Abduction. Popper just didn't use the word.)
- **[Zilberstein et al.](https://arxiv.org/abs/2305.04842) (2024)**: tri-abduction. Abduction gains a branching degree of freedom.


### Everything decomposes

Three primitives; everything else decomposes:

- **Analogy** = abduction (observe surprising similarity across domains) + induction (generalize the structural correspondence). Peirce saw it this way; [Brewer's](https://cyber.harvard.edu/bridge/Library/brewer.htm) legal account confirms it.
- **Diagnosis** = abduction (propose what's wrong) + deduction (trace consequences)
- **Scientific method** = abduction (hypothesize) + deduction (predict) + induction (test)
- **Debugging** = abduction (propose cause) + deduction (if this, then that) + abduction again (it wasn't; next cause)
- **Legal precedent** = abduction (match to prior case) + induction (generalize principle) + deduction (apply rule)

Holmes, House, Semmelweis, Darwin. All running the same compositions. Doyle misnamed the mode; his characters perform it anyway.

### The triangle

The three modes map onto the three morphisms of the [memory monoid](/functor-wizardry):

- **Abduction**: Observation → Theory. Episodes become knowledge. Observe an episode, separate figure from ground, and propose what's true.
- **Deduction**: Theory → Experiment. Knowledge becomes procedure. Given what's true, derive how to act.
- **Induction**: Experiment → Observation. Procedure produces episodes. Run the procedure, accumulate evidence, and feed new observations back in.

<div style="max-width:min(460px, 100%); margin:1.5em auto;">
<img src="/assets/modes-of-reason-triangle.svg" alt="Triangle: Observation → Theory (abduction), Theory → Experiment (deduction), Experiment → Observation (induction). Three modes, three morphisms, one monoid." style="width:100%; display:block;">
</div>

The monoid [broke in Soar](/diagnosis-soar) because the abductive morphism (Observation → Theory) was missing. [`cons`](/cons) closed it manually; the [Natural Framework](/the-natural-framework) gave the interface. Whether the third edge can be automated remains open.

That's a [different post](/abduction).

---

*For [Charles Sanders Peirce](https://en.wikipedia.org/wiki/Charles_Sanders_Peirce) (1839–1914), who named the third mode and spent thirty years writing in solitude, rejected from polite society, unrecognized for it.*
