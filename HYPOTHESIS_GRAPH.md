# Hypothesis Graph: tinygrad Line Budget

**System**: tinygrad (github.com/tinygrad/tinygrad)
**Source**: `~/Documents/tinygrad` at commit `50aa70a25`
**Date**: 2026-05-07
**Entry point**: `sz.py` line counter + `MAX_LINE_COUNT` CI gate in `.github/workflows/test.yml`

## H₀: Baseline Observation

**Original hypothesis**: "The 10k line hard cap forces selection pressure where every new feature must displace existing code."

**Perturbation**: Run `sz.py` and check `MAX_LINE_COUNT` in CI.

**Result**: The cap is **24,000**, not 10k. Currently at **23,364 total lines** (8,928 core). **636 lines of headroom** (97.4% full). The budget has been raised **9 times in 2025** (15,500 → 16,000 → 17,000 → 17,500 → 18,000 → 18,500 → 19,000 → 19,150 → 20,000 → 24,000). The most recent jump (20k→24k) was the largest — a 20% increase.

**Trajectory**: Divergent from original hypothesis. The cap is not a fixed constraint — it's a ratchet that accommodates growth. The selection pressure exists but is softer than claimed: social (szdiff bot comments on every PR) rather than hard-blocked.

**Kill condition**: The "10k hard cap forces displacement" framing is wrong. Revised question: **with 636 lines of headroom, what concrete reductions can offset new features like WARP_REDUCE (+52 lines)?**

**Mode**: Induction (measured). Confidence: 95%.

---

## Graph State Table

| Node | Hypothesis | Status | Shape | Lines | Alignment |
|------|-----------|--------|-------|-------|-----------|
| H₀ | 10k hard cap forces displacement | **Killed** | Divergent | — | — |
| H₀' | 636-line headroom creates urgency for offsets | **Confirmed** | Convergent | — | Active |
| H₁ₐ | onnx.py protobuf parser refactor | **Confirmed** | Convergent | ~50 | #15717 |
| H₁ᵦ | Renderer prefix deduplication | **Killed** | Divergent | 4-5 | #14971 |
| H₁ᵧ | Dead code in top 10 files | **Killed** | Convergent (zero) | 0 | — |
| H₂ₐ | TIP #14215 PARAM/CALL (5 UOps → 2) | **Open** | Unknown | Large | #14215 |
| H₂ᵦ | TIP #14817 Recursive Scheduling | **Open** | Unknown | Medium | #14817 |
| H₂ᵧ | TIP #14971 Unified Renderer API | **Open** | Unknown | Small-Medium | #14971 |
| H₃ₐ | Active removal PR: onnx dtype_fallback | **Confirmed** | Convergent | -7 | #15717 |
| H₃ᵦ | Active removal PR: gate from index | Partial | Convergent | -2 | #16081 |
| H₃ᵧ | Active removal PR: UOp.cast check | Partial | Convergent | -2 | #15899 |
| H₃δ | Active removal PR: CORRECT_DIVMOD_FOLDING | **Killed** | Oscillatory | +25 | #15504 |
| H₃ε | Gate movement refactor (#16040 vs #16020) | **Killed** | Oscillatory | +13/+28 | #16040 |
| H₄ₐ | HCQ Program init dedup (AMD/NV) | Partial | Convergent | ~15-20 | — |
| H₄ᵦ | viz/js dead variable | Confirmed | Convergent | 1 | — |

---

## Confirmed Reduction Opportunities (ranked by issue/PR alignment)

### Rank 1: onnx.py protobuf parser refactor (~50 lines)

**Alignment**: PR #15717 (onnx: remove dtype_fallback, -7 lines) is already open. This refactor is additive to that PR.

**Mechanism**: Seven `_parse_*` methods (lines 298-358) follow an identical pattern:
```python
obj = {}
for fid in msg:
    match fid:
        case N: obj[k] = reader.read_X()
        case _: skip
return obj
```
A data-driven generic parser taking `{fid: (field_name, read_method)}` replaces ~69 lines with ~19 lines of config + generic function.

**Risk**: Low. Pure refactor within a self-contained parser. No behavioral change.
**Mode**: Deduction (code analysis). Confidence: 90%.

### Rank 2: HCQ Program init dedup (~15-20 lines)

**Alignment**: No open PR. Aligns with the general HCQ abstraction direction.

**Mechanism**: Both `AMDProgram.__init__` and `NVProgram.__init__` share an identical alloc-copy-sync-finalize sequence. The relocation loop differs, but the setup/teardown is the same.

**Risk**: Medium. Touching hardware init paths requires testing on both AMD and NV.
**Mode**: Deduction (code analysis). Confidence: 80%.

### Rank 3: Active removal PRs (cumulative ~-11 lines)

- #15717 onnx dtype_fallback: -7 lines
- #16081 gate from index: -2 lines
- #15899 UOp.cast check: -2 lines

These are already in flight. No action needed — just track.

---

## Killed Hypotheses (Pruning Log)

### H₁ᵦ: Renderer prefix deduplication — KILLED

**Claimed**: 60-80 lines saveable by factoring shared `render_kernel` prefix logic.

**Actual**: Only `uops_to_dtypes(uops)` and the vector-prefix loop are shared (~4-5 lines). The three `render_vector_prefix` definitions use completely different syntax (Clang ext_vector_type vs CUDA __align__ structs vs HIP device inline). The WMMA code is entirely backend-specific.

**Kill**: Verification perturbation. Read the actual code — the duplication is conceptual, not textual.
**Mode**: Deduction. Confidence: 95%.

### H₁ᵧ: Dead code in top 10 files — KILLED

Every function and class in the top 10 files is referenced in `tinygrad/`, `test/`, `extra/`, or `examples/`. The codebase is remarkably clean.

**Kill**: Exhaustive grep. No unreferenced symbols found.
**Mode**: Induction. Confidence: 95%.

### H₃δ: CORRECT_DIVMOD_FOLDING removal — KILLED

Despite "remove" in the title, PR #15504 adds +25 net lines — replacing a feature flag with explicit folding logic that's larger than the flag it removes.

**Kill**: Measured PR diff. Oscillatory — removes a flag but adds replacement code.
**Mode**: Induction. Confidence: 95%.

### H₃ε: Gate movement refactor — KILLED (as line reduction)

Both #16040 (+13 lines) and #16020 (+28 lines) are net additions. They're structural improvements, not line reductions.

**Kill**: Measured PR diffs.
**Mode**: Induction. Confidence: 95%.

---

## Open Frontier (TIPs — structural, high-impact, long-term)

### H₂ₐ: TIP #14215 — PARAM/CALL

**Hypothesis**: Replacing DEFINE_GLOBAL, DEFINE_VAR, SPECIAL, KERNEL, CUSTOM_KERNEL with PARAM + CALL (lambda-calculus semantics) would reduce ops from 93 to ~90 and eliminate UOps-in-args patterns across codegen, spec, and renderer files.

**Predicted trajectory**: Convergent but slow. This is geohot's proposal and requires deep structural changes. Line savings would cascade — fewer ops means simpler match statements in every file that pattern-matches on UOps.

**Perturbation needed**: Count every `case Ops.DEFINE_GLOBAL | Ops.DEFINE_VAR | Ops.SPECIAL | Ops.KERNEL | Ops.CUSTOM_KERNEL` across the codebase. Multiply by the ratio of cases consolidated.

**Risk**: High. Architectural change. Would break every downstream tool and test.

### H₂ᵦ: TIP #14817 — Recursive Scheduling

**Hypothesis**: Collapsing two-layer scheduling (big graph + kernels) into recursive scheduling would simplify `schedule/` (currently 920 lines across 6 files).

**Predicted trajectory**: Convergent. Pure architectural simplification.

**Perturbation needed**: Measure how much of `schedule/rangeify.py` (397 lines) and `schedule/indexing.py` (187 lines) is two-layer-specific.

### H₂ᵧ: TIP #14971 — Unified Renderer API

**Hypothesis**: Unified `arch` string parameterization would remove `functools.partial` hacks and implicit Device/Renderer coupling in `renderer/` (2,855 lines across 11 files).

**Predicted trajectory**: Convergent. Aligns with H₁ᵦ failure — the renderers aren't textually duplicated, but they are architecturally coupled in ways that a unified API could clean up.

---

## Reasoning Mode Table

| Claim | Mode | Source | Confidence |
|-------|------|--------|------------|
| Line count is 23,364 / cap is 24,000 | Induction | sz.py + CI config | 95% |
| Budget raised 9x in 2025 | Induction | git log of test.yml | 95% |
| onnx.py parser refactor saves ~50 lines | Deduction | Code analysis | 90% |
| Renderer dedup saves only 4-5 lines | Deduction | Code comparison | 95% |
| No dead code in top 10 files | Induction | Exhaustive grep | 95% |
| TIP #14215 would reduce ops | Abduction | Issue description | 70% |
| TIP #14817 would simplify scheduling | Abduction | Issue description | 65% |
| HCQ init dedup saves 15-20 lines | Deduction | Code comparison | 80% |

---

## Causal Chain

```
H₀ (10k cap) ──killed──> H₀' (636-line headroom at 24k)
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
         Concrete         In-flight       Structural
         reductions       removals        TIPs
              │               │               │
         H₁ₐ: onnx      H₃ₐ,ᵦ,ᵧ:       H₂ₐ,ᵦ,ᵧ:
         ~50 lines       ~-11 lines      unknown
         H₄ₐ: HCQ                       (large)
         ~15-20 lines
              │
              ▼
         Total concrete: ~65-70 lines saveable
         vs WARP_REDUCE cost: +52 lines
         Net: +13-18 lines freed
```

## Summary

The codebase is clean. There is no dead code, minimal textual duplication, and the line budget is a social ratchet that gets raised when needed (9 times in 2025). The realistic line-reduction surface is ~65-70 lines from two concrete refactors (onnx protobuf parser, HCQ init dedup), which roughly offsets WARP_REDUCE's +52 lines.

The real line-budget play is the three open TIPs — PARAM/CALL (#14215) in particular could cascade significant savings by reducing the op count and simplifying every match statement in the codebase. But these are architectural changes on geohot's timeline, not external contributions.

**Recommendation**: For an external contributor, the onnx.py protobuf refactor is the highest-leverage PR: ~50 lines saved, low risk, aligns with #15717, and offsets almost all of WARP_REDUCE's +52.
