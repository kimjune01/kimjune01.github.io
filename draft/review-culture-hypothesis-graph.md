# Hypothesis Graph: Review Culture Pipeline

Root question: does the issue-first, review-schema-shaped, drip-paced pipeline produce higher merge rates than ad-hoc contribution?

## H0: Issue-first PRs merge at a higher rate than unsolicited PRs

- **Evidence for:** tinygrad #16116 — mechanically correct unsolicited PR rejected. No unsolicited PRs merged in our sample.
- **Evidence against:** none yet
- **Falsification:** an unsolicited PR merges faster than an issue-linked PR on the same repo, same contributor
- **Test:** first 20 PRs from `/sweep` — track issue-linked vs unsolicited merge rates
- **Status:** UNCONFIRMED

## H1: Review schema conformance predicts merge outcome

- **Evidence for:** tinygrad rejection pattern — PRs that violated gates (missing tests) were rejected. PR that passed all gates still rejected (but standing was the confound).
- **Evidence against:** #16116 passed all technical gates, still rejected
- **Falsification:** merge rate is uncorrelated with schema conformance across 20+ PRs on 3+ repos
- **Test:** for each PR, score schema conformance (gates passed / total gates, signals within distribution). Correlate with outcome.
- **Confound:** standing. Need to control for contributor history.
- **Status:** UNCONFIRMED

## H2: Standing is a gate that supersedes technical quality

- **Evidence for:** #16116 — perfect schema conformance, rejected on contributor history. "Last warning" language evaluated the person, not the PR.
- **Evidence against:** none yet
- **Falsification:** a contributor with burned standing submits a schema-conforming PR and it merges
- **Test:** compare merge rates for first-time contributors vs repeat contributors vs warned contributors, holding PR quality constant
- **Dependency:** H1 (need schema conformance as a control variable)
- **Status:** UNCONFIRMED

## H3: Drip pacing prevents standing damage

- **Evidence for:** tinygrad ban trajectory — multiple PRs in rapid succession preceded the warning. Volume was cited ("low quality PRs" plural).
- **Evidence against:** none yet — drip hasn't run a full cycle yet
- **Falsification:** a drip-paced contributor (1 PR per merge cycle) still gets warned for volume
- **Test:** first 3 repos through `/sweep` — track time between PRs and maintainer sentiment
- **Status:** UNCONFIRMED

## H4: Framing affects outcome independently of code quality

- **Evidence for:** #16116 body "I'm learning" — personal frame in a code-speaks-for-itself repo. Likely contributed to "low quality" judgment despite clean diff.
- **Evidence against:** single data point, confounded with H2 (standing already burned)
- **Falsification:** two PRs with identical diffs, different framing (contribution vs personal), same outcome
- **Test:** A/B across repos — minimal body vs explanatory body vs no body. Track merge rates.
- **Confound:** hard to isolate from standing and schema conformance
- **Status:** UNCONFIRMED

## H5: The pipeline produces higher merge rates than manual contribution

The meta-hypothesis. Depends on H0–H4.

- **Evidence for:** none yet — pipeline hasn't run a full cycle
- **Evidence against:** none yet
- **Falsification:** manual contributions (no schema, no drip, no issue-first) merge at the same rate across the same repos
- **Test:** compare merge rate of first 20 pipeline PRs against the tinygrad baseline (1/11 merged, ~9%)
- **Target:** >50% merge rate across 3+ repos
- **Status:** UNCONFIRMED

## Edges

```
H0 (issue-first) ──→ H5 (pipeline wins)
H1 (schema conformance) ──→ H5
H2 (standing gate) ──→ H3 (pacing prevents damage)
H4 (framing) ──→ H1 (schema should include framing)
H3 (pacing) ──→ H5
```

## Kill conditions

- If H0 is killed (issue-first doesn't help), the pipeline's discovery layer is wrong. /actionable needs rethinking.
- If H1 is killed (schema doesn't predict), the review-schema skill is theater. Cut it.
- If H2 is killed (standing doesn't matter), the pipeline is over-cautious. Remove cooldowns and pacing.
- If H5 is killed (pipeline doesn't beat manual), the whole thing is overhead.

## Data collection

Every PR through `/sweep` generates a row:

| Field | Source |
|---|---|
| repo | /triage |
| issue_number | /actionable |
| schema_conformance | /review-schema score |
| standing | first-time / repeat / warned |
| framing | body classification |
| pacing_days | /drip log |
| outcome | merged / closed / ignored |
| time_to_outcome | /drip log |
| reviewer_language | gh pr comments |
