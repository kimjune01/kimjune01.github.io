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

---

# Triage Graph: prometheus/client_python

## Scan (2026-05-09)

User: kimjune01. 4.3K stars, Python instrumentation library. 47 open issues, 28 open PRs.
Maintainer: csmarchbanks (MEMBER). Active -- reviewed PRs and commented on issues within last 2 weeks.

**Org risk:** prometheus org has node_exporter PR open from us. Org-blocked if that goes badly. Triaging anyway.

### Your items

| # | Type | Score | Signal | Title | Status |
|---|------|-------|--------|-------|--------|
| 1174 | PR | 5 | Fixes maintainer-acked bug #1140 | fix: raise ValueError when clear() called on metric without labels | OPEN |

### Bugs (maintainer-acknowledged)

| # | Score | Signal | Title | Cross-ref | Status |
|---|-------|--------|-------|-----------|--------|
| 1140 | 5 | MEMBER ack, bug label | _lock not found on metric | #949 (dup) | PR#1174 OPEN |
| 949 | 3 | CONTRIBUTOR + MEMBER | Metrics without labels breaks codepath | #1140 (dup) | DUPLICATE |
| 1035 | - | bug label | Incorrect name in multiprocess mode | #1146 (merged) | FIXED |

### Performance regression

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 1114 | 2 | MEMBER actively investigating | CPU perf degraded on 0.22.1 (parser) | MAINTAINER OWNS |

### Open PRs with maintainer review

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 1057 | 3 | 2 reviews, MEMBER | include timestamp in MultiProcessCollector | STALLED |
| 1081 | 2 | 1 review, MEMBER | Support new asgiref | STALLED |
| 1158 | 2 | 2 reviews, MEMBER | allow metric value class customization | STALLED |
| 1094 | 2 | 2 reviews, MEMBER | custom multiprocess metric path | STALLED |

### Feature requests (maintainer-acked, not bugs)

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 1071 | 1 | MEMBER, 5c | Public registry._names_to_collectors access | DESIGN |
| 1069 | 1 | MEMBER, 3c | Async CustomCollector | DESIGN |
| 1060 | 1 | MEMBER, 2c | Allow str from generate_latest() | DESIGN |
| 918 | 1 | MEMBER, 10c | Native histograms | PR#1104 in progress |

### No maintainer response (skip)

12 items. No MEMBER comments. Not actionable until maintainer engagement.

## Logic trace findings (from review)

**State C gap (child metrics):** `remove()`, `remove_by_labels()`, and `clear()` all crash with `AttributeError` when called on a child metric (State C: has `_labelnames` but no `_lock`). Example: `counter.labels('x').clear()`. This is a pre-existing bug in `remove()` too -- the `if not self._labelnames` guard only catches State A (no labels), not State C (child with labels+values but no _lock). Not fixed in PR#1174 because it would expand scope beyond the maintainer-acknowledged issue. Could be a follow-up PR.

## Review culture

- **Merge velocity:** ~2-3 PRs/month. Docs PRs merge faster (k1chik landed 4 docs PRs in April).
- **Gate:** Maintainer (csmarchbanks) does all reviews. No CI gate visible on PRs.
- **Bug fixes merge:** Yes. #1146, #1148, #1152, #1155, #1156 all bug fixes merged recently.
- **Features:** Slower. Many stalled PRs with 1-2 MEMBER reviews but no merge (e.g., #1057 open since April, #994 open 1+ year).
- **Pattern:** Bug fix with test = best merge probability. Match existing code style exactly.

## Recommended investigation order

1. **#1140** -- DONE. PR#1174 open.
2. **(follow-up)** State C child metric crash -- file issue first, then fix. Affects `remove()`, `remove_by_labels()`, `clear()`.
3. **Observe** #1114 performance regression -- maintainer actively working on it. Offer benchmark help if stalled.

---

## T1140: _lock not found on metric

**Status:** PR#1174 open. https://github.com/prometheus/client_python/pull/1174

### Root cause

`MetricWrapperBase.__init__` only creates `_lock` and `_metrics` when `_is_parent()` is True (metric has `labelnames` but no `labelvalues`). A metric with no labels at all (`labelnames=()`) is not a parent -- it's directly observable. Calling `clear()` on such a metric hit `with self._lock:` which raised `AttributeError`.

### Fix

Added `if not self._labelnames: raise ValueError(...)` guard at the top of `clear()`, matching the existing guard in `remove()`. Error message is identical.

### Review trail

- **Codex (GPT-5.5):** Confirmed `remove_by_labels()` is safe (already has guard). Confirmed `_multi_samples()` is safe (only called when `_is_parent()`). Suggested: remove test docstring, add parallel test for `remove()` on label-less metric. Applied.
- **Logic trace (manual, Gemini unavailable):** Found State C gap -- child metrics also crash on `remove()`/`clear()`. Pre-existing bug, out of scope for this PR.

### Files changed

- `prometheus_client/metrics.py` -- 2-line guard added to `clear()`
- `tests/test_core.py` -- 2 new tests (`test_clear_no_labels_raises`, `test_remove_no_labels_raises`)

---

# Triage Graph: FyroxEngine/Fyrox

## Scan (2026-05-09)

User: kimjune01. 9.3K stars, Rust game engine. 61 open issues, 3 open PRs.
Maintainer: mrDIMAS (MEMBER). Active -- committed b17c5f5 today. Merges contributor PRs regularly (CopeFiend, AghastyGD, Ughuuu, zuiyu1998).

### Your items

| # | Type | Score | Signal | Title | Status |
|---|------|-------|--------|-------|--------|
| 917 | PR | 5 | Fixes maintainer-acked UB #877 | Fix transmute_slice UB: alignment, divisibility, ZST guards | OPEN |
| 918 | PR | 5 | Fixes maintainer-acked UB #827 | Fix read_pixels_of_type UB: bytemuck::cast_slice | OPEN |

### Good-first-issue triage (7 issues)

| # | Score | Type | Title | Competing? | Verdict |
|---|-------|------|-------|------------|---------|
| 877 | 5 | Bug (UB) | transmute_slice misaligned pointer | No | PR#917 SUBMITTED |
| 827 | 5 | Bug (UB) | read_pixels_of_type mem::forget UB | No | PR#918 SUBMITTED |
| 826 | 1 | Feature | Scene tab context menu | PR#879 exists (majiayu000) | SKIP -- competing PR |
| 721 | 1 | Feature | wgpu graphics server | Claimant exploring (Muktarsadiq) | SKIP -- massive scope |
| 712 | 1 | Feature | Native multi-window support | Claimant from Jan 2025 (LuckyPigeon) | SKIP -- massive scope |
| 703 | 2 | Feature | Disable HDR rendering | No | BACKLOG -- moderate scope, no maintainer urgency |
| 588 | 2 | Feature | ImageDecorator widget | No | BACKLOG -- moderate scope, no maintainer urgency |
| 585 | 1 | Feature | Widget icons in World Viewer | No | SKIP -- needs icon sourcing |
| 462 | 1 | Feature | Visualize surfaceless nodes | No | SKIP -- wireframe/sprite work |

### Non-labeled bugs (no "good first issue" label)

| # | Score | Signal | Title | Status |
|---|-------|--------|-------|--------|
| 913 | 2 | NixOS packager request | Missing Cargo.lock | NO MAINTAINER RESPONSE -- wait |
| 880 | 2 | User request | Element buffers for non-triangle topologies | NO MAINTAINER RESPONSE -- feature |
| 890 | 1 | Bug report | Hotkeys don't work on macOS | NO MAINTAINER RESPONSE |

### Review culture

- **Merge velocity:** ~2-4 PRs/month from external contributors. mrDIMAS also commits directly.
- **Gate:** mrDIMAS reviews everything. CI runs on PRs.
- **Bug fixes merge:** Yes. #912 (symlink fix), #909 (nix flakes), #914 (font size const) all merged recently.
- **Features:** Slower. #826 has a PR (#879) from Dec 2025, still open. Large feature PRs stall.
- **Pattern:** Small, focused bug fixes with clear UB/correctness justification = best merge probability.

### Investigation results

#### PR#917: transmute_slice alignment UB (issue #877)

**Round 1 (codex):** Alignment assertion alone is insufficient. Missing divisibility check, ZST guard, and Pod bounds.
**Fix strengthened:** Added all three. `Pod` bounds on public API in fyrox-core; divisibility + ZST assertions in both fyrox-core and fyrox-texture.
**Round 2 (codex):** fyrox-texture's private `transmute_slice<T>` still lacks `Pod` bound on `T`. Acceptable: private function, only called with concrete pixel types that are byte-aligned.
**Verdict:** Ship. Two rounds, converged. No remaining UB.

#### PR#918: read_pixels_of_type UB (issue #827)

**Round 1 (gemini):** ManuallyDrop fixes the immediate UB but `Vec::from_raw_parts` still violates alloc layout invariants (alignment mismatch between `Vec<u8>` and `Vec<T>`).
**Fix rewritten:** Replaced entire unsafe block with `bytemuck::cast_slice::<u8, T>(&bytes).to_vec()`. Safe, correctly-aligned, no UB.
**Round 2 (codex):** `cast_slice` can panic on alignment (Vec<u8> not guaranteed aligned for T). This is a panic, not UB -- strictly better. GPU-allocated pixel buffers are typically aligned in practice.
**Verdict:** Ship. Two rounds, converged. Panic-on-misalignment is acceptable for this API.

## Cross-references

- **UB cluster:** #877 (transmute_slice) and #827 (read_pixels_of_type) are independent UB bugs in different crates (fyrox-core vs fyrox-graphics). No shared root cause.
- **bytemuck usage:** Both fixes leverage the existing `bytemuck` dependency. The codebase already uses `Pod` bounds extensively (e.g., `array_as_u8_slice`, `transmute_vec_as_bytes`).

## Recommended next actions

1. **Monitor PR#917 and PR#918** for maintainer review.
2. **After merge:** Consider follow-up PRs for #703 (disable HDR) or #588 (ImageDecorator) -- moderate scope features with no competing PRs.
3. **#913 (Cargo.lock):** Wait for maintainer response before acting. Policy decision.

---

# Triage Graph: apache/opendal

## Scan (2026-05-09)

User: kimjune01. 5.1K stars, Rust data access layer (S3/GCS/Azure/etc unified API). 21 good-first-issues, 21 help-wanted, 16 bugs.
Fork: https://github.com/kimjune01/opendal
**Org status:** apache org-blocked. Branches pushed to fork. Cannot open PRs until unblocked.

### Your items

| # | Type | Branch | Title | Issue | Status |
|---|------|--------|-------|-------|--------|
| - | feat | feat/azdls-user-metadata | Add user_metadata support to azdls | #4842 | READY (pushed) |
| - | feat | feat/buffer-split | Add split_to/split_off to Buffer | #4593 | READY (pushed) |

### Review culture

- **Lead maintainer:** Xuanwo (responsive, merges within days)
- **Active contributors:** TennyZhuang, suyanhanx, dentiny, tisonkun
- **Merge velocity:** 5-10 PRs/week. Bug fixes and mechanical features merge fastest.
- **Gate:** CI must pass. Per-service behavior tests with cloud credentials (Azurite for Azure, fake-gcs for GCS).
- **Pattern:** Tracking issues with checkbox task lists. Each checkbox = one PR. Feature work follows existing service patterns exactly.
- **AI-friendly:** Has "good first vibe" label for code-agent-suitable tasks. #6829 (crate extraction) has explicit LLM prompts in the issue.

### Candidates scored

| Rank | Issue | Task | Score | Status | Competing PR |
|------|-------|------|-------|--------|-------------|
| 1 | #4842 | azdls user_metadata | 9/10 | IMPLEMENTED | None |
| 2 | #4593 | Buffer split_to/split_off | 9/10 | IMPLEMENTED | Stale claim (2024-05, 2024-12) |
| 3 | #5693 | seafile write-returns-metadata | 7/10 | Backlog | None |
| 4 | #5693 | upyun write-returns-metadata | 7/10 | Backlog | None |
| 5 | #5693 | azfile write-returns-metadata | 7/10 | Backlog | None |
| 6 | #2611 | azblob object versioning | 6/10 | Backlog | None |
| 7 | #5486 | cos conditional reader if_match | 5/10 | Backlog | None |
| 8 | #4842 | upyun user_metadata | 5/10 | Backlog | #7068 (competing) |
| 9 | #2611 | gcs object versioning | 5/10 | Backlog | #5548 (competing) |
| 10 | #4976 | s3 assume role duration-seconds | 4/10 | Backlog | Needs reqsign change |

### Gate results

#### Codex (GPT-5.5) on azdls user_metadata

- **Encoding/decoding correct.** Standard base64, split_once('=') handles padding.
- **Removing action=getStatus necessary** per Azure docs -- getStatus only returns system properties.
- **Missing:** Key validation for chars invalid in ADLS property names (commas, equals).
- **Missing:** Unit tests. **FIXED** -- added 10 tests, all pass.
- **Scope:** Write + stat only (matching other services). Update/clear via action=setProperties not in scope.

#### Gemini 3.1 Pro on Buffer split_to/split_off

- **Logically correct.** Both methods compose slice/advance/truncate properly.
- **Edge cases handled:** split at 0, split at len, empty buffer all correct.
- **Pre-existing concern:** Arc<[Bytes]> keeps dropped chunks alive. Not introduced by this change -- inherent to Buffer's shared-ownership design. Noted but not actionable here.
- **Fuzz tests adequate.** 100 random iterations per test, covers both contiguous and non-contiguous paths.

### Cross-references

- **user_metadata cluster:** #4842 tracks all services. azblob, oss, gcs, cos, obs, swift, webdav already done. azdls, upyun remaining (upyun has competing PR #7068).
- **write-returns-metadata cluster:** #5693 tracks all services. ~15 unchecked. Pattern clear from completed examples (azblob #5958, gcs #5933).
- **versioning cluster:** #2611. s3/cos/oss done. azblob/b2/gcs/gdrive/onedrive/obs remaining. GCS has competing PR #5548.
- **conditional reader cluster:** #5486. cos and swift already implemented (verified in code). Checklist stale.

### Bugs assessed (not pursued)

| # | Title | Reason |
|---|-------|--------|
| #7491 | sftp docs incorrect key | Already has PR #7492 |
| #6577 | trailing whitespace in filenames | Needs RFC per Xuanwo |
| #5858 | behavior tests huge files | Needs design rethink per Xuanwo |
| #7459 | Python ADLS SP credentials | Complex auth chain, needs repro |
| #5330 | Python multiprocess hang | No repro available |

### Recommended next actions

1. **Wait for apache org unblock**, then open PRs for both branches.
2. **Next implementations** (when org access restored):
   - seafile write-returns-metadata (#5693) -- parse JSON upload response
   - azblob object versioning (#2611) -- already has version parsing in stat, needs list+read
3. **Monitor** competing PRs: #5548 (GCS versioning), #7068 (upyun user_metadata).

---

# Triage Graph: databendlabs/databend

## Scan (2026-05-09)

User: kimjune01. 9.3K stars, Rust cloud data warehouse (Snowflake-compatible). 16 good-first-issues, 552 open issues.
Fork: https://github.com/kimjune01/databend

### Your items

| # | Type | Score | Signal | Title | Status |
|---|------|-------|--------|-------|--------|
| 19830 | PR | 5 | Implements unchecked items from #16524 | feat: TH/th ordinal + V shift patterns in to_char | OPEN |

### Review culture

- **Core team:** b41sh, drmingdrmer, zhang2014, sundy-li, forsaken628, TCeason, bohutang, everpcpc, KKould
- **Merge velocity:** 5-10 PRs/day from core team. External contributor PRs much slower.
- **Gate:** CI must pass. Core team reviews. forsaken628 owns the to_char tracking issue (#16524).
- **Bug fixes merge:** Core team lands bug fixes daily. External PRs need careful scope matching.
- **AI-friendly flood risk:** HIGH. Many good-first-issues attract multiple claimants. Check comments before claiming.

### Good-first-issue triage (16 issues)

| # | Score | Type | Title | Competing? | Verdict |
|---|-------|------|-------|------------|---------|
| 16524 | 5 | Tracking | postgres-compatible to_char (TH, V, decimal, locale) | Active (forsaken628 owns) | PR#19830 SUBMITTED (TH+V) |
| 19139 | 1 | Feature | ISO8601 style durations | Assigned to tharunn0 (Mar 2026) | SKIP -- claimed |
| 19435 | 1 | Feature | Date/Timestamp Construction | Open PR #19508 (tharunn0) | SKIP -- competing PR |
| 17660 | 1 | Feature | Optimize explain | Open PR #18362 (ffengyu) | SKIP -- competing PR |
| 15469 | 3 | Feature | Dynamic log level changes per query | Abandoned (Jun 2024) | BACKLOG -- needs deep query infra knowledge |
| 15269 | 2 | Feature | Spilled storage size in query_log | No competing, maintainer discussed | BACKLOG -- needs spill subsystem understanding |
| 12201 | 3 | Refactor | Use native async fn in trait | Abandoned (Aug 2023) | BACKLOG -- mechanical but massive scope |
| 10497 | 1 | Feature | list() with ORDER BY / DISTINCT | Partially done (PR#10708 merged basic) | SKIP -- remaining work unclear |
| 9874 | 1 | Refactor | Try using build-info | No | SKIP -- "needs investigation", risky |
| 9647 | 1 | Feature | sqllogictest type checker | Closed PR#11564 (2023) | SKIP -- stale, unclear scope |
| 8625 | 1 | Perf | xor filter for IN | Abandoned (Jul 2023) | SKIP -- deep storage internals |
| 17460 | 1 | Feature | Sample Jupyter notebook | No | SKIP -- non-code, low impact |
| 19101 | 1 | Feature | HybridBitmap deser optimization | Partially merged (#19149) | SKIP -- remaining work unclear |
| 7951 | 0 | Bug | fuse_snapshot timestamp wrong | Stale (2022) | SKIP -- stale |
| 7251 | 0 | Feature | DDL metrics | Stale (2022) | SKIP -- stale |
| 5039 | 0 | Test | Valgrind stateless test | Open PR #19800 (cathay4t) | SKIP -- competing PR |

### Candidates for next PR (when current merges)

| Rank | Issue | Task | Score | Reason |
|------|-------|------|-------|--------|
| 1 | #16524 | decimal32/decimal64 in to_char | 4 | Same tracking issue, same file, proven path |
| 2 | #16524 | Reuse parsed FmtCacheEntry (caching) | 3 | Performance improvement, same tracking issue |
| 3 | #15469 | Dynamic log level per query | 2 | Abandoned, maintainer asked for PR, deep scope |

### Investigation results

#### PR#19830: TH/th ordinal + V shift patterns (issue #16524)

**Round 1 (implementation):** Implemented TH/th ordinal suffix with PostgreSQL teen-number rules, and V shift-digits pattern with integer+float support. Tests pass.

**Round 2 (codex + gemini review):**
- **Codex (GPT-5.5):** Found TH as post-processing breaks trailing literals/signs. Found Tk0 missing Multi check. Found float V .round() wrong for PostgreSQL ties-to-even. Found potential i128 overflow in integer V.
- **Gemini 3.1 Pro:** Confirmed V trace correctness for "99V999" with value 12. Confirmed TH trace for "9th" with value 1. Found same Tk0 bug and .round() issue. Found TH trailing-digit extraction brittle with PR/MI suffixes.

**All issues fixed in Round 3:**
- Moved TH emission from post-processing to inline at token position
- Fixed Tk0 not checking NumFlag::Multi
- Changed .round() to .round_ties_even()
- Added checked arithmetic for integer V overflow
- Added tests for TH+trailing literal and TH+MI

**Verdict:** Converged after 3 rounds. No remaining known bugs. Clippy clean, fmt clean.

### Cross-references

- **to_char cluster:** #16524 is the tracking issue. RN (Roman) merged in #19501. S/L/D/G merged in #16569. TH/V now in PR#19830. Remaining: decimal32/decimal64, FmtCacheEntry reuse, locale, more tests, docs.
- **forsaken628:** Active collaborator who owns #16524. Merged two PRs (RN + S/L/D/G). Will review our PR.

### Recommended next actions

1. **Monitor PR#19830** for forsaken628/b41sh review.
2. **After merge:** Implement decimal32/decimal64 support for to_char (#16524 unchecked item).
3. **After 2+ merges:** Consider #15469 (dynamic log level) or #12201 (async fn in trait refactor).

---

## Drip queue: databendlabs/databend

| Position | Branch | PR | Issue | Status |
|----------|--------|-----|-------|--------|
| 1 | feat/to-char-th-ordinal | #19830 | #16524 | OPEN |
| 2 | (next: decimal to_char) | - | #16524 | QUEUED (implement after #1 merges) |
