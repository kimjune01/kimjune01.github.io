---
variant: post-medium
title: "Before You Compose"
tags: methodology
---

*Part of the [methodology](/methodology) series. Follows [The Hypothesis Graph](/the-hypothesis-graph).*

---

E-values compose. Multiply evidence across experiments, peek whenever you want, and the guarantee holds. [Previous posts](/evidence-has-a-trajectory) argued this beats compressing to a p-value. An [experiment](https://github.com/kimjune01/e-value-trajectory) confirmed it: composed e-values classified forcing patterns at F1 = 1.000 where standardized sums scored 0.478.

The question is whether the composed trajectory still contains recoverable signal after real-world damage. I stress-tested it. The classifier broke in two places and held in three others.

### Where it breaks

**Missing data.** At 10% missing observations, F1 drops from 1.000 to 0.755. At 25%, to 0.733. In our implementation, each missing observation contributes zero to the composed trajectory (neutral evidence by design). Enough zeros dilute the signal below detection. I tested weighted imputation (upweighting survivors). No difference. The signal isn't misweighted. It's gone.

**Correlated streams.** At ρ = 0.6 between streams, F1 drops to 0.733. The composition advantage disappears because correlated streams carry the information of 1.5 independent ones, not five. I tested averaging instead of multiplying (the theoretically safe option under arbitrary dependence, per [Wang 2025](https://academic.oup.com/biomet/article/112/2/asaf020/8086785)). Same F1. Correlated forcing corrupts the features before composition even runs.

### Where it holds

**Heavy tails.** Replacing the Normal stream with a t-distribution (df = 3, extreme outliers) had zero effect. F1 = 1.000. The classifier uses rank-based features (Theil-Sen slope, permutation entropy, spectral peaks), so outlier magnitude is irrelevant. Heavy tails change values but not rank order, and rank order is all the features need.

**Drift.** A slow nonstationary baseline (0.02 drift per trajectory length) barely registers. F1 = 0.999, null false positive rate 0.4%. The drift is too slow relative to the forcing signal to trigger the trend detector.

**Autocorrelation.** At φ = 0.2 to 0.5, degradation is graceful. At φ = 0.8, the null false positive rate rises to 17% because the autocorrelated noise looks like a weak trend, but F1 stays above 0.92.

### Three checks before you compose

Clean input, correct classification. Corrupted input, no downstream fix recovers what the corruption destroyed.

Before composing e-values across heterogeneous streams, check three things. If any fail, stop and fix the data, not the analysis.

#### 1. Is your signal above the detection cliff?

Every forcing pattern has a minimum amplitude below which the classifier can't detect it. Below that amplitude, 0% detection; above it, 100%. In these experiments, detection behaved like a cliff.

Cliffs vary 50x across patterns. Oscillation is detectable at amplitude 0.03 because spectral energy concentrates in one frequency bin; a linear trend needs 1.50 because the per-step slope is tiny relative to noise. If your signal falls short, more streams won't help. You need more observations or stronger perturbations.

*Check:* compute your composed trajectory's spectral peak ratio and Theil-Sen slope against thresholds calibrated on your null. If both are below threshold, your signal is undetectable at this sample size.

#### 2. Are your streams independent?

Composition gains come from combining independent information. The effective number of independent streams is K_eff = K / (1 + ρ(K-1)), where ρ is the average pairwise correlation. At ρ = 0, K_eff = K. At ρ = 0.6 with K = 5, K_eff ≈ 1.5: five sensors worth only one and a half.

Averaging doesn't fix it, and decorrelation is unreliable if the shared factor is unknown. Shared noise erases the composition advantage.

*Check:* compute pairwise correlation across your streams under null conditions (no forcing). If mean ρ > 0.3, your composition is less than half as powerful as independent streams. If ρ > 0.6, use single-stream analysis instead.

#### 3. Is your data at least 90% complete?

Missing observations contribute zero evidence. At 10% missing, 10% of the trajectory carries no signal. For patterns near their detection cliff (trends, aperiodic forcing), this pushes the signal below threshold. For patterns well above their cliff (oscillation), 10% missing is survivable.

No imputation scheme fixes this because the missing observations aren't misweighted; they're absent. Interpolation introduces false structure. The only fix is better data collection.

*Check:* count the fraction of missing observations per stream. If any stream exceeds 10%, the composed trajectory is unreliable for near-cliff signals.

### Composition is conditional

E-value composition preserves evidence under optional stopping, but it cannot recover signal that was never observed, and it cannot turn correlated streams into independent evidence. Composition is conditional on data quality: independent streams, complete data, sufficient signal.

Run the three checks before you compose. If they pass, composition gives you the power advantage seen in the experiment. If they fail, the result is still useful: it tells you which prerequisite broke.
