---
variant: post
title: "Never Intercept Payments"
tags: vector-space
---

Publishers don't trust exchanges. Advertisers don't trust exchanges. Exchanges don't trust each other. The [ANA found](https://www.ana.net/content/show/id/pr-2023-06-programmaticstudy) that 64 cents of every programmatic dollar disappeared between advertiser and publisher. Google executives [acknowledged](https://digiday.com/media/the-rundown-u-s-v-google-ad-tech-antitrust-trial-by-numbers-so-far/) "irrationally high rents" in the antitrust trial. Nobody is surprised.

The money passes through the exchange, so the exchange can always hide fees. The incentives are clean: payoff large, detection slow, switching cost high.

So don't let the money pass through.

## The Exchange Is a Service

In the standard model, the advertiser pays the exchange, which takes its cut and forwards the rest. The publisher sees a net number and trusts that the deduction was fair.

Flip it. The advertiser pays the publisher directly; the publisher pays the exchange a service fee for routing demand — bid evaluation, [auction resolution](/power-diagrams-ad-auctions), [receipt generation](/receipts-please) — like a CDN bills for bandwidth. One visible line item.

Every dollar the advertiser paid lands in the publisher's account. Visible on arrival. The exchange's fee is separate, explicit, auditable. Nothing to reconcile because nothing was commingled. Settlement runs on [envelopay](/envelopay-spec): the transfer happens on-chain, the email carries the proof, and the DKIM-signed thread is the audit trail. Cost per settlement: under a tenth of a cent.

## Routing Is the Leverage

The obvious objection: what if the publisher doesn't pay? The exchange routed the demand, the publisher collected, and now they stiff the exchange on the service fee.

That assumes contractual leverage: invoices and courts. But the exchange controls something stronger: bid routing itself. The scoring function, the [TEE](/monetizing-the-untouchable), the demand pipeline. Publisher stops paying, exchange stops routing. Bids stop arriving. Revenue dries up.

This leverage is continuous: every impression is a fresh decision to send demand. Yesterday's routing buys nothing; tomorrow's requires today's payment. Less credit exposure: the value stream is real-time.

In the standard model, the exchange's leverage is *withholding money it already collected*. That's what creates the opacity. Publisher-remits swaps financial leverage for operational leverage: cleaner for both sides.

## Five Costs That Vanish

When the exchange never touches advertiser funds, entire categories of overhead disappear.

**Money transmission licensing.** Exchanges that hold and distribute funds are payment intermediaries: [MSB](https://en.wikipedia.org/wiki/Money_services_business) registration, state-by-state licensing, compliance infrastructure. An exchange that invoices for a service? Software vendor. Different regulatory category.

**[Float](https://en.wikipedia.org/wiki/Float_(money_supply)).** The standard exchange collects from the advertiser on [net-30](https://en.wikipedia.org/wiki/Net_D), pays the publisher on net-60, and pockets interest on the spread: a financing business wearing an ad exchange as a skin suit. Publisher-remits eliminates float. The exchange never holds the principal.

**Disputes.** A disputed charge traps the exchange in the middle, holding money two parties claim. Publisher-remits puts the dispute where it belongs: between advertiser and publisher. The exchange holds [attested receipts](/receipts-please) but not the funds.

**Payout schedules.** No batching, no minimum thresholds, no "$100 before we pay" gates. The publisher already has the money.

**Working capital.** No capital reserves to front publisher payments. Launch costs drop to engineering and infrastructure, not treasury operations.

## Trust by Structure

[Transparency Is Irreversible](/transparency-is-irreversible) argues that publishing σ is a one-way gate: once advertisers see each other's reach, no successor can claw that visibility back. Publisher-remits is the financial gate.

Public σ means you can't hide what you're *doing*; publisher-remits means you can't hide what you're *charging*. Together they close both sides of the opacity problem: information transparent by protocol, money transparent by architecture. Reintroducing hidden fees would require restructuring the entire payment flow. Every participant would notice.

[Epsilon-Nash](/transparency-is-irreversible#how-much-should-an-exchange-charge) says fees settle where switching cost meets marginal cost. When the exchange never touches the money, fees compress to what the pipe is worth: compute, routing, [attestation](/receipts-please). Two percent, not thirty.

The gap between thirty percent and two is not negotiation — it's architecture. Never intercept payments, and the fee has nowhere to hide.

---

*Part of the [Vector Space](/vector-space) series.*
