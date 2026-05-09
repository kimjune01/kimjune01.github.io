---
name: mise-en-place
description: Pre-investigation checklist. Ensures the system under test, methodology, experiment repo, ambiguity heuristic, and goal are established before any work begins. Gate before /investigate.
argument-hint: <system-path-or-description>
allowed-tools: Read, Write, Edit, Bash, Agent, AskUserQuestion
---

# Mise en place

Everything in its place before the first cut. This skill ensures five things are established before an investigation begins. No implementation until all five are answered.

## Checklist

Work through each item in order. For each one: check if it already exists in the experiment repo, ask the user if ambiguous, document the answer. Do not proceed to the next item until the current one is resolved.

### 1. System under test

What system are we investigating? Where does the source live? Can we perturb it?

- Identify the target system (codebase path, repo URL, or description)
- Confirm perturbation access: can we change inputs, configurations, or code and observe the effect?
- **Verify identity at runtime, not by configuration.** The labeled target and the actually-resolved target can diverge silently — fallback chains, silent-pick logic, missing dependencies, and platform defaults will pick a different backend than the one the env var named. Write a probe that prints the resolved identity (renderer class, library path, version string) and run it before any measurement. Every benchmark labeled with the wrong identity is worse than no benchmark — it propagates into PR descriptions and downstream investigations as authoritative-looking false positives.
- If the source repo has a parallel session or is shared, clone it to an isolated directory
- Document in the experiment repo README

### 2. Methodology

How will we investigate, validate, and protect the work? Each has a reference framework — pick the one that fits, or name a different one with equivalent rigor.

Three modes, three frameworks. Each covers one edge of the [triangle](https://june.kim/modes-of-reason):

**Abduction** (Observation → Theory) — how hypotheses are generated:
- [Hypothesis graph](https://june.kim/the-hypothesis-graph): perturb, classify trajectory shape (convergent/divergent/oscillatory/chaotic), follow the edge the kill condition generates. For engineered systems you can poke.
- Name what "better" means — the metric and how it's measured.

**Deduction** (Theory → Experiment) — how claims are stress-tested:
- [Proof manual](https://june.kim/the-proof-manual): classify claim type × domain, look up candidate techniques, check kill conditions and symmetry mismatches. The kill at step N names the technique at step N+1.

**Induction** (Experiment → Observation) — how the measurement is protected:
- [Prereg checklist](https://june.kim/the-prereg-checklist): 22 questions from Bacon through Ramdas. Answer before touching data. Catches abductive retrofit, unfalsifiable claims, underpowered tests, hidden degrees of freedom.
- At minimum: state what would disprove each hypothesis before testing it.

Document in the experiment repo README or a dedicated methodology doc.

### 3. Experiment repo

Where does the work happen? Is it set up?

- Create or identify the experiment repo (separate from the system under test)
- `git init` with an initial commit
- CLAUDE.md for future sessions
- Baseline measurement script and raw data
- Hypothesis graph (even if just H0)
- Reference materials: [parts bin](https://june.kim/the-parts-bin) for algorithm lookup when the investigation diagnoses a broken role

### 4. Ambiguity heuristic

When two approaches seem equivalent, how do we choose?

- Name a single tiebreaker (lines of code, latency, trial count, etc.)
- The heuristic must be measurable, not subjective
- Document in README

### 5. Dependency graph

If there are multiple hypotheses or workstreams, what's the ordering?

- Which hypotheses must be tested first?
- Which can run in parallel?
- What blocks what?
- Document in the hypothesis graph or README

### 6. Overarching goal

What does success look like? What would make us stop?

- State the goal in one sentence
- State the falsification condition: what result would kill the project?
- Document in README

## Output

A checklist summary with status for each item:

```
mise en place
  ✓ system under test: <what>
  ✓ methodology: <what>
  ✓ experiment repo: <path>
  ✓ ambiguity heuristic: <what>
  ✓ dependency graph: <ordering>
  ✓ goal: <what>
```

If any item is missing or ambiguous, stop and resolve it before proceeding. The checklist is the gate — nothing starts until it's complete.

## When to use

Before `/investigate`. Before any multi-session research project. Before building anything where "what are we even doing" might come up three sessions from now.

The cost of this checklist is 10 minutes. The cost of skipping it is a session spent building the wrong thing.
