# Union-Find Compaction: Roadmap

Roadmap for union-find context compaction in gemini-cli. Covers current state, evaluation criteria, rollout phases, and risks.

PR: [#24736](https://github.com/google-gemini/gemini-cli/pull/24736)
Design: [union-find-compaction](https://www.june.kim/union-find-compaction)

## Progress

| Milestone | Status | Ref |
|-----------|--------|-----|
| Core implementation (Forest, ContextWindow, TF-IDF embedder, async summarizer) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Integration in `chatCompressionService.ts` (flat/union-find dispatch) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Experiment flag gating (`COMPRESSION_STRATEGY`, ID 45768880) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| Unit/integration tests (52 contextWindow, 32 compression service) | Done | [#24736](https://github.com/google-gemini/gemini-cli/pull/24736) |
| LRU eviction with tombstones | Not started | — |
| Compression eval harness (clustering quality, fact retention, tombstone reactivation) | Not started | — |
| User-facing settings (`compression.strategy` in `.gemini/settings.json`) | Not started | — |
| Session persistence (`union-find.md` per directory) | Not started | — |

---

## Vision

Flat compaction has two UX problems. First, it's lossy at the wrong granularity: it compresses the entire history into one summary, so the loss is unpredictable — facts, decisions, and constraints vanish and the user can't anticipate which ones. Second, it's a foreground surprise: the model stalls, reprocesses everything, and comes back different. And when the session ends, everything is gone.

Union-find compaction makes three bets. **Topical lossiness over chunkwise lossiness:** messages cluster into episodes ("the part where we debugged the race condition"), and when something is forgotten, it's a complete topic — not an arbitrary slice of history. The user can reason about what's gone. **Continuous background compaction over foreground surprise:** episodes summarize incrementally as messages graduate out of the hot window. No stall, no reprocessing, no moment where the model suddenly forgets. **Message-wise provenance plus summaries over summaries only:** source messages remain addressable through parent pointers. `expand(rootId)` recovers the original messages behind any summary. Flat compaction replaces the source — once summarized, the original is gone.

| | Flat | Union-find |
|---|---|---|
| Compression granularity | Entire history → one summary | Per-episode summaries |
| When it runs | Foreground stall | Continuous background graduation |
| What's lost | Unpredictable — arbitrary facts from anywhere | Whole topics, oldest first |
| Provenance | Source replaced by summary | Source messages addressable via `expand()` |
| After session ends | Gone | Persisted in `union-find.md` |

Session continuity is the long-term goal. The forest persists in a `union-find.md` file tied to the directory. A new session reads the forest and picks up where the last one left off. Multiple sessions in the same directory read from the same forest — open two terminals, start two conversations, both see the same episode history.

This is the continuity layer between the hot window (live working state, current session only) and persistent memory (GEMINI.md, memory files, durable constraints that outlive any session).

**Implementation detail:** simple LRU eviction on clusters is sufficient because the layers above (hot window) and below (persistent memory) already handle the hard cases.

---

## Current state

**Implemented.** ContextWindow + Forest (union-find with path compression), local TF-IDF embedder, async cluster summarizer. Integration in `chatCompressionService.ts` dispatches between `'flat'` and `'union-find'` strategies.

- Gated behind experiment flag `COMPRESSION_STRATEGY` (ID 45768880), default `'flat'`
- No user-facing CLI flag or settings entry
- No compression-specific evals (unit/integration tests only: 52 contextWindow, 32 compression service)
- Tuning parameters hardcoded: graduateAt=26, evictAt=30, maxColdClusters=10, mergeThreshold=0.15

**What flat does today.** Single-pass LLM summarization with verification probe. Reprocesses entire history on each compression. Summary replaces source — no provenance, no expandability.

**What union-find adds.** Per-cluster summarization via incremental graduation. Each `union()` is near-O(1). Source messages remain addressable through parent pointers. No batch stall. Summaries are pre-merged at write time; context stays bounded without reprocessing.

---

## Eval criteria

How to measure whether union-find should replace flat as the default.

### Clustering quality (primary)

The union-find forest produces clusters that serve as the unit of recall and the unit of forgetting. If the clusters are good — coherent episodes that match how a human would chunk the conversation — everything downstream works: summaries are coherent, eviction is unsurprising, tombstones are useful. If the clusters are bad, no eviction policy or summary prompt saves you.

Measure episode boundary quality: given a conversation with annotated topic boundaries, how well do the union-find clusters align? Compute precision and recall of cluster boundaries against human-annotated boundaries. Target: gemini-cli's actual conversation patterns (tool calls, file reads, multi-turn debugging, topic interleaving) rather than synthetic chat.

### Summary and tombstone quality

Each cold cluster carries a summary. When evicted, it compresses further to a one-line tombstone. Measure both:

- **Summary faithfulness.** Does the cluster summary preserve the key facts, decisions, and constraints from the source messages? Adapt the 40-fact protocol from the [standalone experiment](https://github.com/kimjune01/union-find-compaction): seed facts into clusters, score binary recall from summaries with a strict LLM judge.
- **Tombstone reactivation.** Given a tombstone and access to the codebase, can the model reconstruct enough to answer follow-up questions about the episode? This tests whether tombstones preserve the right retrieval cues (files, function names, decisions, constraints) rather than just the outcome.

Minimum bar: union-find summaries match flat's recall at low compression; beat it by ≥10pp at 200+ messages. Tombstones should support reactivation for ≥80% of follow-up queries about closed episodes.

### Latency

- **Graduation cost.** Time per `append()` + background `resolveDirty()`. Should be <100ms per graduation (TF-IDF is local; LLM call is fire-and-forget).
- **Compression stall.** Flat blocks the conversation during recompression. Union-find should show measurably lower p95 user-perceived latency during compression events.
- **Cold-start.** First compression with no pre-existing clusters. Measure time-to-first-render after initial graduation cascade.

### Token efficiency

Compressed-to-original token ratio at equivalent recall. Union-find's per-cluster summaries may use more tokens than flat's single summary for the same information — but the recall advantage should justify the budget.

### Provenance (qualitative)

`expand(rootId)` recovers source messages. Flat cannot. This is a capability difference, not a metric — but it enables downstream features (audit trails, selective re-expansion, multiplayer context).

### Regression

All existing compression tests must pass unchanged. The flat path must remain functional as a fallback.

---

## Rollout phases

### Phase 0: Experiment flag (current)

Status quo. Union-find is available via `COMPRESSION_STRATEGY` experiment flag or local `GEMINI_EXP` override. No user-facing exposure.

**Exit criteria:** Review feedback addressed, CI green on the PR.

### Phase 1: Compression eval harness

Add an automated compression benchmark to `evals/`. Structure:

1. Synthetic conversation generator (parameterized: message count, fact density, tool-call ratio, topic interleaving)
2. Compression runner (flat vs union-find, same budget)
3. Clustering quality scorer (boundary alignment against annotated topic transitions)
4. Fact retention scorer (strict LLM judge, binary recall, no partial credit)
5. Tombstone reactivation scorer (can the model answer follow-ups from tombstone + codebase?)
6. Results table with McNemar's test on discordant pairs

This is the PR I'd submit next. It gives maintainers a repeatable way to evaluate compression changes — useful beyond union-find.

**Exit criteria:** Eval harness merged, baseline results for flat strategy established.

### Phase 2: User-facing opt-in

Expose compression strategy in user settings (`.gemini/settings.json`). Something like:

```json
{
  "coreTools": {
    "compression": {
      "strategy": "union-find"
    }
  }
}
```

Allows power users to opt in without experiment flags. Generates real-world usage data.

**Exit criteria:** Settings schema updated, documented in user-facing docs.

### Phase 3: A/B at scale

Enable union-find for a percentage of users via the experiment flag infrastructure. Measure:

- Fact retention (via the eval harness, run on anonymized conversation logs)
- Compression latency (p50, p95, p99)
- User-reported issues (context loss, incoherent responses after compression)
- Token usage (cost impact)

**Exit criteria:** Union-find matches or beats flat on all metrics across the A/B population.

### Phase 4: Default strategy

Flip the default from `'flat'` to `'union-find'`. Flat remains available as a fallback (explicit setting or automatic on summarization failure — already implemented).

**Exit criteria:** Stable in production for ≥2 weeks with no regressions.

---

## Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Poor cluster boundaries | Episodes split or merged at wrong points; summaries become incoherent; eviction drops half a thought | Primary eval metric. TF-IDF merge threshold (0.15) is the main tuning lever. Measure boundary alignment against human annotations. |
| Summary quality on small clusters (<3 messages) | Summaries may be worse than raw text | Singletons already serve raw content (no summary). Could raise minimum cluster size before summarizing. |
| Tombstone too lossy | Model can't reconstruct when user reopens a topic; "false restart" where agent repeats investigation | Tombstones must preserve retrieval cues: files, decisions, constraints, failure/success. Eval via reactivation test. |
| TF-IDF vocabulary growth over long sessions | Embedding drift: old vectors become stale as vocabulary expands | Cosine similarity handles mismatched dimensions (shorter vector gets zero-padded). Monitor centroid quality over 500+ message sessions. |
| Cold-start latency | First compression has no pre-existing clusters; graduation cascade processes many messages at once | TF-IDF embedding is local (<1ms per message). LLM calls are batched in `resolveDirty()`. Monitor p95 on first compression. |
| Durable constraints lost to eviction | User said "don't touch generated files"; instruction evicted; agent violates it | Not a compaction bug — it's a persistence bug. Durable constraints belong in GEMINI.md or memory files, not cold clusters. Document this boundary clearly. |
| Hardcoded tuning parameters | One-size-fits-all may not suit all conversation patterns | Phase 2 settings could expose tuning knobs. Start with defaults, tune based on eval results. |
| Prompt injection through cluster summaries | Summarized content could contain delimiter strings | Already mitigated: `sanitizePromptString` escapes `<>` and backticks at the `<context_clusters>` wrap site. |

---

## Eviction policy

**LRU on clusters, not messages.** When the cluster count exceeds `maxColdClusters`, drop the cluster whose newest member is oldest.

This is the right level of resolution. The union-find forest operates on cold storage only — the hot window (~27 most recent messages) remains fully expanded and untouched by compaction. By the time a message graduates into a cold cluster, the user has already moved past it. Cold clusters are past episodes, not live working state.

The current cap enforcement merges the two most similar clusters (`findClosestPair` + `union`). This preserves all information but creates progressively larger mega-clusters: after enough merges, one cluster can contain 50+ messages summarized into a single paragraph. The summary degrades because the summarizer is asked to compress increasingly diverse content. LRU eviction avoids this entirely — clusters stay small, summaries stay coherent, and the unit of forgetting matches the unit of recall.

Humans don't remember conversations message-by-message. We remember episodes: "the part where we debugged the race condition," not turn 47. LRU on messages drops content at arbitrary boundaries, mid-thought. LRU on clusters drops a complete episode as a unit. The forgetting is coherent because the thing being forgotten is coherent. And the dropped episode doesn't vanish entirely — it compresses to a one-line tombstone in the session history, enough for the model to say "we resolved that earlier" rather than "I don't know what you're referring to." If the user reopens the topic, the tombstone provides retrieval cues for reconstructing details from the codebase.

We can also assume that sessions are dominated by one or two primary tasks, with the remaining clusters being short-lived tangents. The attention distribution is heavy-tailed: one main debugging arc or feature implementation gets most of the messages, a couple of side threads get moderate attention, and the rest are brief questions that resolved in a few turns. The main task is almost always the most recent — still in the hot window or freshly graduated — and is never the eviction candidate. The eviction candidates are the small, old, self-contained tangents, which is exactly what LRU selects. Sophisticated eviction scoring (activation functions, distinctiveness metrics, multi-dimensional composites) solves a tiebreaking problem that barely exists in practice. If the clusters are good, dumb eviction works. If the clusters are bad, no eviction policy saves you.

Durable information — user constraints ("don't touch generated files"), architectural decisions, project identity — does not belong in cold clusters at all. It belongs in persistent memory: GEMINI.md, memory files, or the todo/task system. The compaction system is not responsible for persistence; it is responsible for the ephemeral middle layer between "what you're doing right now" (hot window) and "what you always know" (filesystem). Expecting cold clusters to preserve durable constraints is a persistence bug, not an eviction bug.

| | Closest-pair merge | LRU eviction |
|---|---|---|
| Information loss | None (merged, not dropped) | Oldest cluster dropped (tombstoned) |
| Cluster size | Unbounded growth | Bounded by graduation rate |
| Summary quality | Degrades as clusters grow | Stable (small clusters only) |
| Complexity | O(k²) per enforcement | O(k) per enforcement |
| Recoverability | `expand()` still works on mega-cluster | Tombstone + codebase reconstruction |

The TF-IDF embedder already supports `removeDocument()` for clean teardown when clusters are evicted — the infrastructure is in place.

---

## What I can contribute next

Ordered by value to the project:

1. **Compression eval harness** (Phase 1) — standalone PR, useful for any compression work. Covers clustering quality, fact retention, and tombstone reactivation.
2. **LRU eviction with tombstones** — replace closest-pair merge with cluster-level LRU. Evicted clusters compress to one-line tombstones in a session history section. Infrastructure (`removeDocument()`) already exists.
3. **Settings schema for strategy selection** (Phase 2) — small, well-scoped
4. **Tuning parameter documentation** — explain the constants and their rationale, especially the hot window size (graduateAt), cluster cap (maxColdClusters), and merge threshold
5. **Session persistence** — serialize the forest across session restarts (parent pointers are just integers)

Open to prioritization input from maintainers.
