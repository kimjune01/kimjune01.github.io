---
name: investigate
description: Run a hypothesis graph on an engineered system. Perturb, classify the evidence trajectory, follow the edge. Fan-out for breadth, codex for adversarial filtering, e-value classification for shape. Produces a hypothesis graph document with provenance.
argument-hint: <system-or-question>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, WebFetch, WebSearch
---

# Investigate: Hypothesis Graph to PR

Perturb an engineered system, classify the evidence trajectory, follow the edge the kill condition generates. Repeats until the frontier closes or the human redirects. Optionally continues through prework, benchmark, adversarial review, and PR — with a feedback loop that re-enters the hypothesis graph when downstream phases kill a candidate fix.

## Dependencies

Phases 1-6 are self-contained — they use only the tools in `allowed-tools`. Phases 7-8 invoke other skills:

| Skill | Used in | Purpose | Fallback if missing |
|-------|---------|---------|-------------------|
| `/codex` | Phase 2 (filter), Phase 7 (hunt) | Structural review via codex CLI | `cat <<'EOF' \| codex exec -` directly |
| `/gemini` | Phase 7 (hunt) | Logic-tracing review via Gemini API | Skip — codex alone is sufficient for convergence, just slower |
| `/bug-hunt` | Phase 7 | Multi-pass adversarial loop | Run codex manually in rounds, track findings in a file |

If the target machine doesn't have `codex` CLI installed, Phases 1-6 still work. Phase 7 degrades to manual review. Phase 8 (ship) only needs `git` and `gh`.

The skill reads no machine-specific paths. All file references are relative to the target system passed as the argument.

## Theory

- **Hypothesis graph**: [The Hypothesis Graph](https://june.kim/the-hypothesis-graph) — perturb, classify, follow the edge. Kill conditions generate the next hypothesis.
- **E-value classification**: [Evidence has a trajectory](https://june.kim/evidence-has-a-trajectory) — every experiment produces a trajectory classifiable as convergent, divergent, oscillatory, or chaotic. The shape names the next question.
- **Modes of reason**: [Modes of Reason](https://june.kim/modes-of-reason) — abduction proposes, deduction traces consequences, induction tests. Label each node's reasoning mode and track confidence accordingly.

## Input

A system to investigate and a question about it. Can be:
- A codebase path + performance question ("why is X slow")
- A repo URL + behavioral question ("why does X crash under Y")
- A system description + structural question ("what's the bottleneck")

## Output

A hypothesis graph document at `HYPOTHESIS_GRAPH.md` (or user-specified path) with:
- Each node: hypothesis, null, perturbation, trajectory shape, kill condition, edge
- Graph state table (killed / refined / confirmed / partial)
- Frontier edges (open experiments with predicted classification)
- Reasoning mode table (which mode produced which claim, confidence level)
- Pruning log (what died and why — failures are information)

## Process

### Phase 1: Observation (H₀)

Establish the baseline. Run the most direct perturbation available.

1. Identify the system's perturbation surface — what can you poke?
2. Run the baseline experiment. Measure.
3. Classify the trajectory. If divergent from expectation, H₀ is killed. If convergent, the system behaves as expected — stop or redirect.
4. Write H₀ to the graph document.
5. Present to the human: "The system diverges from expectation on [measurement]. Where do you want to look first?"

### Phase 2: Fan-out (H₁...Hₖ)

Generate competing hypotheses for the observation. This is abduction — highest uberty, lowest security.

1. **Fan out k hypotheses** (default k=3). Launch subagents in parallel, each exploring a different causal explanation. Each subagent gets:
   - The H₀ observation
   - A distinct angle to investigate
   - A concrete perturbation to run (not "explore this direction" — "measure this quantity under this condition")
   - **Its own copy of the system under test.** Before launching, copy the target directory to `/tmp/interrogate-H{n}/` for each branch. This prevents cross-contamination — one branch's modifications (patches, env vars, generated files) must not affect another branch's measurements.

2. **Each subagent runs its perturbation and classifies the trajectory:**

   | Shape | Meaning | Edge |
   |-------|---------|------|
   | **Convergent** | Hypothesis confirmed, evidence settles | Test a different node |
   | **Divergent** | Strong evidence for or against | Follow the direction |
   | **Oscillatory** | Hypothesis too coarse, two modes visible | Split into sub-hypotheses |
   | **Chaotic** | System too complex for this perturbation | Decompose differently |

3. **Converge with codex.** For each subagent result:
   ```
   cat <<'EOF' | codex exec -
   Review this hypothesis and its evidence. What's overclaimed? What's
   unsupported? What alternative explanation fits the same data?

   [hypothesis + perturbation + result]
   EOF
   ```
   Fix issues codex finds. Two rounds max per hypothesis.

4. **Prune.** Kill hypotheses that:
   - Codex disproved (deduction killed the abduction)
   - The experiment refuted (induction killed the abduction)
   - Produced oscillatory classification (too coarse — refine, don't keep)

5. **Write nodes to graph document.** Each node gets its full record: hypothesis, null, perturbation, trajectory, shape classification, kill condition, edge.

6. **Present to human.** Show the graph state table. The human Attends — they decide which surviving edges to follow, which killed hypotheses to note, whether to fan out again.

### Phase 2.5: Provenance check (critical hypotheses)

Before acting on a surviving hypothesis that proposes a code change, check its history and ecosystem context. This step catches gotchas that perturbation alone can't surface.

1. **Git blame.** When did the current code enter the repo? Who wrote it, and what was the commit message? A deliberate design choice has different weight than a migration default that was never reconsidered.

2. **Issue/PR search.** Search the upstream project's issue tracker for the proposed change (e.g., `site:github.com/project "client:only" build performance`). Look for:
   - Known bugs or regressions with the proposed approach
   - Gotchas others hit (CSS extraction, styling, hydration)
   - Whether the issue was fixed, open, or has workarounds

3. **Adjacent clue synthesis.** Combine git history + upstream issues into a risk assessment. A proposed fix that has open bugs against it in the upstream project needs a visual/functional check, not just a timing check.

4. **Write findings to graph document.** Add a "Provenance" section to the surviving hypothesis with: origin commit, upstream issues found, risk assessment.

### Phase 3: Extend (H₂...Hₙ)

Follow the surviving edges. Each edge is a new hypothesis generated by a kill condition.

1. For each surviving edge, design a perturbation that would classify it. Prefer perturbations that are:
   - **Decisive**: the result distinguishes this hypothesis from alternatives
   - **Cheap**: fast to run, doesn't require external access
   - **Reversible**: doesn't modify the system under investigation

2. Run the perturbation. Classify. Codex-filter. Prune. Write.

3. Repeat until:
   - The frontier closes (all edges point to already-classified nodes)
   - The human redirects
   - Depth 10 reached (hard stop — present the graph and let the human decide)

### Phase 4: Report

Write the final graph document with:

1. **Graph state table** — all nodes, status, trajectory shape
2. **Causal chain** — the path from H₀ through confirmed/killed hypotheses to the current diagnosis
3. **Frontier edges** — open experiments with predicted classification and confidence
4. **Reasoning mode table** — which mode produced each claim:
   - Deduction (read the code, traced consequences): 95-99% confidence
   - Induction (ran the experiment, measured): 90-95% confidence
   - Abduction (proposed from observation): 60-85% confidence
5. **Pruning log** — what died, which experiment or codex round killed it

Present to human. If the diagnosis implies a code change, ask: "Prework and ship, or stop at the diagnosis?" If stop, the investigation is complete. If ship, continue to Phase 5.

### Phase 5: Prework

When a surviving hypothesis implies a code change, build the [prework](/prework) artifacts before touching production. The experiment repo IS the prework — it was built during the investigation. Formalize it.

1. **Experiment repo.** Consolidate the investigation artifacts into a standalone repo:
   - `reference.py` — ground truth (numpy, BLAS, or known-good implementation)
   - `propose.py` — the candidate fix as a pure function, no target codebase dependency
   - `validate.py` — propose matches reference for all test cases
   - `extract.py` — dumps the target system's actual behavior for comparison
   - `compat.py` — proves the fix doesn't change correctness (numerical equivalence, output identity)
   - `bench.py` — measures the fix against the baseline
   - `shapes.py` — test matrix covering the target shapes AND regression shapes

2. **Transformation design doc** (`TRANSFORM.md`). Maps the candidate fix onto the target codebase:
   - Which files to touch
   - Which option to take if there are multiple intervention points
   - What NOT to change
   - Verification plan

3. **Integration manifest** (`MANIFEST.md`). One line per artifact: repo, branch, remote, what it hosts.

4. **Derisk.** Run `extract.py` to confirm the bug exists in the target. If it doesn't, the diagnosis was wrong — go back to Phase 2. This is the most important step. Without it, the prework is speculative.

### Phase 6: Benchmark

Measure the candidate fix on the target system.

1. Implement the fix in the target codebase (minimal change).
2. Run `bench.py` against both the baseline and the fix.
3. Classify the benchmark trajectory:
   - **Divergent improvement** on all tested cases → proceed to Phase 7.
   - **Oscillatory** (helps some cases, hurts others) → the fix is too coarse. Re-enter Phase 2 with the oscillatory result as H₀. Split the hypothesis. The bug hunt in Phase 7 may also catch this, but catching it here is cheaper.
   - **No improvement** → the diagnosis was wrong or the fix doesn't address it. Go back to Phase 2.

### Phase 7: Bug hunt

Run `/bug-hunt` on the candidate fix. Codex first (structural), Gemini second (logic tracing), iterated to convergence.

**Critical rule: if the bug hunt kills the fix, re-enter the hypothesis graph.** The kill condition from the bug hunt is a new observation. Classify its trajectory shape and follow the edge:
- Bug hunt finds a regression on a specific layout/shape → **oscillatory**. Split the hypothesis.
- Bug hunt finds a correctness error → **divergent against**. Kill the fix, mine the failure for a new edge.
- Bug hunt finds nothing → **convergent**. Proceed to Phase 8.

This is the feedback loop that /forge doesn't have. The bug hunt doesn't just verify — it generates new hypotheses that feed back into the investigation. The tinygrad matvec investigation went through this loop twice: the first fix (remove GROUP) was killed by the bug hunt for regressing nn.Linear's transposed layout. The kill condition (oscillatory — helps one layout, hurts another) re-entered the graph, split into two sub-hypotheses, and the surviving hypothesis (wider UPCAST alone) shipped.

### Phase 8: Ship (human gate)

**This is the only phase that requires human approval.** Everything before it is local and reversible. A PR is an external side effect — it's visible to other people, triggers CI on their hardware, and occupies reviewer attention. Present the full package and wait for a go/no-go.

Present to the human:
- The diff (should be small — if it's not, the prework missed something)
- The benchmark table
- The bug hunt convergence status
- The PR title and body draft
- Any existing PRs found by the idempotency guard

If approved:

1. Commit the minimal fix.
2. Push the experiment repo to a public remote (it's the provenance for the PR).
3. Create the PR with:
   - One-sentence problem
   - One-sentence solution
   - Link to experiment repo
   - Benchmark table
   - "No regressions" with the verification scope
4. Git blame the changed line. If it was a deliberate design choice, ping the author. If it was an inherited default, note that in the PR.

## Monoidal contract

Each phase produces a self-contained artifact that is a valid input to any downstream phase — and a valid stopping point on its own.

| Phase | Output artifact | Valid alone? |
|-------|----------------|--------------|
| 1-3 Interrogate | Hypothesis graph (`.md`) | Yes — a diagnosis with provenance |
| 4 Report | Graph + frontier edges | Yes — diagnosis + what to try next |
| 5 Prework | Experiment repo | Yes — a validated prototype |
| 6 Benchmark | Measurement table | Yes — evidence for or against |
| 7 Bug hunt | Convergence report | Yes — adversarial verification |
| 8 Ship | PR with provenance | Yes — contribution with full trail |

**Composition rule:** the output of phase N is the input to phase N+1, but any phase can also accept its input from an external source. You can run Phase 7 (bug hunt) on a fix you wrote by hand — it doesn't require Phases 1-6. You can start at Phase 5 (prework) if you already have a diagnosis from a conversation. The phases compose; they don't require sequential execution.

**Identity:** running a phase on its own output is a no-op. Re-interrogating a converged graph produces the same graph. Re-benchmarking an already-measured fix produces the same numbers. This is how you know a phase is done.

**Associativity:** (interrogate → prework) → benchmark = interrogate → (prework → benchmark). The grouping doesn't matter because each phase's output fully encodes its result. No hidden state leaks between phases.

**Crash recovery:** the hypothesis graph document is the checkpoint. Every phase writes its state to the file before presenting to the human. On restart, read the graph document and resume:
- Nodes with status (killed/confirmed/partial) → already classified, skip.
- Frontier edges with "pending" → resume from here.
- If an experiment repo exists → Phase 5 is done, check for bench results.
- If a PR exists (`gh pr list --author`) → Phase 8 was reached, check CI status.

No phase reads state from memory that isn't also in the document. If the file exists, the investigation is resumable. If it doesn't, start fresh.

## The outer loop

The full pipeline iterates. A kill in any downstream phase re-enters the hypothesis graph, and the entire pipeline runs again from the new diagnosis. This is not a special case — it's the normal operating mode.

```
 ┌──────────────────────────────────────────────────────────┐
 │                                                          │
 ▼                                                          │
Interrogate → Prework → Benchmark → Bug hunt → Ship        │
                            │            │                  │
                            │ oscillatory│ kill             │
                            │            │                  │
                            └────────────┴── classify ──────┘
                                             re-enter
```

**Idempotency guard:** before Phase 8 (ship) on any iteration, check for existing PRs:
- `gh pr list --repo <target> --search "<keywords from diagnosis>"` — look for open PRs addressing the same issue.
- `gh pr list --repo <target> --author <user> --state all` — check if a previous iteration already created a PR.
- If a PR exists: update it (push to same branch, edit description) rather than creating a new one. Never create duplicate PRs from successive iterations.
- If someone else's PR addresses the same issue: link to it in the graph document and stop. The investigation becomes evidence for their PR, not a competing one.

**Halt condition:** the outer loop terminates when:
- Bug hunt converges (both codex and Gemini report zero new findings), OR
- The human redirects, OR
- Three consecutive iterations produce the same diagnosis (fixed point), OR
- An existing PR already addresses the surviving hypothesis (contribute evidence, don't duplicate)

The tinygrad investigation iterated twice: the first fix (remove GROUP + wider UPCAST) was killed by the bug hunt, re-entered the graph as an oscillatory observation, split into sub-hypotheses, and the surviving fix (UPCAST alone) converged on the second iteration.

Without the outer loop, the first fix ships with a 25% regression on the most common code path. With it, the regression is caught, the hypothesis is refined, and the simpler fix emerges.

## Rules

- **Perturbation access is required.** If you can't poke the system, you can't investigate it. Say so and stop. The hypothesis graph only works where you can poke.
- **Classification before explanation.** Classify the trajectory shape first, then interpret. Don't skip to the explanation.
- **Kill conditions generate edges.** When a hypothesis dies, the failure mode names the next hypothesis. Don't discard kills — mine them for edges.
- **Codex filters, Claude generates.** Never reverse the roles. Claude's abductions are fertile but insecure. Codex's deductions are sterile but reliable. Use both.
- **Label provenance.** Every claim gets: which subagent generated it, which experiment tested it, which codex round validated it, which reasoning mode produced it.
- **Never suppress failures.** A well-characterized dead end (H₁ₐ: fusion hurts) is worth more than an untested hypothesis.
- **The human Attends between cycles.** Present the prune results before the next fan-out. The human picks which edges to follow.
- **Keep going to depth 10.** Don't stop after two cycles. Follow every surviving edge until the frontier closes, the human redirects, or depth 10. Each cycle: fan out, run perturbations, codex-filter, prune, write to graph, follow surviving edges. The graph deepens until it converges or hits the wall.
- **Confidence tracks mode.** Don't claim 95% confidence on an abduction. Don't claim 60% on a deduction. The mode determines the ceiling.

## E-Value Trajectory Classification

Each experiment produces samples. The samples form a trajectory. Classify the trajectory:

- **Divergent**: each sample monotonically accumulates evidence in one direction. The hypothesis is strongly supported or strongly refuted. No ambiguity.
- **Convergent**: evidence rises then settles. Partial confirmation — the hypothesis explains some but not all of the observation. Refine.
- **Oscillatory**: evidence waxes and wanes across samples. The hypothesis fits some cases but not others. Two or more modes visible. Split into sub-hypotheses.
- **Chaotic**: evidence is aperiodic — no pattern across samples. The perturbation isn't isolating a single cause. Decompose differently.

The shape is the edge-generation mechanism. Divergent → follow. Convergent → refine. Oscillatory → split. Chaotic → redesign the perturbation.

## Example

```
/interrogate ~/documents/tinygrad "how much of tinygrad's LLaMA inference gap is realize overhead vs kernel quality vs scheduling?"
```

Phase 1-3: H₀ (novel graph shapes) killed — JIT covers everything. H₁ₘ (matvec kernel quality) confirmed — stride-32768 in inner loop. H₂ₘ (prefill chunking) confirmed. Diagnosis converges.
Phase 5: experiment repo with reference, propose, validate, extract, compat, bench. extract.py confirms bug on Metal.
Phase 6: benchmark candidate fix (remove GROUP + wider UPCAST). +74% bandwidth.
Phase 7: bug hunt kills the fix — nn.Linear's transposed weights regress 25%.
→ Re-enter Phase 2: oscillatory → split. UPCAST alone survives. Re-benchmark: +62-105%.
→ Bug hunt round 2: codex zero, Gemini zero. Converged.
Phase 8: one-number PR, experiment repo as provenance. CI passes.
