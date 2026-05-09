# Triage Graph: tinygrad/tinygrad

## Scan (2026-05-08)

User: kimjune01. 87 open items (50 issues, 37 PRs).

### Your items

| # | Type | Score | Signal | Title | Status |
|---|------|-------|--------|-------|--------|
| 16113 | PR | 4 | Your PR, awaiting review | Failing tests (MATVEC + PTX bf16) | PENDING |
| 16114 | Issue | 3 | Issue you filed, tagged geohot | Two bugs: MATVEC + PTX bfloat16 | PENDING |

### Software bugs (reproducible without specific hardware)

| # | Score | Signal | Title | Repro | Cross-ref | Status |
|---|-------|--------|-------|-------|-----------|--------|
| 7020 | 2 | Maintainer (chenyuxyz), 5 comments | TinyJit returns wrong values | Likely — correctness critical | #6803 | PENDING |
| 12296 | 2 | Maintainer (chenyuxyz) | max backward can underflow | Likely — correctness | #13322 (open PR) | PENDING |
| 12409 | 2 | Unassigned, 1 comment | gradients through where with nan branch | Likely — correctness | | PENDING |
| 11495 | 2 | Unassigned, 4 comments | torch.linalg.matrix_rank wrong for identity | Likely — correctness | | PENDING |
| 13409 | 2 | Unassigned, 0 comments, 6mo stale | Onnx ScatterND infinite loop in graph_rewrite | Likely — clear description | | PENDING |
| 13179 | 2 | Unassigned, 1 comment | Variable expression equality bug | Likely — symbolic | | PENDING |
| 8617 | 2 | Maintainer (chenyuxyz), 3 comments | stacking many tensors hits recursion limit | Likely — reproducible | | PENDING |
| 11908 | 2 | Unassigned, 1 comment | Beam cache doesn't invalidate on env var change | Likely — clear bug | | PENDING |
| 15351 | 2 | Unassigned, 3 comments | mnist_gan invalidbitwidth | Likely — reproducible | | PENDING |
| 11966 | 2 | Unassigned, 2 comments | GPU dims limiting bug | Likely — internals | | PENDING |
| 10144 | 2 | Labeled bug+upstream, 4 comments | LLVM+BEAM breaks permuted matmul on M4 Pro | Locally reproducible | | PENDING |
| 6803 | 2 | Unassigned, 7 comments | JIT bad output SDXL SplitVanillaCFG | Likely — correctness | #7020 | PENDING |

### Maintainer-filed (geohot wants these done)

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 6909 | 3 | geohot + good first issue | If BF16 isn't supported, it should autocast to float | PENDING |
| 7889 | 3 | geohot + good first issue | Make TYPED=1 work | PENDING |
| 6922 | 2 | geohot, 3 comments | Bad loop ordering resulting in too many loads | PENDING |
| 9262 | 2 | geohot, 3 comments | Changes requested from pytorch backend | PENDING |
| 13707 | 2 | geohot | Fix JIT to assert if schedulecaches don't match | PENDING |
| 13699 | 2 | geohot | Remove image dtype and make it a late rewrite | PENDING |
| 11001 | 2 | geohot | Kernelize/kernel.py/Lowerer refactor | PENDING |
| 10400 | 2 | geohot | Remove DISK hack from assign | PENDING |
| 8762 | 2 | geohot TIP | Linearize for Kernels | PENDING |
| 8618 | 2 | geohot | stunning mnist | PENDING |
| 6411 | 2 | geohot | Bad ordering in allreduce | PENDING |

### Maintainer-filed (chenyuxyz)

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 13165 | 2 | chenyuxyz | KernelInfo name not overwriting | PENDING |
| 12514 | 2 | chenyuxyz | inconsistent SPLIT_REDUCEOP | PENDING |
| 12231 | 2 | chenyuxyz | arange .to should recreate not transfer | PENDING |
| 11756 | 2 | chenyuxyz | bf16 numerical issue on exp, log, cos | PENDING |
| 11626 | 2 | chenyuxyz | x.abs()**2 is x**2 | PENDING |
| 11548 | 2 | chenyuxyz | z3 hangs while beaming embedding | PENDING |
| 7922 | 2 | chenyuxyz | sdv2 different output fp16 Metal | PENDING |

### Design proposals

| # | Score | Author | Title | Status |
|---|-------|--------|-------|--------|
| 14817 | 2 | geohot | TIP: Recursive Scheduling | PENDING |
| 14215 | 2 | geohot | TIP: add PARAM/CALL hierarchy | PENDING |
| 8762 | 2 | geohot | TIP: Linearize for Kernels | PENDING |
| 14971 | 2 | sirhcm | TIP: Unified Renderer API | PENDING |
| 7787 | 2 | geohot | Switch Allocator with Buffer | PENDING |

### Hardware/driver (need specific hardware — skip)

19 items. RTX/eGPU/TinyGPU/MESA/OpenCL driver issues. Not investigable without hardware.

### Tracking/milestones (observe only)

7 items. MI350X roadmap (Flash Attention, Llama training, assembly output). Not actionable.

### External PRs (not ours — observe only)

37 open PRs from other contributors. Notable cross-refs:
- **#15951** (Qazalin): sqtt rdna4 wmma overlap — cross-ref our H0.6a WMMA lane mapping finding
- **#16067** (Qazalin): fix bank conflicts in amd_copy_matmul — RDNA4 related
- **#13322** (markerdmann): Fix max backward counts — cross-ref #12296
- **#15518** (Yaskophx): reduce GPU hogging — labeled "ai slop" in title by author

### Stale/vague (low priority)

10 items. No repro, vague description, or support questions.

## Cross-references

- **bf16 cluster:** #6909 (autocast) ↔ #11756 (numerical) ↔ #16114 (PTX KeyError). Same dtype, different failure modes.
- **JIT correctness:** #7020 (wrong values) ↔ #6803 (bad SDXL output). May share root cause.
- **max backward:** #12296 (underflow) ↔ #13322 (open PR fix).
- **RDNA4 WMMA:** #15951 (Qazalin's overlap work) ↔ #16067 (bank conflicts) ↔ our H0.6a finding. Different angles on the same hardware constraint.
- **OpenCL ambiguous calls:** #12237 (sqrt) ↔ #9930 (exp2). Same root cause — missing explicit casts.

## Recommended investigation order

Priority: reproducible locally > correctness > maintainer filed > stale opportunity.

1. **#6909** — bf16 autocast (geohot filed, good first issue). Directly related to our PTX bf16 work. Test-first: write a test that expects bf16 to autocast to float on unsupported backends.
2. **#7889** — Make TYPED=1 work (geohot filed, good first issue). Signals he wants external help.
3. **#12296** — max backward underflow (chenyuxyz, correctness). #13322 may already fix it — check.
4. **#12409** — gradients through where with nan (correctness).
5. **#13409** — ScatterND infinite loop (clear bug, 6mo stale, zero attention).
6. **#11908** — Beam cache invalidation (we know BEAM internals).
7. **#10144** — LLVM+BEAM permuted matmul on M4 Pro (locally reproducible).
8. **#7020** — TinyJit wrong values (critical correctness, chenyuxyz filed).
9. **#13179** — Variable expression equality (symbolic, testable).
10. **#11756** — bf16 numerical issues (related to #6909, same cluster).

---

## T11908: Beam cache doesn't invalidate when optimization env vars change

**Status:** Fix written + tests passing. Dry run -- not pushed.

### Root cause

The beam search cache key (`tinygrad/codegen/opt/search.py`, line 123) was:
```python
key = {"ast": s.ast.key, "amt": amt, "allow_test_size": allow_test_size,
       "device": s.ren.target.device, "suffix": s.ren.suffix}
```

It does not include any of the env vars that affect beam search behavior. When you change `BEAM_UPCAST_MAX`, `BEAM_LOCAL_MAX`, `BEAM_UOPS_MAX`, `BEAM_PADTO`, `NOLOCALS`, `TC`, or `TC_OPT` between runs, the cache serves a stale result from the previous configuration.

### Env vars that affect beam search output

| Env var | Default | Where read | Effect |
|---------|---------|-----------|--------|
| `BEAM_UPCAST_MAX` | 256 | `get_kernel_actions` (call time) | Limits max upcast factor |
| `BEAM_LOCAL_MAX` | 1024 | `get_kernel_actions` (call time) | Limits max local size |
| `BEAM_UOPS_MAX` | 3000 | `_try_compile` (call time) | Filters kernels with too many uops |
| `BEAM_PADTO` | 0 | module import time | Adds PADTO actions to search space |
| `NOLOCALS` | 0 | module import time | Adds NOLOCALS action to search space |
| `TC` | 1 | module import time | Affects TC arg in actions list |
| `TC_OPT` | 2 | module import time | Affects TC arg in actions list |
| `BEAM_MIN_PROGRESS` | 0.01 | `beam_search` (call time) | Affects termination criterion |

Note: `getenv` is `@functools.cache` -- values are frozen per-process. The bug manifests across separate process invocations (different tinygrad runs), not within a single process.

### Fix

Added 7 env var values to the cache key dict (line 123 of `search.py`):
```python
key = {"ast": s.ast.key, "amt": amt, "allow_test_size": allow_test_size,
       "device": s.ren.target.device, "suffix": s.ren.suffix,
       "BEAM_UPCAST_MAX": getenv("BEAM_UPCAST_MAX", 256),
       "BEAM_LOCAL_MAX": getenv("BEAM_LOCAL_MAX", 1024),
       "BEAM_UOPS_MAX": getenv("BEAM_UOPS_MAX", 3000),
       "BEAM_PADTO": getenv("BEAM_PADTO", 0),
       "NOLOCALS": getenv("NOLOCALS", 0),
       "TC": getenv("TC", 1),
       "TC_OPT": getenv("TC_OPT", 2)}
```

`BEAM_MIN_PROGRESS` was omitted: it affects how long search runs (quality), not which optimizations are valid. Including it would bust the cache on trivial threshold changes. Judgment call -- could include it later.

### Tests

`test/null/test_beam_cache_invalidation.py` -- 9 tests, all passing:
- Captures the real cache key from `beam_search` via mock injection (patches `diskcache_get` to intercept the key, returns fake cached value to short-circuit)
- Asserts each of the 7 env vars is present in the key
- Asserts env var values match `getenv` defaults
- End-to-end: stores under one key, looks up with a different `BEAM_UPCAST_MAX` value, asserts cache miss

### Side effect: schema migration

Existing `beam_search_22` tables in `cache.db` have 5 columns. After this fix, the key has 12 columns. `diskcache_put` uses `CREATE TABLE IF NOT EXISTS` -- it won't add columns to existing tables. First write after the fix will fail with `sqlite3.OperationalError: table beam_search_22 has no column named BEAM_UPCAST_MAX`. Fix: either bump `VERSION` (23) to create a fresh table, or `DROP TABLE beam_search_22` in a migration step. Bumping VERSION is the tinygrad convention (they're at VERSION=22).

### Files changed

- `tinygrad/codegen/opt/search.py` -- cache key expanded (1 line changed)
- `test/null/test_beam_cache_invalidation.py` -- new test file (9 tests)

---

*Dry run complete. No agents spawned, no PRs pushed.*
