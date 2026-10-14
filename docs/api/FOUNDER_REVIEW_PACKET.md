# Founder review packet - Identity & Access API, part 1 (revision 3, validated 2026-10-14)

Status: **APPROVED 2026-10-14 (founder reply `APPROVE`, taken as acceptance of the recommendations D-A, D-B, D-C and the listed defaults).** Full detail: `API_DESIGN_IDENTITY_ACCESS.md`
(section numbers below refer to it). Contract: `openapi/identity-access.openapi.yaml`. Nothing is implemented.

## 1. Validation (run 2026-10-14 in `~/dev/psa`)

Contract checker PASS (valid OpenAPI, 16 operations, audit table matches); deliberate-fault tests 23 caught / 0 missed; restored
status history identical to the backup (`cmp`, no output); framework project validation 98 passed / 0 failed. No defects were
found, so no file in the draft was changed. These prove internal consistency only (design doc section 11), not that the design
is right or secure.

## 2. Scope of the first feature

Signup, verification, login and sessions = the 8 operations below. Everything else in the draft is later work and needs no
decision now.

| Operation | Source (requirement / story / architecture) | Basis |
|---|---|---|
| startSignup, completeSignup | FR-001 "A user shall create and verify an account using supported identity methods."; FR-002; NFR-033. Story: none (gap). Stage 8 decision 1; Stage 6 L115 | Explicit |
| startLogin, completeLogin | NFR-033; no numbered FR states sign-in. Story: none (US-016 only covers revocation on deletion). Stage 6 L115 "verified account channels, short-lived access credentials and revocable device sessions"; L129 "login/OTP" rate limits | Implied |
| refreshSession, logout | NFR-033; no story. Stage 6 L115 "short-lived access credentials and revocable device sessions" | Implied |
| getCurrentUser, updateProfile | FR-002 "safety profile containing their name, verified phone number…"; no story. Stage 6 L116 | Explicit |

Account for the rest (full table: design doc section 3): 8 operations are later work (identifiers: 3, one needing RC-3; staff
sign-in: 5, implied by Stage 6 L115/L122 MFA and NFR-031); 10 were removed as unsupported by any approved text.

The central finding: **no approved story exists for signup, verification, login or sessions**, and no numbered FR states
sign-in. The behaviour is derived from NFR-033 and Stage 6, so it needs requirement text and stories before implementation.

## 3. Decisions that change product behaviour (only these)

| # | Decision | Recommendation | Impact |
|---|---|---|---|
| **D-A** | **RC-1: approve a new FR plus stories for signup, verification, sign-in, renewal and sign-out** (design doc section 5) | **APPROVE.** I then write the FR and stories for your review (stage gate). | Without it the first feature has no approved requirement or acceptance criteria (framework rule 1). Adds one FR and about five stories; no code change. |
| **D-B** | **FD-2: credential model.** FR-001 leaves "supported identity methods" undefined | **Passwordless one-time code** sent to a verified phone (primary) or e-mail; no passwords. It is the only model consistent with Stage 6 "verified account channels". | You accept: SMS cost on every sign-in; SIM-swap and recycled-number exposure; dependence on an SMS/e-mail provider that is not yet selected (Local uses a fake). A password model would add a credential store, reset flow and breach exposure, and a new recovery path. |
| **D-C** | **RC-2: can a user see their signed-in devices and sign one out remotely?** (3 removed operations) | **Defer to the next Identity feature**, not the first. | Without it, a lost or stolen phone keeps a valid session until it expires (30 days, rotating) unless support revokes it, which is a real risk for a safety app. Adding it later needs a session label/last-used column (GAP-DB-02) already required for sessions, so deferral does not force rework. If you consider lost-phone sign-out a v1 requirement, answer APPROVE for RC-2 now. |

Everything else is a documented default and needs no answer; each takes effect on `APPROVE` and you may object to any:

- **FD-3** suspended account signs in with `SOS_ONLY` scope (principle already settled by your 2026-10-09 decision).
- **A-1** a DELETION_PENDING account cannot sign in until the deletion flow says otherwise.
- **TC-1..TC-9** conventions, 6-digit code / 10 min / 5 attempts / 60 s cooldown, 15-minute opaque access token with a revocation check on every request, 30-day rotating refresh with reuse detection, rate limits, uniform responses (anti-enumeration), E.164 with Nigeria first, display name 1-100 characters, no idempotency key on auth flows.

## 4. Deferred, not needed for the first feature

RC-3 (second identifier), RC-4/FD-5 (staff sign-in, MFA provisioning and recovery), RC-5 (staff and account administration),
FD-4 (total loss of every verified channel). Defaults are in the design doc; they are decided when those features are scheduled.
The 8 staff and identifier operations stay in the draft but are not approved by an `APPROVE` of the first feature unless you
say so. V3 findings stay deferred Pilot-readiness blockers.

## 5. Before implementation starts (after your answers)

1. Write the approved FR and stories (D-A) and obtain your approval.
2. Database Architect review of **GAP-DB-01** (authentication challenges) and **GAP-DB-02** (refresh credential, scope, session kind) plus **GAP-DB-04** (rate-limit counters, no Redis approved: needs a recorded decision, framework rule 14). GAP-DB-03 (second factors) is not needed for this feature.
3. Security review of the authentication design (code handling, token model, enumeration).
4. Open product input needed later, not now: SMS/e-mail provider selection.

## 6. Reply needed

`APPROVE`, `MODIFY` or `PAUSE`, with an answer to **D-A, D-B, D-C** (or "accept recommendations"). Nothing is committed.
