# SSPA Structured Products on Daml Finance

An implementation of Swiss structured products — as classified by the
[SSPA Swiss Derivative Map© 2026](https://www.sspa.ch) — as DAML templates built on
[`daml-finance`](https://github.com/digital-asset/daml-finance), Digital Asset's open-source
library for modeling financial instruments, lifecycle events, and settlement on DAML.

## Status

| SSPA category | Products | Status |
|---|---|---|
| 11 — Capital protection | 1100, 1130, 1135, 1140 | Implemented (from scratch) |
| 12 — Yield enhancement | 1200, 1210, 1220, 1230, 1255, 1260 | Implemented (1230/1255/1260 reuse daml-finance's own instruments) |
| 13 — Participation | 1300, 1310, 1320, 1330, 1340 | Implemented (from scratch) |
| 14 — Additional credit risk | 1400, 1410, 1420, 1430 | Implemented (from scratch) |
| 20 — Leverage | 2100, 2110, 2200, 2210, 2300 | Implemented (2100/2200 reuse daml-finance's own instruments) |

All 24 products across all 5 SSPA categories are implemented, and every one of them has a full
Daml Script test suite (`daml/Sspa/Test/`, one file per category, 24 scenario functions covering
~40 sub-cases total — most products get both a "plain" and a barrier-breach/credit-event case)
exercising the complete lifecycle → claim → settlement pipeline end-to-end, with real settled
holding balances asserted against hand-computed expected amounts.

## Product mapping

### 11 — Capital protection (`daml/Sspa/CapitalProtection/`)

Built from scratch on top of `daml-finance`'s contingent-claims combinators
(`Daml.Finance.Claims.V3.Util.Builders`, itself built on `ContingentClaims.Core.V3.Claim`), since
`daml-finance` doesn't ship ready-made capital-protection instruments.

| SSPA code | Product | Module | Payoff |
|---|---|---|---|
| 1100 | Capital Protection Note with Participation | `Participation.daml` | Protected principal + long call above strike |
| 1130 | Capital Protection Note with Barrier | `Barrier.daml` | Protected principal + up-and-out call, knock-out pays a fixed rebate |
| 1135 | Capital Protection Note with Twin Win | `TwinWin.daml` | Protected principal + call + down-and-in-*out* put (i.e. active until the barrier is breached), so both up and down moves earn participation as long as the barrier holds |
| 1140 | Capital Protection Note with Coupon | `Coupon.daml` | Protected principal + a coupon per period, floored at zero, driven by that period's underlying performance |

`Util.daml` in the same directory holds the two claim-building helpers these products needed
beyond what `daml-finance` already provides: a "pay a fixed rebate the first time a barrier is
breached" claim, and a "floored performance coupon" claim.

### 12 — Yield enhancement (`daml/Sspa/YieldEnhancement/`)

| SSPA code | Product | Module | Payoff |
|---|---|---|---|
| 1200 | Discount Certificate | `DiscountCertificate.daml` | Capped bond − short put (built from scratch) |
| 1210 | Barrier Discount Certificate | `BarrierDiscountCertificate.daml` | Capped bond − short down-and-in put (built from scratch) |
| 1220 | Reverse Convertible | `ReverseConvertible.daml` | Fixed-coupon bond − short put (built from scratch) |
| 1230 | Barrier Reverse Convertible | `BarrierReverseConvertible.daml` | Fixed-coupon bond − short down-and-in put — **re-exports `daml-finance`'s own `Instrument.StructuredProduct.V0.BarrierReverseConvertible`** |
| 1255 | Conditional Coupon Reverse Convertible | `ConditionalCouponReverseConvertible.daml` | Autocallable with coupon-at-risk, no separate final-redemption barrier — **re-exports `daml-finance`'s own `Instrument.StructuredProduct.V0.AutoCallable`** (parameterize with `finalBarrier = putStrike`) |
| 1260 | Conditional Coupon Barrier Reverse Convertible | `ConditionalCouponBarrierReverseConvertible.daml` | Same as 1255, plus a protective final-redemption barrier — **re-exports the same `AutoCallable`** (parameterize with `finalBarrier < putStrike`) |

Where `daml-finance` already ships a battle-tested instrument for the exact economic structure a
product needs (1230, 1255, 1260 are all bond/coupon-plus-barrier-option structures that
`Instrument.StructuredProduct.V0` already covers), the corresponding module here is a thin
re-export rather than a reimplementation — see each file's header comment for the reasoning and
the exact parameterization used to specialize the shared `AutoCallable` template into the two
distinct SSPA codes 1255/1260.

### 13 — Participation (`daml/Sspa/Participation/`)

Built from scratch, on top of one shared building block: a plain, uncapped, unfloored 1:1 tracker
claim (`Util.daml`'s `createTrackerClaim`), which every product in this category layers barrier
and/or option legs on top of.

| SSPA code | Product | Module | Payoff |
|---|---|---|---|
| 1300 | Tracker Certificate | `TrackerCertificate.daml` | Plain 1:1 tracker |
| 1310 | Outperformance Certificate | `OutperformanceCertificate.daml` | Tracker + extra long call above strike (disproportionate upside) |
| 1320 | Bonus Certificate | `BonusCertificate.daml` | Tracker + long down-and-out put (bonus floor at nominal while the barrier holds) |
| 1330 | Bonus Outperformance Certificate | `BonusOutperformanceCertificate.daml` | Tracker + outperformance call + bonus down-and-out put (1310 + 1320 combined) |
| 1340 | Twin Win Certificate | `TwinWinCertificate.daml` | Tracker + 2×-scaled long down-and-out put (falling underlying converts to profit while the barrier holds) |

### 20 — Leverage (`daml/Sspa/Leverage/`)

| SSPA code | Product | Module | Payoff |
|---|---|---|---|
| 2100 | Warrant | `Warrant.daml` | Plain vanilla call/put — **re-exports `daml-finance`'s own `Instrument.Option.V0.EuropeanCash`** |
| 2110 | Spread Warrant | `SpreadWarrant.daml` | Long option + short option at a further strike (call spread / put spread, built from scratch) |
| 2200 | Warrant with Knock-Out | `WarrantWithKnockOut.daml` | Barrier call/put, worthless on breach — **re-exports `daml-finance`'s own `Instrument.Option.V0.BarrierEuropeanCash`** |
| 2210 | Mini-Future | `MiniFuture.daml` | Knock-out option struck at a financing level, small residual paid on a stop-loss breach (built from scratch; simplified — no daily financing-level reset) |
| 2300 | Constant Leverage Certificate | `ConstantLeverageCertificate.daml` | Constant leverage factor compounded period-over-period across a rebalancing schedule (built from scratch) |

### 14 — Additional credit risk (`daml/Sspa/CreditRisk/`)

Every product here takes a category 11/12/13 product's claims and wraps each one with
`Util.daml`'s `untilCreditEvent` -- active only until a credit event of a third-party reference
entity occurs, reusing `Daml.Finance.Claims.V3.Util.Builders.createCreditEventPaymentClaims` (and,
for products with a periodic coupon, `createConditionalCreditFixRatePaymentClaims`) to add the
one-off `(1 - recoveryRate) * notional` recovery payment paid out if/when it does.

| SSPA code | Product | Module | Structure |
|---|---|---|---|
| 1400 | Credit Linked Notes | `CreditLinkedNote.daml` | A synthetic corporate bond: fixed coupon + principal, both credit-event-conditional; no equity underlying |
| 1410 | Conditional Capital Protection Note with additional credit risk | `ConditionalCapitalProtectionNote.daml` | 1100 (protected principal + call), credit-event-conditional |
| 1420 | Yield Enhancement Certificate with additional credit risk | `YieldEnhancementCertificate.daml` | 1220 (fixed-coupon bond + short put), credit-event-conditional |
| 1430 | Participation Certificate with additional credit risk | `ParticipationCertificate.daml` | 1300 (plain tracker), credit-event-conditional |

## Architecture

Every from-scratch instrument follows the same shape (mirroring how `daml-finance`'s own
`Instrument.StructuredProduct.V0` package is built):

- A `template Instrument` implementing:
  - `Daml.Finance.Interface.Claims.V4.Claim.I` — `getClaims` returns the product's payoff as a
    list of tagged [contingent claims](https://github.com/digital-asset/daml-finance) trees
    (`Zero`/`One`/`Give`/`And`/`Or`/`Scale`/`When`/`Until`/`Cond`/...), built by composing
    `Daml.Finance.Claims.V3.Util.Builders` functions (vanilla/barrier options, fixed-rate coupons,
    FX-adjusted principal) with a small amount of product-specific glue in each category's
    `Util.daml`.
  - `Daml.Finance.Interface.Instrument.Base.V4.Instrument.I` — the generic instrument identity
    (`InstrumentKey`) that holdings reference.
  - `Daml.Finance.Interface.Claims.V4.Dynamic.Instrument.I` — lets the lifecycling engine version
    the instrument forward in time as events are processed.
  - `Daml.Finance.Interface.Util.V3.Disclosure.I` — observer management.
- A `template Factory` with an `Originate` choice that creates the `Instrument` and registers its
  by-key `Reference` (required by the lifecycling/claiming machinery, which addresses instruments
  by `InstrumentKey` rather than `ContractId`).

This is a **full lifecycle + settlement** integration, not just a payoff calculator: instruments
are actually lifecycled over time via `Daml.Finance.Claims.V3.Lifecycle.Rule.Evolve` (driven by
time-clock events and `NumericObservable` price fixings), the resulting `Effect`s are claimed
against real holdings via `Daml.Finance.Lifecycle.V4.Rule.Claim.ClaimEffect`, and the resulting
settlement `Batch` is actually settled (`Daml.Finance.Settlement.V4.Batch.Settle`), moving cash
between real `Account`/`Holding` contracts on-ledger. See `daml/Sspa/Test/` for worked end-to-end
examples.

## Building

This project uses [Nix flakes](https://nixos.wiki/wiki/Flakes) to provide the DAML SDK and
`daml-finance` dependency dars without requiring a separate manual `daml` install. If your nix
install doesn't already have flakes enabled globally, pass
`--extra-experimental-features "nix-command flakes"` on every command below (or add
`experimental-features = nix-command flakes` to your `nix.conf` once, and drop the flag).

Compile the project into a `.dar` (a pure, sandboxed build — no manual setup needed):

```console
$ nix build
```

The compiled `sspa-structured-products-0.1.0.dar` is written to `result/`.

For interactive development (running `daml studio`, `daml script`, `daml test`, editing files and
rebuilding repeatedly), enter a dev shell instead — this also gets you `daml`/`damlc` on `PATH`,
a `.lib/daml-finance/` directory populated with the exact `data-dependencies` dars `daml.yaml`
expects, and a best-effort compiled dar symlinked into `dist/` (rebuilt every time you re-enter the
shell; entering the shell always succeeds even if the project doesn't currently compile, so you
can fix a build error from inside it):

```console
$ nix develop
$ daml build
$ daml test        # runs the Daml Script test suite under daml/Sspa/Test/
```

Both paths pin the exact same DAML SDK (2.10.0) and `daml-finance` bundle (`sdk/2.10.0`) release
by content hash, fetched from their official GitHub releases
(`digital-asset/daml` and `digital-asset/daml-finance`) — no separate `daml` installation, and no
Artifactory/enterprise credentials, required.

## Disclaimer

This is a sample/reference implementation for illustrating how the SSPA Swiss Derivative Map©
taxonomy can be modeled on `daml-finance`. It is not affiliated with, endorsed by, or reviewed by
the Swiss Structured Products Association (SSPA), SIX, or Avaloq, and it does not constitute
investment advice, a decision basis for any investment, or a complete/audited implementation of
any real-world structured product. Product economics here are simplified for clarity and should
not be relied upon for pricing, risk, or legal purposes.
