# Union-Find Compaction: Roadmap

PR: [#24736](https://github.com/google-gemini/gemini-cli/pull/24736)
Issue: [#22877](https://github.com/google-gemini/gemini-cli/issues/22877)
Design: [union-find-compaction](https://www.june.kim/union-find-compaction)

In this document:
- [Progress](#progress)
- [Vision](#vision)
- [Prework](#prework)
- [Current state](#current-state)
- [Eval criteria](#eval-criteria)
- [Rollout phases](#rollout-phases)
- [Risks, failure modes, and mitigations](#risks-failure-modes-and-mitigations)
- [Eviction policy](#eviction-policy)
- [Security and context hygiene](#security-and-context-hygiene)
- [Open items](#open-items)
- [What I can contribute next](#what-i-can-contribute-next)

## Progress

| Milestone | Status | Ref |
|-----------|--------|-----|
| Core implementation (Forest, ContextWindow, TF-IDF embedder, async summarizer) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Integration in `chatCompressionService.ts` (flat/union-find dispatch) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Experiment flag gating (`COMPRESSION_STRATEGY`, ID 45768880) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Unit/integration tests (52 contextWindow, 32 compression service) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| LRU eviction with tombstones | Not started | — |
| Compression evals (clustering quality, fact retention, tombstone reactivation) | Not started | — |
| User-facing settings (`compression.strategy` in `.gemini/settings.json`) | Not started | — |
| Session persistence (`union-find.json` per directory) | Not started | — |

---

## Vision

Flat compaction is lossy at the wrong granularity and runs at the wrong time. It compresses the entire history into one summary, so facts, decisions, and constraints vanish unpredictably. It stalls the conversation while reprocessing. And when the session ends, everything is gone.

Union-find compaction addresses context rot: the progressive degradation of model coherence as flat compaction discards facts the model still needs. Episodes degrade gracefully (full detail → summary → tombstone → gone), and at every stage the model retains enough to stay useful.

Union-find compaction makes three bets. **Topical lossiness over chunkwise lossiness:** messages cluster into episodes ("the part where we debugged the race condition"), and when something is forgotten, it's a complete topic. The user can reason about what's gone. **Continuous background compaction over foreground surprise:** episodes summarize incrementally as messages graduate out of the hot window. No foreground stall, no sudden loss of context mid-conversation. **Message-wise provenance plus summaries over summaries only:** source messages remain addressable through parent pointers. `expand(rootId)` recovers the original messages behind any summary. Flat compaction replaces the source; once summarized, the original is gone.

| | Flat | Union-find |
|---|---|---|
| Compression granularity | Entire history → one summary | Per-episode summaries |
| When it runs | Foreground stall | Continuous background graduation |
| What's lost | Unpredictable — arbitrary facts from anywhere | Whole topics, oldest first |
| Provenance | Source replaced by summary | Source messages addressable via `expand()` |
| After session ends | Gone | Persisted in `union-find.json` |

The forest persists in a `union-find.json` file tied to the directory. A new session reads the forest and picks up where the last one left off. Multiple sessions in the same directory see the same episode history.

```
┌─────────────────────────────────────────────┐
│  Persistent memory (GEMINI.md, memory files) │  ← durable constraints, project identity
├─────────────────────────────────────────────┤
│  Cold clusters (union-find forest, ≤10)      │  ← episode summaries, LRU eviction
├─────────────────────────────────────────────┤
│  Hot window (~27 most recent messages)       │  ← live working state, fully expanded
└─────────────────────────────────────────────┘
```

Union-find owns the middle layer. Simple LRU eviction on clusters is sufficient because the layers above and below handle the hard cases.

---

## Prework

The union-find compaction architecture was prototyped, experimentally validated, and ported to gemini-cli across three repos.

**[Prototype and standalone experiment](https://june.kim/union-find-compaction)** ([repo](https://github.com/kimjune01/union-find-compaction)) — forest data structure, TF-IDF embedder, cluster summarizer. 7 trials on a synthetic 200-message conversation with 40 verifiable facts. Advantage comes from granularity: flat compresses 200 messages into one block, union-find operates on clusters of 5–20, preserving footnote facts that disappear in single-pass compression.

| | Flat | Union-find |
|---|---|---|
| Recall at 50 messages | 90% | 90% |
| Recall at 200 messages | 72–82% | 88–92% |
| Production trial (Haiku→Sonnet) | 75% | 90% |

Directional but underpowered (n=40; one trial reached p=0.039).

**[Gemini-cli experiment](https://github.com/kimjune01/union-find-compaction-for-gemini-cli)** — preregistered, 12 real GitHub issue conversations (120 messages each), evaluated with Flash Lite. Experiment harness ready to rerun with different parameters.

| Metric | Result | Criterion |
|---|---|---|
| Token cost | 0.79x flat (21% cheaper) | ≤1.0x |
| Append latency (p95) | 0.33ms | <100ms |
| Recall | +8.3pp (30.2% vs 21.9%) | Directional, p=0.136 |
| Background `resolveDirty()` (p50) | 4.0s | Fits within LLM call wait |
| Conversations won | 8/12 | — |

Underpowered at 96 questions. Recommended follow-up: 24+ conversations with Gemini Pro as summarizer.

**Contribution history on gemini-cli** — [#2](https://github.com/kimjune01/gemini-cli-claude/pull/2), [#3](https://github.com/kimjune01/gemini-cli-claude/pull/3), [#4](https://github.com/kimjune01/gemini-cli-claude/pull/4), [#5](https://github.com/kimjune01/gemini-cli-claude/pull/5). Prior PRs on a fork.

---

## Current state

**Implemented.** ContextWindow + Forest (union-find with path compression), local TF-IDF embedder, async cluster summarizer. Integration in `chatCompressionService.ts` dispatches between `'flat'` and `'union-find'` strategies.

- Gated behind experiment flag `COMPRESSION_STRATEGY` (ID 45768880), default `'flat'`
- No user-facing CLI flag or settings entry
- No compression-specific evals (unit/integration tests only: 52 contextWindow, 32 compression service)
- Tuning parameters hardcoded:
  - `graduateAt=26` — hot window size. Keeps ~13 user-assistant turn pairs fully expanded. Chosen to be large enough for an active debugging loop but small enough that graduation starts before the context window fills.
  - `evictAt=30` — headroom between graduation and eviction so the summarizer can finish before the next eviction check.
  - `maxColdClusters=10` — starting heuristic. Provides headroom for sessions with several topic changes. Tune via eval data on real conversation distributions.
  - `mergeThreshold=0.15` — cosine similarity floor for clustering. Below this, messages start a new cluster. Initial value from the standalone experiment; needs validation against gemini-cli conversation patterns.

```
Flat (current):
  [all old messages] ──→ LLM summarize ──→ LLM verify ──→ single summary
  Blocking. Two LLM calls. Entire history reprocessed.

Union-find:
  append(msg)       <1ms    Embed locally, graduate to forest, merge by similarity
  render()          <0.1ms  Return cached cluster summaries + hot window verbatim
  resolveDirty()    ~4s     Async. Batch-summarize dirty clusters in background
```

---

## Eval criteria

### Clustering quality (primary)

Clusters are the unit of recall and the unit of forgetting. If they align with how a human would chunk the conversation, everything downstream works. If they don't, no eviction policy saves you.

Measure: precision and recall of cluster boundaries against human-annotated topic boundaries. Target gemini-cli's actual conversation patterns (tool calls, file reads, multi-turn debugging, topic interleaving).

### Summary and tombstone quality

- **Summary faithfulness.** Adapt the 40-fact protocol from the [standalone experiment](https://github.com/kimjune01/union-find-compaction): seed facts into clusters, score binary recall with a strict LLM judge. Minimum bar: match flat at low compression, beat it by ≥10pp at 200+ messages.
- **Tombstone reactivation.** Given a tombstone and codebase access, can the model answer follow-ups about the episode? Target: ≥80% reactivation rate.

### Latency

- **Graduation cost.** Time per `append()` + background `resolveDirty()`. Should be <100ms per graduation (TF-IDF is local; LLM call is fire-and-forget).
- **Compression stall.** Flat blocks the conversation during recompression. Union-find should show measurably lower p95 user-perceived latency during compression events.
- **Cold-start.** First compression with no pre-existing clusters. Measure time-to-first-render after initial graduation cascade.

### Token efficiency

Compressed-to-original token ratio at equivalent recall. Per-cluster summaries may use more tokens than a single flat summary, but the recall advantage should justify the budget.

### Provenance (qualitative)

`expand(rootId)` recovers source messages while a cluster is live. After eviction, source messages are gone and only the tombstone remains. Flat cannot recover sources at any stage. Provenance enables downstream features: audit trails, selective re-expansion, multiplayer context.

### Regression

All existing compression tests must pass unchanged. The flat path must remain functional as a fallback.

### Compatibility

Union-find must coexist with existing session features (`/chat save`, `/chat resume`, session checkpointing). The forest is additive derived state alongside the conversation history, not a replacement. On `/chat resume`, the forest can be rebuilt from the restored message list by replaying graduation. If a persisted forest exists and matches the session, skip rebuild and load directly. Verify during Phase 2 implementation that save/resume serialization covers all necessary state.

---

## Rollout phases

```
Phase 0          Phase 1            Phase 2              Phase 3        Phase 4
Experiment flag  Evals + LRU        Settings + persist   A/B at scale   Default
[current]        ──→                ──→                  ──→            ──→
```

### Phase 0: Experiment flag (current)

Union-find is available via `COMPRESSION_STRATEGY` experiment flag or local `GEMINI_EXP` override. No user-facing exposure.

**Exit criteria:** Review feedback addressed, CI green on the PR.

### Phase 1: Evals + LRU eviction

Two PRs, independent of each other:

**Compression evals.** Add compression-specific benchmarks to the existing `evals/` framework:
1. Synthetic conversation generator (parameterized: message count, fact density, tool-call ratio, topic interleaving)
2. Compression runner (flat vs union-find, same budget)
3. Clustering quality scorer (boundary alignment against annotated topic transitions)
4. Fact retention scorer (strict LLM judge, binary recall, no partial credit)
5. Tombstone reactivation scorer (can the model answer follow-ups from tombstone + codebase?)
6. Results table with McNemar's test on discordant pairs

Useful beyond union-find: any future compression change can be evaluated against these evals.

**LRU eviction with tombstones.** Replace closest-pair merge with cluster-level LRU. Evicted clusters compress to one-line tombstones in a session history section. Infrastructure (`removeDocument()`) already exists.

**Exit criteria:** Compression evals merged with baseline results for flat. LRU eviction merged and validated against the evals.

### Phase 2: User-facing opt-in + session persistence

**Settings.** Expose compression strategy in `.gemini/settings.json`:

```json
{
  "coreTools": {
    "compression": {
      "strategy": "union-find"
    }
  }
}
```

Power users opt in without experiment flags. Generates real-world usage data.

**Session persistence.** Serialize the forest to `.gemini/context/union-find.json` per directory. New sessions read the forest on startup. Parent pointers are integers; serialization is straightforward.

Persistence concerns:
- **Location.** `.gemini/context/` keeps it alongside other gemini-cli state. Should be excluded from version control (see open items on `.gitignore` approach).
- **Sensitive data.** Cluster summaries may contain file contents, error messages, or tool output. Same exposure as existing `.gemini/` state files. Summaries inherit the sanitization already applied at the `<context_clusters>` wrap site.
- **Concurrent sessions.** Read-on-startup, write-on-graduation. Last-writer-wins is acceptable for the single-user case; clusters are append-only and summaries are idempotent. A file lock (`flock`) prevents mid-write corruption.
- **Corruption recovery.** If the forest fails to deserialize, discard it and start fresh. Cold storage is ephemeral by design; losing it is equivalent to starting a new session. Log a warning so the user knows.
- **Schema migration.** Version field in the JSON header. If the version doesn't match, discard and rebuild rather than attempting migration. Early phases; stability over backwards compatibility.

**Exit criteria:** Settings schema updated and documented. Forest persists across session restarts.

### Phase 3: A/B at scale

Enable union-find for a percentage of users via the experiment flag infrastructure. Measure:

- Clustering quality and fact retention (via the eval harness)
- Compression latency (p50, p95, p99)
- User-reported issues (context loss, incoherent responses after compression)
- Token usage (cost impact)
- Session continuity: do users in multi-session workflows report better coherence?

**Exit criteria:** Union-find matches or beats flat on primary metrics (fact retention, clustering quality, user-reported coherence). Acceptable tradeoffs: up to 15% higher token usage if recall improves by ≥5pp absolute. Latency p95 must not regress by more than 10% vs flat baseline.

### Phase 4: Default strategy

Flip the default to `'union-find'`. Flat remains as a fallback via explicit setting. The existing fallback-on-summarization-failure path in `chatCompressionService.ts` (catches summarizer errors and falls back to flat) applies to union-find as well.

**Exit criteria:** Stable in production for ≥2 weeks with no regressions.

---

## Risks, failure modes, and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Poor cluster boundaries | Episodes split or merged at wrong points; summaries become incoherent; eviction drops half a thought | Primary eval metric. TF-IDF merge threshold (0.15) is the main tuning lever. Measure boundary alignment against human annotations. |
| Summary quality on small clusters (<3 messages) | Summaries may be worse than raw text | Singletons already serve raw content (no summary). Could raise minimum cluster size before summarizing. |
| Tombstone too lossy | Model can't reconstruct when user reopens a topic; "false restart" where agent repeats investigation | Tombstones must preserve retrieval cues: files, decisions, constraints, failure/success. Eval via reactivation test. |
| TF-IDF vocabulary growth over long sessions | Embedding drift: old vectors become stale as vocabulary expands | Cosine similarity handles mismatched dimensions (shorter vector gets zero-padded). Monitor centroid quality over 500+ message sessions. |
| Cold-start latency | First compression has no pre-existing clusters; graduation cascade processes many messages at once | TF-IDF embedding is local (<1ms per message). LLM calls are batched in `resolveDirty()`. Monitor p95 on first compression. |
| Durable constraints lost to eviction | User said "don't touch generated files"; instruction evicted; agent violates it | From the user's perspective this is context loss regardless of whose bug it is. Mitigation: at summarization time, extract constraint-shaped content ("never", "always", "don't") and surface it for promotion to persistent memory. Document the boundary between compaction and persistence. |
| Hardcoded tuning parameters | One-size-fits-all may not suit all conversation patterns | Phase 2 settings could expose tuning knobs. Start with defaults, tune based on eval results. |
| Prompt injection through cluster summaries | Summarized content could contain delimiter strings or adversarial instructions | `sanitizePromptString` escapes `<>` and backticks at the `<context_clusters>` wrap site. Persisted summaries inherit this sanitization. Untrusted repo content (e.g. user-controlled file names or error messages) passes through the same escaping path. |
| Operational failure mid-compaction | Process exits during graduation or summarization; forest left in inconsistent state | Graduation is atomic per message (append + union are in-memory operations). Summarization is async and idempotent — if interrupted, `resolveDirty()` re-summarizes on next run. Persistence writes are atomic (write-to-temp, rename). No partial state reaches disk. |

---

## Eviction policy

**LRU on clusters.** When the cluster count exceeds `maxColdClusters`, drop the cluster whose newest member is oldest. Evicted clusters compress to a one-line tombstone in the session history.

The current cap enforcement merges the two most similar clusters (`findClosestPair` + `union`), creating progressively larger mega-clusters. After enough merges, one cluster can contain 50+ messages summarized into a single paragraph. Summary quality degrades because the summarizer compresses increasingly diverse content. LRU avoids this: clusters stay small, summaries stay coherent.

In the gemini-cli experiment (12 conversations, 120 messages each), clusters followed a heavy-tailed distribution: 1–2 clusters per conversation contained the majority of messages, with the rest being short tangents of 3–8 messages. The dominant cluster is almost always the most recent (still in the hot window or freshly graduated) and is never the eviction candidate. The candidates are the small, old, self-contained tangents, which is what LRU selects. Whether this distribution holds across real user sessions is an open question for Phase 3 telemetry.

| | Closest-pair merge | LRU eviction |
|---|---|---|
| Information loss | None (merged) | Oldest cluster tombstoned |
| Cluster size | Unbounded growth | Bounded by graduation rate |
| Summary quality | Degrades as clusters grow | Stable (small clusters only) |
| Complexity | O(k²) per enforcement | O(k) per enforcement |
| Recoverability | `expand()` on mega-cluster | Tombstone + codebase reconstruction |

`removeDocument()` already exists in the TF-IDF embedder for clean teardown on eviction.

---

## Security and context hygiene

Union-find compaction plugs into gemini-cli's existing multi-layer security infrastructure rather than adding new mechanisms.

| Concern | Existing infrastructure | Union-find integration |
|---------|------------------------|----------------------|
| Prompt injection | `sanitizePromptString()` escapes code fences, HTML, control chars | Already applied at `<context_clusters>` wrap site and in `clusterSummarizer.ts` before summarization |
| Sensitive data in context | `agent-sanitization-utils.ts` redacts PEM, JWT, tokens, credentials; `environmentSanitization.ts` filters env vars | Tool output entering clusters passes through the same redaction path |
| History integrity | `historyHardening.ts` enforces role alternation, tool call/response pairing | Forest operates on post-hardened history; no new message types introduced |
| Content wrapping | `snippets.ts` wraps memory in `<loaded_context>`, hooks in `<hook_context>` with injection disclaimers | Cluster summaries wrapped in `<context_clusters>` (same pattern) |
| Persistence | `storage.ts` central `.gemini` path map; `chatRecordingService.ts` sanitizes session IDs; `fileKeychain.ts` uses `0700`/`0600` for credentials | Forest persists to `.gemini/context/union-find.json`, same directory conventions |
| Tool output filtering | `toolOutputMaskingService.ts` offloads large outputs to disk; `toolDistillationService.ts` summarizes | Tool outputs are already masked/distilled before they enter the hot window and graduate to clusters |

**Known gaps (see open items):**
- Non-credential state files (chat JSONL, tool outputs, and now union-find.json) use default file permissions, not restrictive modes. Same gap as existing persistence.
- Sanitization is at prompt-render time. Persisted summaries should sanitize-on-write so the file at rest is clean.

---

## Open items

Issues recognized but deferred to implementation PRs:

- **Settings schema conventions.** The `coreTools.compression.strategy` path is a placeholder. Needs alignment with gemini-cli's actual settings schema before the Phase 2 PR.
- **TF-IDF justification.** Why local TF-IDF over learned embeddings? Short answer: zero latency, no API dependency, good enough for topic-level clustering. Deserves a dedicated section or design doc with failure case analysis.
- **Sanitization at rest vs render time.** Current sanitization happens at prompt render (`<context_clusters>` wrap site). Persisted summaries need sanitize-on-write, not just sanitize-on-read.
- **`.gitignore` mutation.** Auto-adding `.gemini/context/` to `.gitignore` assumes git, assumes the user wants mutation. Needs a more cautious plan (check, warn, suggest rather than auto-edit).
- **Cross-platform file locking.** `flock` is Unix-only. Node-compatible atomic write story needed for Windows.
- **Observability.** Instrumentation (cluster count, graduation rate, eviction count, summarization latency, dirty cluster backlog, tombstone hit rate) needed before Phase 3 ramp-up, not before merge.
- **Rollback plan.** If A/B shows regressions: disable experiment flag restores flat immediately, persisted forest is ignored (left on disk, not deleted).
- **Experiment failure cleanup.** If union-find is rejected, what happens to `.gemini/context/union-find.json`? Probably: leave it, add a cleanup command, document manual removal.
- **Durable constraint promotion flow.** "Surface for promotion to persistent memory" is vague. Needs a concrete UX: who sees the prompt, where, when.
- **Session isolation expectations.** Multiple sessions sharing one forest may surprise users who expect terminal sessions to be isolated. Needs product decision.
- **Insertion-order confound.** Union-find emits cluster summaries at a different position than flat's single summary. At p=0.136, the recall difference could be explained by positional sensitivity rather than clustering quality. Future benchmarks should hold insertion index and compaction lifecycle constant to isolate the clustering variable. ([discussion context](https://github.com/google-gemini/gemini-cli/discussions/26488))

---

## What I can contribute next

Ordered by value to the project:

1. **Compression eval harness** (Phase 1) — standalone PR, useful for any compression work. Covers clustering quality, fact retention, and tombstone reactivation.
2. **LRU eviction with tombstones** — replace closest-pair merge with cluster-level LRU. Evicted clusters compress to one-line tombstones in a session history section. Infrastructure (`removeDocument()`) already exists.
3. **Settings schema for strategy selection** (Phase 2) — small, well-scoped
4. **Tuning parameter documentation** — explain the constants and their rationale, especially the hot window size (graduateAt), cluster cap (maxColdClusters), and merge threshold
5. **Session persistence** — serialize the forest across session restarts (parent pointers are just integers)

Open to prioritization input from maintainers.
