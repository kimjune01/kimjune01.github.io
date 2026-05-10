# Sweep Graph (2026-05-10)

## Score

| Metric | Count |
|--------|-------|
| Merges | 3 (bat#3734, mprocs#216, servo#44816) |
| Open PRs | 74 |
| Repos triaged | 94 |
| Repos evicted | 15 |
| Closures | 8 |

## Close to merge

| PR | Status | Blocker |
|----|--------|---------|
| godotengine/godot#119362 | APPROVED, all checks pass | Waiting maintainer click |
| EnzymeAD/Enzyme#2816 | APPROVED | Needs rebase (agent running) |
| tach-org/tach#931 | Maintainer "thanks!" | Waiting merge click |
| google-gemini/gemini-cli#24736 | Community LGTMs | Needs rebase + official review |

## Cross-repo findings

- **Astro dead imports:** withastro/astro#16634 (closed, Vite approach) -> withastro/compiler#1162 (open, compiler approach). Same bug, different layer.
- **Pallets org rejection:** click#3414, jinja#2166, quart#464 all closed by davidism within 21 seconds. Org-level maintainer surface confirmed. 30-day cooldown.
- **Prometheus cluster:** 5 repos (prometheus, client_golang, node_exporter, client_python, alertmanager). Shared CNCF governance. Org-gated to 1 open PR.
- **Grafana cluster:** 3 repos (grafana, pyroscope, loki). Same org gate.
- **astral-sh cluster:** 3 repos (ruff, uv, ty). Same maintainer team. Org-gated.
- **tracel-ai cluster:** 3 repos (burn, burn-onnx, cubecl). False ban alarm resolved. PR#4937 still open.
- **sharkdp cluster:** 2 repos (bat, fd). bat#3734 MERGED (first). fd#1994 open. Warm org.
- **charmbracelet cluster:** 2 repos (lipgloss, bubbletea). Shared maintainer meowgorithm.
- **pylint-dev cluster:** 2 repos (pylint, astroid). Same maintainers.
- **IBM cluster:** 3 repos (mcp-cli, mcp-context-forge, AssetOpsBench). Standing from 3 prior merges.
- **Apache cluster:** 4 repos (airflow, opendal, superset, datafusion-ballista). Org-gated.
- **Anti-AI policies:** uptime-kuma ("AI Slop" label), litestar (AI_POLICY.md), immich (CONTRIBUTING.md ban). All evicted.
- **Complexity predicts merge (H8):** All 3 merges were trivial fixes. No complex PR has merged yet.
- **Standing-first confirmed (H5):** mprocs denylist worked: domain-heavy #212 killed by gemini, trivial #185 merged.

## Evicted repos (15)

| Repo | Reason |
|------|--------|
| withastro/astro | dormant, no items |
| python/cpython | no actionable items |
| faster-cpython/ideas | proposal only |
| SoarGroup/Soar | solo maintainer ignores external |
| Aider-AI/aider | 10-50x merge ceiling |
| python-attrs/attrs | hostile AI policy |
| influxdata/telegraf | hard CLA ban on AI code |
| pallets/click | org-level batch rejection (cooldown 2026-06-09) |
| pallets/jinja | org-level batch rejection |
| pallets/quart | org-level batch rejection |
| google-gemini/gemini-cli-action | repo archived |
| louislam/uptime-kuma | anti-AI policy |
| litestar-org/litestar | auto-closes AI PRs |
| immich-app/immich | CONTRIBUTING.md bans LLM PRs |
| onecli/onecli | no mechanical bugs |

## Org gate status

| Org | Open PR | Queued behind |
|-----|---------|---------------|
| prometheus | client_python#1174, node_exporter#3652 | alertmanager |
| astral-sh | ruff#25066 | uv, ty |
| grafana | pyroscope#5139 | grafana, loki |
| charmbracelet | lipgloss#672 | bubbletea |
| sharkdp | fd#1994 | bat (next) |
| apache | datafusion-ballista#1673 | airflow, opendal, superset |
| IBM | mcp-cli#242 | AssetOpsBench, mcp-context-forge |
| pylint-dev | pylint#11002 | astroid |
| tracel-ai | burn#4937, cubecl#1328 | burn-onnx |
| pyro-ppl | numpyro#2188, pyro#3451 | - |
