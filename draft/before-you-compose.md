---
variant: post-medium
title: "Before You Compose"
tags: methodology
---

*Part of the [methodology](/methodology) series. Follows [The Hypothesis Graph](/the-hypothesis-graph).*

---

E-values compose. You can multiply evidence across experiments, peek whenever you want, and the guarantee holds. The [previous posts](/evidence-has-a-trajectory) argued this is strictly more useful than compressing to a p-value. The [experiment](https://github.com/kimjune01/e-value-trajectory) confirmed it: composed e-values classified forcing patterns at F1 = 1.000 where standardized sums scored 0.478.

Then I stress-tested it. The classifier broke in two places and held everywhere else. The breaks tell you more than the successes.

### Where it breaks

**Missing data.** At 10% missing observations, F1 drops from 1.000 to 0.755. At 25%, it collapses to 0.733. The classifier treats missing observations as neutral evidence (zero contribution to the composed trajectory). Enough zeros dilute the signal below the detection threshold. No imputation scheme fixes this — I tested weighted imputation (upweighting surviving observations) and it made no difference. The signal isn't misweighted. It's gone.

**Correlated streams.** At ρ = 0.6 correlation between streams, F1 drops to 0.733. The composition advantage disappears because correlated streams aren't independent sources of information. Five correlated sensors carry the information of 1.5 independent ones. I tested averaging instead of multiplying (the theoretically safe option under arbitrary dependence, per [Wang 2025](https://academic.oup.com/biomet/article/112/2/asaf020/8086785)). Same F1. The problem isn't the composition method. The problem is that correlated forcing corrupts the features before composition even runs.

### Where it holds

**Heavy tails.** Replacing the Normal stream with a t-distribution (df = 3, extreme outliers) had zero effect on classification. F1 = 1.000. The classifier uses rank-based features (Theil-Sen slope, permutation entropy, spectral peaks) that ignore outlier magnitude. Heavy tails change the values but not the ordering, and the ordering is all the features need.

**Drift.** Adding a slow nonstationary baseline (0.02 drift per trajectory length) had near-zero effect. F1 = 0.999, null false positive rate 0.4%. The drift is too slow relative to the forcing signal to trigger the trend detector.

**Autocorrelation.** Mild to moderate autocorrelation (φ = 0.2 to 0.5) degrades gracefully. At φ = 0.8, the null false positive rate rises to 17% — the autocorrelated noise looks like a weak trend. But F1 stays above 0.92.

### Three checks before you compose

The pattern: the classifier works when its input is clean and fails when its input is corrupted. No downstream fix (better imputation, different composition rule, fancier classifier) recovers what the input destroyed.

Before composing e-values across heterogeneous streams, check three things. If any fail, stop and fix the data, not the analysis.

**1. Is your signal above the detection cliff?**

Every forcing pattern has a minimum amplitude below which the classifier can't detect it. The cliff is sharp: 0% detection one step below, 100% one step above. There is no "partial detection" regime.

The cliffs vary 50× across patterns. Oscillation (periodic signal) is detectable at amplitude 0.03 because spectral energy concentrates in one frequency bin. A linear trend needs amplitude 1.50 because the per-step slope is tiny relative to noise. If your signal is below the cliff for its pattern type, adding more streams or fancier composition won't help. You need more observations or stronger perturbations.

**Check:** compute your composed trajectory's spectral peak ratio and Theil-Sen slope. Compare to thresholds calibrated on your null. If both are below threshold, your signal is undetectable at this sample size.

**2. Are your streams independent?**

The composition advantage comes from combining independent information. The effective number of independent streams is K_eff = K / (1 + ρ(K-1)), where ρ is the average pairwise correlation and K is the number of streams. At ρ = 0, K_eff = K (full independence). At ρ = 0.6 with K = 5, K_eff ≈ 1.5. You have five sensors contributing the information of one and a half.

This isn't a composition problem — averaging doesn't fix it, decorrelation is unreliable if the shared factor is unknown. It's a data design problem. If your streams share noise, the composition advantage is an illusion.

**Check:** compute pairwise correlation across your streams under null conditions (no forcing). If mean ρ > 0.3, your composition is less than half as powerful as independent streams. If ρ > 0.6, use single-stream analysis instead.

**3. Is your data at least 90% complete?**

Missing observations are set to zero evidence (neutral contribution). At 10% missing, the composed trajectory has 10% of its length carrying no signal. For patterns near their detection cliff (trends, aperiodic forcing), this pushes the signal below threshold. For patterns well above their cliff (oscillation), 10% missing is survivable.

No imputation scheme fixes this. Weighted imputation (upweighting survivors) doesn't help because the missing observations aren't misweighted — they're absent. Interpolation introduces artificial structure. The only fix is better data collection.

**Check:** count the fraction of missing observations per stream. If any stream exceeds 10%, the composed trajectory is unreliable for near-cliff signals.

### The honest recommendation

E-value trajectories are always better than p-values. They preserve temporal structure at zero cost. But composition across streams is conditional on data quality. The composition advantage is real when streams are independent, complete, and carry sufficient signal. When any of these fail, composition adds complexity without adding power.

Three checks, three numbers, three thresholds. Run them before you compose. If they pass, the framework gives you a 3.4× power advantage and a four-bin classification with F1 > 0.99. If they fail, the framework tells you which prerequisite to fix. Either way, you learn more than a p-value would tell you.

The kill condition for the technique is the technique applied to itself.
