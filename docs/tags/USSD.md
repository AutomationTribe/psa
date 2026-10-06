# USSD Tag — Deferred Feature Record

Status: Paused  
Paused: 2026-10-06  
Target: Post-version 1

## Last known work completed

- Defined the concept: an authorized person can initiate a safety alert from another phone using a USSD code, registered user's Safety ID and secure verification.
- Confirmed that USSD can create an incident but cannot retrieve GPS from an absent user's phone by itself.
- Identified possible caller-provided location, landmark/LGA entry and telecom cell-location integration subject to provider agreement.
- Identified the preferred launch route: integrate with an existing Nigerian licensed VAS/USSD aggregator rather than obtain a dedicated licence first.
- Captured deferred requirements in FR-090–093 and US-011.

## Current blockers

- No aggregator or mobile-network operator has been selected.
- Coverage, pricing, session behavior and caller-number availability are unverified.
- Identity, anti-abuse and emergency false-report controls are not finalized.
- Telecom-provided cell-location access is unverified.
- Regulatory, privacy and end-to-end operational review is incomplete.

## Next steps when resumed

1. Shortlist licensed aggregators covering MTN, Airtel, Glo and 9mobile; obtain technical documentation, pricing and test access.
2. Prototype the Safety ID/PIN flow, caller-location collection, fraud controls and operator-dashboard incident creation in a sandbox.
3. Run cross-network field tests and complete regulatory, privacy, security and operational approval before enabling the feature.

When the user enters `USSD`, report these three sections and any later recorded updates. Do not resume implementation automatically.
