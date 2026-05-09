---
name: investigate
description: Run a hypothesis graph on an engineered system. Perturb, classify the evidence trajectory, follow the edge. Fan-out for breadth, codex for adversarial filtering, e-value classification for shape. Produces a hypothesis graph document with provenance.
argument-hint: <system-or-question>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, WebFetch, WebSearch
---

# Investigate: Hypothesis Graph to PR

Perturb an engineered system, classify the evidence trajectory, follow the edge the kill condition generates. Runs autonomously through all phases — observation, fan-out, extend, prework, benchmark, bug hunt — until the frontier closes, depth 10, or a PR emerges. The only human gate is Phase 8 (ship), because a PR is an external side effect. Everything before it is local, reversible, and should proceed without asking.

## Dependencies

Phases 1-6 are self-contained — they use only the tools in `allowed-tools`. Phases 7-8 invoke other skills:

| Skill | Used in | Purpose | Fallback if missing |
|-------|---------|---------|-------------------|
| `/codex` | Phase 2 (filter), Phase 7 (hunt) | Structural review via codex CLI | `cat <<'EOF' \| codex exec -` directly |
| `/gemini` | Phase 7 (hunt) | Logic-tracing review via Gemini API | Skip — codex alone is sufficient for convergence, just slower |
| `/bug-hunt` | Phase 7 | Multi-pass adversarial loop | Run codex manually in rounds, track findings in a file |

If the target machine doesn't have `codex` CLI installed, Phases 1-6 still work but Claude's abductions go unfiltered. Expect one-pass overclaiming — downgrade confidence on surviving hypotheses by ~10% and flag in the graph document that codex filtering was unavailable. Phase 7 degrades to manual review (Claude alone, no adversarial second opinion). Phase 8 (ship) only needs `git` and `gh`.

The skill reads no machine-specific paths. All file references are relative to the target system passed as the argument.

## Theory

- **Hypothesis graph**: [The Hypothesis Graph](https://june.kim/the-hypothesis-graph) — perturb, classify, follow the edge. Kill conditions generate the next hypothesis.
- **E-value classification**: [Evidence has a trajectory](https://june.kim/evidence-has-a-trajectory) — every experiment produces a trajectory classifiable as convergent, divergent, oscillatory, or chaotic. The shape names the next question. Lineage: sequential testing (Wald 1945), e-values and safe anytime-valid inference (Vovk & Wang 2021).
- **Modes of reason**: [Modes of Reason](https://june.kim/modes-of-reason) — abduction proposes, deduction traces consequences, induction tests. The abduction/deduction/induction split is Peirce's (1878). Label each node's reasoning mode and track confidence accordingly.

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
5. Write H₀ to the graph document. Pick the highest-leverage edge and continue to Phase 2 — don't stop to ask.

### Phase 2: Fan-out (H₁...Hₖ)

Generate competing hypotheses for the observation. This is abduction — highest uberty, lowest security.

1. **Fan out k hypotheses** (default k=3). Launch subagents in parallel, each exploring a different causal explanation. Each subagent gets:
   - The H₀ observation
   - A distinct angle to investigate
   - A concrete perturbation to run (not "explore this direction" — "measure this quantity under this condition")
   - **Isolation rule.** Measurement-only perturbations (read code, run existing benchmarks, profile) share the original system — no copy needed. Intervention perturbations (apply patches, change env vars, generate files) each get their own copy: `cp -r` the target directory to `/tmp/interrogate-H{n}/`. The distinction matters for cost: most fan-out branches are measurement-only; only branches that modify state need isolation.

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

   **Codex/Gemini review findings are hypothesis generators.** When a reviewer flags a risk, edge case, or untested assumption, don't just "soften the claim" — add the concern as a new open hypothesis in the graph with a concrete perturbation. A reviewer saying "prune might misclassify cache kernels" is an abduction: it proposes a failure mode. Treat it like any other abduction — design a perturbation, run it, classify the trajectory.

   This prevents review feedback from decaying into vague caveats. Each concern either gets tested (and confirmed or killed) or stays visible as an open frontier edge.

4. **Prune.** Kill hypotheses that:
   - Codex disproved (deduction killed the abduction)
   - The experiment refuted (induction killed the abduction)
   - Produced oscillatory classification (too coarse — refine, don't keep)

5. **Write nodes to graph document.** Each node gets its full record: hypothesis, null, perturbation, trajectory, shape classification, kill condition, edge.

6. **Continue autonomously.** Follow all surviving edges. Prioritize by: cheapest decisive perturbation first. Write the graph state table to the document after each cycle so the human can review asynchronously, but don't stop to present — keep going.

### Phase 2.5: Provenance check (every conclusive hypothesis)

**Mandatory on every confirmed or killed hypothesis**, not just those proposing code changes. A hypothesis that reaches a conclusion (confirmed, killed, or refined) must have its provenance checked before the conclusion is trusted. This catches:
- Deliberate design choices misread as bugs (H₁₂: geohot's REALIZE=0 was intentional)
- Existing mechanisms that already solve the problem (H₁₃: prune_linear existed but was never applied to LLM loading)
- Adjacent work by other contributors that the investigation might duplicate or conflict with

1. **Git blame.** When did the current code enter the repo? Who wrote it, and what was the commit message? A deliberate design choice has different weight than a migration default that was never reconsidered.

2. **Issue/PR search.** Search the upstream project's issue tracker for the proposed change (e.g., `site:github.com/project "client:only" build performance`). Look for:
   - Known bugs or regressions with the proposed approach
   - Gotchas others hit (CSS extraction, styling, hydration)
   - Whether the issue was fixed, open, or has workarounds

3. **Adjacent clue synthesis.** Combine git history + upstream issues into a risk assessment. Check whether different contributors built complementary pieces that nobody connected (e.g., contiguous as fusion barrier + prune as onetime detection, built 18 days apart by different people). The gap between existing mechanisms is often more actionable than building new ones.

4. **Write findings to graph document.** Add a "Provenance" section to the conclusive hypothesis with: origin commit, upstream issues found, risk assessment, and whether existing mechanisms were overlooked.

### Phase 3: Extend (H₂...Hₙ)

Follow the surviving edges. Each edge is a new hypothesis generated by a kill condition.

1. For each surviving edge, design a perturbation that would classify it. Prefer perturbations that are:
   - **Decisive**: the result distinguishes this hypothesis from alternatives
   - **Cheap**: fast to run, doesn't require external access
   - **Reversible**: doesn't modify the system under investigation

2. Run the perturbation. Classify. Codex-filter. Prune. Write.

3. Repeat until:
   - The frontier closes (all edges point to already-classified nodes)
   - A candidate fix emerges and passes Phase 5.5 (regression check) — proceed to prework and ship pipeline
   - The human redirects
   - Depth 10 reached (hard stop — present the graph)

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

If the diagnosis implies a code change, continue to Phase 4.5 and the prework/ship pipeline. If the frontier is still open, return to Phase 3. Don't stop to ask — the graph document records the state.

### Phase 4.5: Reframe

Check whether the investigation has produced a load-bearing observation that retires the original framing. This happens when the surviving hypothesis isn't a fix — it's a pattern, a structural insight, or a reframing that makes the original H₀ the wrong question.

1. **Test for reframe.** Does the surviving hypothesis answer the original question, or does it replace it? If H₀ was "why is X slow?" and the surviving hypothesis is "X's tightness is manufactured by a specific human process, not an architectural pattern," the output is an observation, not a code change.

2. **Capture the transferable pattern.** If the investigation reframes, write the observation as:
   - A memory entry (if it's a durable insight about how a system or team works)
   - A blog post seed (if it's a transferable pattern worth publishing)
   - A graph document annotation (always — the reframe is part of the provenance)

3. **Record the reframe** in the graph document. If the reframe retires the original question entirely, halt — the graph is the output. If the reframe opens new edges (it usually does), return to Phase 3 and keep going.

4. **Halt condition.** The investigation terminates when the frontier closes, depth 10, or a PR ships. A reframe that opens no new edges is a natural halt. Don't ask for permission to continue — the graph document records the state for the human to review.

### Phase 5: Prework

When a surviving hypothesis implies a code change, build the [prework](/prework) artifacts before touching production. Keep all prework in one directory: `prework/<slug>/` in the worktree (e.g., `prework/matvec-stride/`). The directory ships with the branch and gets deleted when the PR merges. Only create a standalone experiment repo when the prework needs to outlive the PR — provenance for a controversial change, or a reusable benchmark that applies across repos.

1. **Prework artifacts.** Build these in `prework/<slug>/`:
   - `reference.py` — ground truth (numpy, BLAS, or known-good implementation)
   - `propose.py` — the candidate fix as a pure function
   - `validate.py` — propose matches reference for all test cases
   - `extract.py` — dumps the target system's actual behavior for comparison
   - `compat.py` — proves the fix doesn't change correctness (numerical equivalence, output identity)
   - `bench.py` — measures the fix against the baseline
   - `shapes.py` — test matrix covering the target shapes AND regression shapes

   For simple fixes (one-liner, obvious correctness), skip the full artifact set. Write a failing test and the fix. The prework scales with the risk of the change.

2. **Derisk.** Run `extract.py` to confirm the bug exists in the target. If it doesn't, the diagnosis was wrong — go back to Phase 2. This is the most important step. Without it, the prework is speculative.

### Phase 5.5: Regression check (before benchmark)

**Mandatory before Phase 6.** Before measuring speedup, verify the fix doesn't break anything. This catches correctness regressions cheaply — before investing in benchmarking and bug hunts.

1. **Output equivalence.** Run `compat.py` — the fix must produce identical results to the baseline. For LLM inference: same token sequences. For numerical code: same outputs within tolerance. If outputs diverge, the fix has a correctness bug — stop and diagnose before proceeding.

2. **Existing test suite.** Run the target project's tests for the affected subsystem. Don't run the entire suite (too slow, too many unrelated failures from missing deps). Target:
   - Tests that import the changed module
   - Tests that exercise the affected code path (e.g., `test_jit.py` for JIT changes, `test_gguf.py` for GGUF changes)
   - Any tests tagged with the feature name (`-k "prune or gguf or jit"`)

3. **Gate.** All tests must pass before proceeding to Phase 6. If tests fail, classify: is it a real regression (fix broke something) or a pre-existing failure (missing deps, hardware-specific skip)? Only real regressions block.

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

**Pipeline mode vs standalone.** When called from `/triage` or `/sweep`, investigate does NOT ship directly. Instead, write a readiness record to `/tmp/triage-dry-run/<number>-pr.md` (branch, base commit, test commands, diff, PR draft) and return. `/drip` handles all remote operations — pushing, PR creation, tone matching, pacing. When running standalone (user invoked `/investigate` directly), Phase 8 ships as described below.

Present to the human:
- The diff (should be small — if it's not, the prework missed something)
- The benchmark table
- The bug hunt convergence status
- The PR title and body draft
- Any existing PRs found by the idempotency guard

If approved (standalone mode only):

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
| 4.5 Reframe | Transferable observation | Yes — insight that retires the original question |
| 5 Prework | Experiment repo | Yes — a validated prototype |
| 6 Benchmark | Measurement table | Yes — evidence for or against |
| 7 Bug hunt | Convergence report | Yes — adversarial verification |
| 8 Ship (standalone) | PR with provenance | Yes — contribution with full trail |
| 8 Ship (pipeline) | Readiness record | Yes — candidate for `/drip` queue |

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
- Bug hunt converges (both codex and Gemini report zero new findings) AND the PR ships, OR
- The human redirects, OR
- Frontier closes (all edges classified, no open hypotheses), OR
- Three consecutive iterations produce the same diagnosis (fixed point), OR
- An existing PR already addresses the surviving hypothesis (contribute evidence, don't duplicate), OR
- Depth 10 reached (hard stop — present the graph)

**Do not halt at diagnosis.** If the diagnosis implies a fix, continue through prework → benchmark → regression check → bug hunt → ship. The only human gate is Phase 8 (ship). Everything else runs autonomously.

The tinygrad investigation iterated twice: the first fix (remove GROUP + wider UPCAST) was killed by the bug hunt, re-entered the graph as an oscillatory observation, split into sub-hypotheses, and the surviving fix (UPCAST alone) converged on the second iteration.

Without the outer loop, the first fix ships with a 25% regression on the most common code path. With it, the regression is caught, the hypothesis is refined, and the simpler fix emerges.

## Rules

- **Perturbation access is required.** If you can't poke the system, you can't investigate it. Say so and stop. The hypothesis graph only works where you can poke.
- **Classification before explanation.** Classify the trajectory shape first, then interpret. Don't skip to the explanation.
- **Kill conditions generate edges.** When a hypothesis dies, the failure mode names the next hypothesis. Don't discard kills — mine them for edges.
- **Codex filters, Claude generates.** Never reverse the roles. Claude's abductions are fertile but insecure. Codex's deductions are sterile but reliable. Use both.
- **Label provenance.** Every claim gets: which subagent generated it, which experiment tested it, which codex round validated it, which reasoning mode produced it.
- **Never suppress failures.** A well-characterized dead end (H₁ₐ: fusion hurts) is worth more than an untested hypothesis.
- **Run autonomously between cycles.** Write the graph state to the document after each cycle, but don't stop to present. Pick the highest-leverage surviving edge and keep going. The human can redirect at any time — the graph is always readable — but the default is forward motion.
- **Keep going to depth 10.** Don't stop after two cycles. Follow every surviving edge until the frontier closes, the human redirects, or depth 10. Depth = outer-loop iterations (a full pass through interrogate → prework → benchmark → bug-hunt counts as one iteration; phases within an iteration don't increment depth). Each cycle: fan out, run perturbations, codex-filter, prune, write to graph, follow surviving edges. The graph deepens until it converges or hits the wall.
- **Confidence tracks mode.** Don't claim 95% confidence on an abduction. Don't claim 60% on a deduction. The mode determines the ceiling.
- **Graph-first on new evidence.** Any new evidence that changes a node's status — CI result, measurement, code trace — must be written to the graph document before anything else happens. Not "should I update the graph?" — write it. The graph is the checkpoint; if it's not written, the investigation isn't real. Then classify the trajectory, follow the edge, design the next perturbation. The human reviews the graph asynchronously; they should never have to prompt "update the hypothesis graph."
- **CI is a perturbation surface.** When the system under investigation has CI with hardware you don't own (GPUs, architectures, OSes), treat CI as a remote lab. Push a draft PR per investigation, one commit per perturbation. Watch CI results, classify, update the graph, push the next perturbation. The loop is: perturb → push → watch → classify → update graph → next perturbation. The only human gate is Phase 8 (ship).
- **Fail on master, pass with fix.** When the investigation finds a bug, write a test and a fix. Verify locally: the test must fail on master and pass with the fix. Ship both in one PR. A test that passes on master proves nothing — we learned this by shipping one and getting called out by a reviewer.

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
