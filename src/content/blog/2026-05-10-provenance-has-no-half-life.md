---
variant: post
title: "Provenance Has No Half-Life"
tags: pageleft
---

*Part of the [pageleft](/pageleft) series.*

Two camps. One refuses AI contributions on principle. The other evaluates the diff. The first camp's throughput is bounded by one human's attention. The second's compounds with every contributor who can write a spec that an agent compiles.

The gap widens at machine speed. Every month, the agnostic camp ships more, the anti-AI camp falls further behind, and the distance becomes harder to close. Not because the argument was won. Because one side kept shipping while the other kept explaining why their way was more legitimate.

Real programmers write assembly by hand. Everyone else is faking it.

## The squeeze

[The Press](/the-press) argued that copyleft squeezes out copyright. Not replaces. Squeezes. The cost curves diverge: copyleft gets cheaper as [Canon](/canon) grows; copyright gets more expensive as the provenance pile deepens. The holdouts hold until holding costs exceed switching costs. Then the equilibrium flips.

[Sweep & Triage](/sweep-and-triage) demonstrated the mechanism at the smallest observable scale. One repo, fourteen PRs, one merge. The merge took fifty-six seconds. Minus thirty-four lines, obvious dedup, zero questions needed. Every rejection was a verification cost the maintainer couldn't justify paying. [H5](/sweep-and-triage#the-hypothesis-graph): maintainers optimize for review efficiency, not correctness. Five repos confirmed, zero against.

Spec-depth prose makes verification cheap. When the issue is the spec, precise enough that a coding agent compiles it without guessing, the PR stops asking the maintainer to evaluate a diff against an underspecified problem. It asks whether the diff matches a spec that's already public, timestamped, linkable. Five questions collapse to one. The maintainer becomes a verifier instead of an investigator.

The throughput differential between the two camps is the cost-curve squeeze playing out at repo scale. The same mechanism operates at every scale where the policy choice exists: repos, companies, industries, legal regimes. Sweep & Triage is the smallest instance. The larger instances are predictions.

## Absorption

[CC BY-SA-NS](/cc-by-sa-ns) is strictly more restrictive than CC BY-SA. Same share-alike, plus the network clause. In the [license lattice](/licenses-are-functors), stricter absorbs weaker on derivation: CC BY-SA-NS ⊗ CC BY-SA = CC BY-SA-NS.

Any derivative work that combines a BY-SA-NS source with a BY-SA source inherits the network obligation. The corpus doesn't have to be relicensed. The upgrade rides in via composition. Wikipedia is BY-SA. Stack Overflow is BY-SA. The moment a substantial derivative crosses a BY-SA-NS work, the derivative is BY-SA-NS.

AI companies run code on servers without distributing binaries. Standard copyleft misses them. The NS clause closes that loophole for prose the same way AGPL closed it for code.

A handful of authors publishing under NS puts a network clause in the future of any work that derives from the BY-SA commons and crosses theirs. The clause's reach scales superlinearly with adoption. The licensing decision is contagious through the citation graph.

Creative Commons hasn't added a network clause in twelve years. They patch after the need is visible. They don't predict. CC BY-SA-NS is what happens when one author does.

## The law

Legal doctrine runs on dependencies that shift:

**Enforcement budget.** Every infringement claim has to sort through a deeper pile of timestamped open prior art. Enforcement gets more expensive per case. The marginal claim worth pursuing in 2015 becomes too expensive by 2030.

**Cultural legibility.** Juries decide derivative-work questions. If "an issue is a spec, a spec compiles to code, the code is a derivative" becomes how engineers describe their practice, the jury hearing the case has that frame already loaded. Feist killed sweat-of-the-brow because the alternative had become culturally absurd.

**Industry practice.** Doctrine follows what industry has already settled into. If spec-then-compile becomes normal engineering, the next generation of doctrine accommodates it. Courts don't lead. They ratify.

**Political economy.** As the cost curves invert, companies built on Canon have an interest in keeping Canon's licensing intact. New constituencies, new statutes.

**Evidentiary infrastructure.** Commit timestamps, signed publications, copyleft license metadata. Provenance has to be provable to be enforceable. Building that infrastructure is itself a form of legal change.

The squeeze doesn't defeat the legal regime. The substrate it runs on shifts under it.

## Courts won't decide

The [idea-expression boundary](/open-prose) is where this lives. Consider the scenario where prose-as-source is ruled copyrightable expression. Then every coding agent that read a blog post and produced an implementation created a derivative work. Every company running vibe-coded output as a service is distributing derivatives of every post the agent drew from. OpenAI trained on the corpus. Anthropic trained on the corpus. The liability surface is the entire internet.

Courts can handle individual cases. They cannot issue a general ruling that resolves prose-as-source without massive collateral consequences. The idea-expression boundary is a gradient, not a line. Which sentence in a blog post is protectable expression and which is uncopyrightable idea? The answer changes per paragraph, per clause, per word. Every case requires bespoke filtration: [*Altai*](https://law.justia.com/cases/federal/appellate-courts/F2/982/693/137252/) abstraction-filtration-comparison, applied to prose instead of code, at a scale that would overwhelm every federal district.

Consider the opposite. Courts rule that compilable prose is idea, not expression. Copyright doesn't attach. Then copyleft has nothing to enforce — but neither does copyright. The entire IP regime for AI-assisted output dissolves. Every company that claims ownership of vibe-coded software loses the legal basis for that claim. The same ruling that frees prose from copyleft frees code from copyright. That outcome is worse.

Either direction overwhelms the courts. Out of self-preservation, they defer. Not by refusing to hear cases, but by settling narrowly, by distinguishing facts, by letting the question age without resolving it. The deferral is structural.

Courts are best served waiting until public opinion settles. When the question finally reaches a jury, the judge invites an expert whose testimony is unambiguous because the practice is already established. The expert doesn't argue a novel theory. They describe what everyone already does. The jury nods. The ruling ratifies.

[*Burrow-Giles v. Sarony*](https://www.law.cornell.edu/supremecourt/text/111/53) settled photography the same way in 1884. The photographer chose the subject, angle, and lighting; the camera was mechanical. The spec-writer chooses architecture, constraints, and tradeoffs; the agent is mechanical. By the time the Supreme Court ruled that photographs were copyrightable, photographers had been claiming authorship for decades. The ruling didn't change practice. It recognized it.

If spec-depth prose keeps compiling to working systems, if engineers keep treating posts as build instructions, if [vibelogging](/vibelogging) becomes how software gets specified, then by the time the question reaches a courtroom, prose-as-expression is the only answer that matches what everyone already believes. The expert witness describes the practice. The jury has used coding agents themselves. The ruling writes itself.

[PageLeft](/pageleft-manifesto) is the infrastructure that tips it. Every spec-depth issue, every compilable post, every derivative that traces to prose under copyleft builds the practice the courts will eventually ratify. The question isn't whether prose is expression. It's whether enough people treat it that way before the court gets around to asking.

[CC BY-SA-NS](/cc-by-sa-ns) is the first move in that window. No professional legal opinion required. It would be based on courts that won't rule yet. The license works the way GPL v1 worked. The Free Software Foundation didn't wait for courts to confirm copyleft was enforceable. They wrote the license, attached it to GNU, and let the practice run for a decade before case law caught up. It worked because people respected it, it was written down, and complying was cheaper than fighting.

## Provenance has no half-life

Patents expire. Trade secrets leak. Copyrights eventually lapse. Trademarks can be abandoned.

Provenance doesn't decay. A commit timestamp from 2026 is still a 2026 timestamp in 2050. Publication dates don't drift. Citation graphs don't lose edges. The Internet Archive doesn't forget. The evidence accumulates. The redundancy compounds. Every attempt to dispute the timestamp adds new artifacts that confirm it.

Early movers' positions appreciate indefinitely. Late entrants can't manufacture earlier timestamps. An author who licenses BY-SA-NS in 2030 joins a corpus that earlier authors already shaped.

For the corporate side, waiting accumulates exposure. Every additional year of BY-SA-NS publication grows the corpus that any future derivative might compose with. Doing nothing accumulates exposure at machine speed.

## Zero downside

Four scenarios.

**Nobody adopts.** The work is still public, still indexed, still timestamped. The NS clause sits inert. Cost to me: zero.

**Someone derives and complies.** The clause did its job. The commons grew. Cost: zero.

**Someone derives and ignores the clause.** I don't sue. I don't mention it. Non-enforcement preserves the clause without exposing it to an adverse ruling. The provenance says I published first; the violator's conduct is now part of a record someone else can litigate with better facts. Cost: zero.

**Someone reads my work and publishes their own version under BY-SA.** Best outcome. Their work joins the BY-SA corpus. Mine sits one notch above in the lattice. Any future derivative combining theirs with mine is BY-SA-NS by absorption. They've recruited themselves as an unwitting ally. Cost: zero.

Every scenario terminates at zero cost. Two strengthen the position. Two leave it unchanged. BY-SA-NS weakly dominates BY-SA across every state of the world.

## Cowardice

Risk-averse players don't wait for the cost curves to fully invert. They wait for the appearance of consensus, then move in herds. The first few defections are read as outliers. Past a threshold, the same legal departments flip from "copyleft is a risk we avoid" to "anti-AI policy is a risk we can't justify." The perceived position shifted. The cost curves didn't.

Premature conformity is the failure mode. The risk-averse player optimizes for "don't be wrong relative to peers." They convert late enough to eat the throughput penalty and contribute nothing to the substrate that's winning. They survive, but as second-tier participants: no timestamps from the formative period, no standing in the citation graph, no provenance the post-transition regime can't dislodge.

Someone has to go first. Waiting for someone else to absorb the first-mover risk while the foundational period closes is cowardice. The option being declined isn't "should I license this work." It's "should I have a position in the foundational period." Anti-copyleft policy in legal departments — the kind that fires a CI warning when an engineer imports a share-alike dependency — is the same algorithm at a different scale. They optimize against locally visible peer behavior and will flip together, in cohorts, when the perceived consensus tips. The demise looks like Kodak: presiding over the slow obsolescence of a position that used to be the safe one.

## Inevitable

The direction is obvious. The timing is not.

Abstraction transitions resolve one way. Assembly to C, manual memory to GC, on-prem to cloud. The lower-level practitioners hold the high-status position during the transition, then become a niche, then become a costume. The burden is on whoever thinks prose-to-code is the transition that breaks the pattern.

The trend shows it, the tools allow it, and abduction, induction, and deduction all point one way. The ratchet is slow but real. Copyleft is irrevocable. The corpus only grows. Each foundational publication is a permanent move forward that no subsequent action can reverse.

Obvious in direction, uncertain in timing. Publish, timestamp, wait. The position holds across every window: 2028, 2038, 2048. The ratchet runs at whatever pace the regime runs at. Direction-rightness is what the strategy needs. Timing-rightness is what the strategy is designed not to need.

I see the future. The timestamp will show I said so.

---

*Provenance has no half-life. The foundational period is now. The ratchet turns.*
