I tested 27 merged PRs across 9 repos (3 languages) to measure whether iterative LLM review catches slop (code that passes tests but isn't merge-ready). 9 trials were on gemini-cli.

The status quo for this repo is a one-shot review from Gemini Code Assist. That's the 43% baseline: a coin flip on merge-readiness. With an adversarial cross-model loop (hunt bugs → fix → rebuild → retest → repeat), 91%. Same code, same spec. I only added the loop.

If you have access to more than one SOTA model, iterating before submitting the PR is a certain improvement. Maintainer time is the bottleneck. Arriving pre-iterated means less back-and-forth and a higher chance of approval on first human review.

Writeup (methodology, per-language breakdowns, caveats): https://june.kim/does-iteration-mitigate-slop-slope

Experiment repo: https://github.com/kimjune01/refactor-equivalence

Forge diffs on this repo: [#2](https://github.com/kimjune01/gemini-cli-claude/pull/2), [#3](https://github.com/kimjune01/gemini-cli-claude/pull/3), [#4](https://github.com/kimjune01/gemini-cli-claude/pull/4), [#5](https://github.com/kimjune01/gemini-cli-claude/pull/5)
