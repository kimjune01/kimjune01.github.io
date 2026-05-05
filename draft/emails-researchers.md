# SRE outreach — trilogy

## Will Larson — lethain@gmail.com

Subject: formalizing how SREs diagnose systems

Hi Will,

I wrote a trilogy of posts that tries to formalize what SREs already do when they diagnose a production issue. The core idea is that every diagnostic step either validates a hypothesis or kills it, and the kill condition tells you what to test next. I built an experiment to back it up with data: a four-bin classifier on composed evidence trajectories that achieves near-perfect accuracy on clean data but breaks sharply under missing data and correlated sensors.

The first post argues that compressing evidence to a single number (like a p-value or a threshold alert) throws away the temporal structure that carries diagnostic information. The second post formalizes the diagnostic loop as a graph where each experiment generates edges pointing to the next experiment. The third post identifies three prerequisite checks you should run before trusting composed evidence across heterogeneous streams.

I think you'd find the connection to incident response interesting. The runbook is a partial version of this graph, but without the formal structure that would let it accumulate knowledge across incidents rather than just within them.

https://june.kim/evidence-has-a-trajectory
https://june.kim/the-hypothesis-graph
https://june.kim/before-you-compose

June Kim

---

## Charity Majors — charity@honeycomb.io (inferred, unconfirmed)

Subject: formalizing the SRE diagnostic loop

Hi Charity,

I wrote a trilogy of posts that tries to formalize what happens when an engineer stares at a dashboard and decides what to check next. The argument is that the shape of a signal over time carries diagnostic information that a single threshold alert throws away, and that every failed diagnostic check tells you what to test next. I built a classifier to back it up with an experiment, and the third post identifies three prerequisite checks for when composing signals across heterogeneous streams works versus when it breaks.

I think the connection to observability is direct. The runbook is a partial version of this graph, and the postmortem is where the graph accumulates across incidents.

https://june.kim/evidence-has-a-trajectory
https://june.kim/the-hypothesis-graph
https://june.kim/before-you-compose

June Kim

---

## Liz Fong-Jones — lizf@honeycomb.io

Subject: when composed signals break — three prerequisite checks

Hi Liz,

I wrote a series on formalizing the SRE diagnostic loop as a hypothesis graph, where each diagnostic test either classifies the system or generates the next test to run. I built a four-bin classifier on composed evidence trajectories and stress-tested it. The classifier works perfectly on clean data but collapses at 10% missing observations and when sensors share correlated noise. The third post distills it into three prerequisite checks you should run before trusting any composed signal across heterogeneous streams.

The full experiment repo is public, including all preregistrations and robustness analysis.

https://june.kim/evidence-has-a-trajectory
https://june.kim/the-hypothesis-graph
https://june.kim/before-you-compose
https://github.com/kimjune01/e-value-trajectory

June Kim

---
