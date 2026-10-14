# API design, part 1: identity and access (local draft, revision 3)

Status: **APPROVED by the founder on 2026-10-14 for the first Identity & Access feature only (scope below). Not implemented.**
Approved: D-A (RC-1: new requirement and stories for signup, verification, sign-in, renewal, sign-out - to be drafted for review), D-B (FD-2: passwordless one-time code to a verified phone or e-mail), D-C (RC-2 deferred to the next Identity feature), and the documented defaults FD-3, A-1 and TC-1..TC-9. Approved operations: startSignup, completeSignup, startLogin, completeLogin, refreshSession, logout, getCurrentUser, updateProfile. The other 8 operations (identifiers, staff sign-in) and RC-3, RC-4, RC-5, FD-4, FD-5 stay **draft/deferred**. Approval is not approval of any implementation; the preconditions in section 12 still apply.
Date: 2026-10-10 (revision 3; revision 1 had 26 operations, revision 2 removed 10)
Contract: [`openapi/identity-access.openapi.yaml`](openapi/identity-access.openapi.yaml) (16 operations)
Checks: [`tools/check_contract.py`](tools/check_contract.py), notes in [`README.md`](README.md)

Revision 3 gives every operation its exact supporting text, checks the draft against the requirements you named, corrects two
places where revision 2 cited a requirement for more than its text says (section 4), adds an impact summary for every proposed
requirement change, and marks every decision open, resolved or recommended. It invents no requirement and edits no approved one.

## 1. Sources and classification

| Short name | Document |
|---|---|
| FR / NFR / US | `docs/requirements/FUNCTIONAL_REQUIREMENTS.md`, `NON_FUNCTIONAL_REQUIREMENTS.md`, `USER_STORIES.md` (numbered) |
| Stage 6 | `docs/architecture/STAGE_6_ARCHITECTURE.md`, "Security boundaries". Cited by line as of this draft: L115 authentication, L116 authorization, L120 deletion, L122 dashboard sessions, L124 operator scope, L129 rate limits |
| Stage 7 | `docs/engineering/STAGE_7_ENGINEERING_STANDARDS.md` section 3 (API, validation, errors, idempotency) and section 5 (security) |
| Stage 8 | `docs/database/STAGE_8_DATABASE_DESIGN.md`: section 3 (Identity row), section 5 constraint 9, section 10 decision 1 (`S8-DEC1`) |
| `S6-SEC`, `S8-DEC1` | Short names used in the contract for the Stage 6 security boundaries and Stage 8 decision 1 |

Classes (contract field `x-support`):

1. **Explicitly required** (`EXPLICIT`) - a numbered FR/NFR states the capability.
2. **Implied by approved architecture/security** (`IMPLIED`) - no numbered FR states it, but approved architecture/security text (Stage 6, Stage 8) or NFR-031/NFR-033 implies it.
3. **Requires a proposed requirement change** (`CHANGE_REQUIRED`) - approved text allows the thing but nothing requires or defines it; kept in the draft only conditionally (`x-requirement-change`).
4. **Unsupported (removed)** - nothing approved supports it; removed from the contract. Section 5 gives the change that would restore it.

The reverted SOS slice is not a source and nothing here is taken from it.

## 2. Scope

Signup, login, identity verification, the signed-in person's account, identifiers and sign-out, and **staff sign-in only**
(because the dashboard cannot be used without it). Staff/account administration and session management beyond signing out are
removed. Later parts: trusted circle and family (including FR-008/FR-061 join flows and minor onboarding), trips, SOS, location,
notifications and push tokens, operator workflow, audio, subscriptions, partner API, account deletion flow, rescue PIN.

## 3. Operation audit (26 operations of revision 1)

References: requirement = exact supporting text; story = user story; architecture = approved design text.

| Operation | Classification | Requirement (exact text) | User story | Architecture / design reference | Result |
|---|---|---|---|---|---|
| `startSignup` | Explicitly required | FR-001 "A user shall create and verify an account using supported identity methods." NFR-033 | none (GAP-01). US-001 c3-4, US-007 c2 mention signing up *through a link* (later parts) | Stage 8 decision 1; Stage 6 L115 | kept |
| `completeSignup` | Explicitly required | FR-001; FR-002 "safety profile containing their name, verified phone number…" | none | Stage 8 section 3 Identity row | kept |
| `getCurrentUser` | Explicitly required | FR-002 "A user shall maintain a safety profile containing their name, verified phone number and optional information approved for emergency use." | none | Stage 6 L116 (authorization server-side; ids never permission); Stage 7 section 5 | kept |
| `updateProfile` | Explicitly required | FR-002 (name). Optional emergency information is undefined, so only `displayName` | none | V3 column grant: `psa_api` may update only `display_name` | kept |
| `startLogin` | Implied by approved architecture/security | NFR-033 "protect against account takeover…". **No numbered FR states sign-in** | none | Stage 6 L115 "Authentication and recovery use verified account channels, short-lived access credentials and revocable device sessions"; L129 limits on "login/OTP" | kept; RC-1 recommended |
| `completeLogin` | Implied by approved architecture/security | NFR-033; FR-009 (see section 4: system revokes sessions on deletion; not a sign-in rule) | US-016 c1 (revocation on deletion) | Stage 6 L115, L120 | kept; assumption A-1 |
| `refreshSession` | Implied by approved architecture/security | NFR-033 | none | Stage 6 L115 "short-lived access credentials" (a renewal path is a design choice, TC-3) | kept; RC-1 recommended |
| `logout` | Implied by approved architecture/security | NFR-033 | none | Stage 6 L115 "revocable device sessions" | kept; RC-1 recommended |
| `listIdentifiers` | Implied by approved architecture/security | FR-002 (verified phone number is part of the profile). The same masked list is already inside `getCurrentUser` | none | Stage 8 decision 1 | kept (redundant with `getCurrentUser`; candidate to drop at implementation) |
| `startIdentifierAdd` | Requires a proposed requirement change | FR-001 covers creating and verifying *an account*; nothing says a second identifier is added later | none (US-001 c4, US-007 c2 verify an *invited* identity, later parts) | Stage 8 decision 1 "An account may have verified phone and email identifiers" | kept, conditional on RC-3 |
| `completeIdentifierAdd` | Requires a proposed requirement change | same | none | same | kept, conditional on RC-3 |
| `startStaffLogin` | Implied by approved architecture/security | NFR-031 "separate user, family-head, operator, supervisor and partner permissions"; NFR-033 | US-010 assumes a signed-in operator, defines no sign-in | Stage 6 L115 "Operator and administrator access requires MFA"; L122 cookie sessions + CSRF | kept; RC-4 recommended |
| `completeStaffFirstFactor` | Implied by approved architecture/security | same | US-010 | same | kept; RC-4 recommended |
| `completeStaffMfa` | Implied by approved architecture/security | NFR-031 | US-010 | Stage 6 L115 (MFA) | kept; RC-4 recommended |
| `getStaffSession` | Implied by approved architecture/security | NFR-031; FR-102 "Only an assigned operator or authorized supervisor shall access full incident details." (the dashboard needs the role) | US-010 | Stage 6 L124 "Operator access is scoped to assigned incidents or supervisor duties." | kept; RC-4 recommended |
| `logoutStaff` | Implied by approved architecture/security | NFR-033 | none | Stage 6 L122 | kept; RC-4 recommended |
| `listSessions` | Unsupported (removed) | none. FR-007 concerns *sharing permissions and contact access*, not sessions | none | Stage 6 L115 says only that sessions are revocable | removed; RC-2 |
| `revokeSession` | Unsupported (removed) | none | none | same | removed; RC-2 |
| `revokeOtherSessions` | Unsupported (removed) | none | none | same | removed; RC-2 |
| `startMfaEnrollment` | Unsupported (removed) | none. MFA is required (Stage 6) but nothing says how factors are enrolled or recovered | none | Stage 6 L115 | removed; RC-4 |
| `completeMfaEnrollment` | Unsupported (removed) | none | none | same | removed; RC-4 |
| `stepUpStaff` | Unsupported (removed) | none | none | Stage 6 L115 "privileged actions use step-up verification where appropriate" - no privileged staff action remains in scope | removed; RC-5 |
| `listStaff` | Unsupported (removed) | none. "Actors" and the dashboard introduction mention administering access, but no numbered FR/US does | none | Stage 8 section 8 | removed; RC-5 |
| `setOperatorProfile` | Unsupported (removed) | none | none | V3 function `set_operator_profile` exists; authority rule D5 is open (deferred) | removed; RC-5 |
| `setAdministratorProfile` | Unsupported (removed) | none | none | V3 `set_admin_profile`; D4 open (deferred) | removed; RC-5 |
| `setUserAccountStatus` | Unsupported (removed) | none. The 2026-10-09 policy says only that suspension must not block SOS | none | V3 `set_user_account_status`; D8 open (deferred) | removed; RC-5 |

Totals: **4 explicitly required, 10 implied by approved architecture/security, 2 requiring a proposed requirement change,
10 unsupported (removed)**. The contract check fails if this table and the contract disagree.

## 4. Check against the named requirements and Stage 6

| Requirement (exact text) | What the draft does | Verdict |
|---|---|---|
| **FR-001** "A user shall create and verify an account using supported identity methods." | `startSignup` + `completeSignup`: account created only after the identifier is verified by a one-time code | Consistent. "Supported identity methods" is undefined, so the method is a founder decision (FD-2) |
| **FR-002** "…safety profile containing their name, verified phone number and optional information approved for emergency use." | Display name captured at signup and editable; verified phone is in the account; no emergency-information field | Partly covered: the optional information is undefined (gap) |
| **FR-008** non-member who joins "through either link and verifies the invited identity shall be automatically linked to the originating trusted circle" | **Not covered by this part.** No join token is accepted here. The joining step is an operation of the trusted-circle part, run after signup. This part supplies what it needs: a verified, normalised identifier on the new account to compare with the invited one. Signup responses are uniform, which matches Stage 8 constraint 9 ("A public response must not reveal whether an account exists") | Interface only. Open for the contacts part: the person must be able to sign up with the *invited* identifier; behaviour if they use a different one is that part's to define |
| **FR-009** "On account deletion, the system shall revoke sessions and remove the user from family memberships immediately." | Revocation is an **action of the deletion workflow** (the worker may update `device_session`), not an operation here. The contract's obligations: a revoked session's access credential stops working on the next request (credentials are checked against the session record, not accepted until expiry) and cannot be refreshed; sign-in is refused for a DELETED account. **Not specified by FR-009:** when "deletion" begins (request or completion), and whether sign-in is refused while deletion is pending; the approved rule is that deletion waits for active incidents | Consistent for what the text says. Assumption **A-1**: a DELETION_PENDING account cannot sign in. Open for the deletion part |
| **FR-061** invitee "shall be told to sign up; after completing onboarding through the invitation and accepting the disclosed location consent, the system shall add them to the family immediately" | **Not covered by this part**, same interface as FR-008 (family part; consent capture is the family/consent part) | Interface only |
| **FR-067** "A minor account shall be created only through an adult family-head invitation and shall belong to an active family circle." | Public signup creates ordinary accounts; there is no minor path and no age field. FR-067 does not require signup to check age, so none is added. Guardian authority and child-consent rules stay open under FR-069 | Consistent; minor eligibility is not an open decision |
| **NFR-031** "Access shall follow least privilege, with separate user, family-head, operator, supervisor and partner permissions." | Separate credentials (bearer for people, cookie session for staff); roles read from the database on every request; family-head and partner permissions are not in this part | Consistent for user/operator/supervisor/administrator |
| **NFR-033** "…protect against account takeover, forged alerts, replayed requests, insecure direct object access, injection, abusive location queries and excessive automated requests." | Single-use codes with an attempt limit and rate classes (takeover, replay, excessive requests); refresh reuse revokes the session; every string bounded, unknown fields rejected (injection); no object ids in the remaining paths (the removed session ids were the only ones). Account-enumeration resistance is **not in NFR-033's text**: it extends the approved join-link rule (Stage 8 constraint 9) to authentication as a technical default (TC-5) | Consistent; enumeration resistance is a design default, not a requirement |
| **Stage 6 L115** "Authentication and recovery use verified account channels, short-lived access credentials and revocable device sessions. Operator and administrator access requires MFA; privileged actions use step-up verification where appropriate." | Codes go only to verified channels; short-lived access + rotating refresh; sessions revocable server-side; staff sign-in has a second factor. "Recovery uses verified channels": a person who still controls one verified channel signs in again; losing every channel is **not covered** (FD-4). Step-up removed with the administration operations | Consistent; MFA enrolment/recovery and step-up are not defined |
| **Stage 6 L122** "Dashboard sessions use secure HTTP-only same-site cookies, CSRF protection and a restrictive content security policy. Mobile apps contain no shared backend credential." | Staff cookie `__Host-` HttpOnly Secure SameSite=Strict + synchronizer CSRF token; mobile uses per-session bearer credentials. CSP is a dashboard response header, outside this API | Consistent |

Corrections to revision 2: it cited FR-009/US-016 as if they required sign-in refusal for deleting accounts - they only say the
system revokes sessions on deletion (above); and it described recovery as "no approved process" although Stage 6 L115 says
recovery uses verified account channels (only the total-loss case is open).

## 5. Proposed requirement changes (nothing here edits an approved requirement)

Framework rule 3: each needs an impact analysis before implementation. Summaries below; wording is a proposal for FD-1.

| ID | Proposed change | Status of the operations |
|---|---|---|
| RC-1 | New FR + stories: a registered user signs in on a device by proving control of a verified identifier, stays signed in for a bounded period (renewal), and signs out; signup and verification get a user story and acceptance criteria (none exist for FR-001/FR-002) | Clarification: the 4 operations are already implied (class 2) |
| RC-2 | New FR + story: a user sees the devices signed in to their account and signs any of them out | Restores `listSessions`, `revokeSession`, `revokeOtherSessions` |
| RC-3 | Amend FR-001/FR-002: a user may verify one phone number and one e-mail address on the account; adding the second requires verification and a recent sign-in | Needed for the 2 `CHANGE_REQUIRED` operations |
| RC-4 | New FR: operators, supervisors and administrators sign in to the dashboard with a second factor; staff accounts are created and their second factor enrolled and recovered by a defined process (FD-5) | Clarification for the 5 staff operations (class 2); restores the 2 enrolment operations |
| RC-5 | New FR + stories: administrators grant, suspend and reactivate operator, supervisor and administrator access and suspend or reactivate accounts, audited, with a fresh second-factor check; supervisors manage operators | Restores `listStaff`, the 3 administration PUTs and `stepUpStaff` |

**Impact summaries** (R=requirements/stories, D=data, A=API, B=backend, F=frontend/mobile, S=security, T=tests, Doc=documentation):

- **RC-1.** R: one FR; stories for signup, verification, sign-in, renewal, sign-out with criteria. D: authentication challenges and a richer session record (GAP-DB-01, GAP-DB-02). A: none new (4 operations drafted). B: authentication module, rate limiter, code-delivery provider interface (fake in Local). F: sign-in screens; secure credential storage; an expired credential must not block queued offline SOS delivery (FR-048) - settled in the SOS part. S: takeover, SIM swap, brute force, enumeration; security review. T: single-use/expiry/attempts, immediate revocation, rate limits, contract tests. Doc: stories, API doc, runbook for code-delivery failure.
- **RC-2.** R: one FR + story. D: session record needs device label/platform/last used (GAP-DB-02). A: restores 3 operations. B: session service. F: "signed-in devices" screen. S: object-level access (another person's session id must look like "not found"). T: foreign and unknown ids, revoke current, idempotent revoke. Doc: story, API doc.
- **RC-3.** R: amend FR-001/FR-002 + story. D: `user_identifier` already allows phone and e-mail, one verified owner each (no change); recycled-number handling is open. A: 2 operations. B: challenge flow reused. F: add phone/e-mail screen. S: uniform response when the identifier is verified elsewhere; recent-sign-in rule. T: verified-elsewhere case, recent sign-in. Doc: story.
- **RC-4.** R: one FR + staff sign-in story (extends US-010). D: second-factor storage (GAP-DB-03), staff session kind (GAP-DB-02). A: 5 operations kept + 2 enrolment operations restored. B: cookie session, CSRF, MFA. F: dashboard sign-in and second-factor pages; CSP. S: MFA strength, session fixation, cookie flags; staff recovery (FD-5). T: CSRF, cookie attributes, role re-read per request, fail-closed when no factor. Doc: staff onboarding/recovery runbook.
- **RC-5.** R: one FR + stories for staff and account administration. D: V3 functions exist (`set_operator_profile`, `set_admin_profile`, `set_user_account_status`) with the provisional authority rules D4/D5/D8 - **deferred, not reopened**. A: restores 5 operations. B: needs the admin-plane placement decision (DB-003, deferred). F: administration screens. S: step-up, self-change, last-administrator protection. T: authority matrix, audit events. Doc: stories, authority decision record.

## 6. Operations in the contract (16)

All paths are under `/api/v1`. Rate class names a bucket; numbers are TC-4.

| Operation | Method and path | Credential | Rate class | Class | Open items |
|---|---|---|---|---|---|
| startSignup | POST `/auth/signup/challenges` | none | AUTH_CHALLENGE | Explicit | FD-2, TC-2 4 5 6 7 |
| completeSignup | POST `/auth/signup/verifications` | none | AUTH_VERIFY | Explicit | FD-2, TC-2 3 4 7 8 |
| getCurrentUser | GET `/me` | bearer (any scope) | ACCOUNT_READ | Explicit | |
| updateProfile | PATCH `/me` | bearer (FULL scope) | ACCOUNT_WRITE | Explicit | TC-7 |
| startLogin | POST `/auth/login/challenges` | none | AUTH_CHALLENGE | Implied | FD-2, TC-2 4 5 |
| completeLogin | POST `/auth/login/verifications` | none | AUTH_VERIFY | Implied | FD-2, FD-3, A-1, TC-2 3 4 8 |
| refreshSession | POST `/auth/token/refresh` | refresh credential in body | AUTH_VERIFY | Implied | FD-3, TC-3 |
| logout | POST `/auth/logout` | bearer | SESSION_MANAGEMENT | Implied | |
| listIdentifiers | GET `/me/identifiers` | bearer | ACCOUNT_READ | Implied | |
| startIdentifierAdd | POST `/me/identifiers/challenges` | bearer (FULL) | AUTH_CHALLENGE | Change required (RC-3) | FD-2, TC-2 4 5 6 |
| completeIdentifierAdd | POST `/me/identifiers/verifications` | bearer (FULL) | AUTH_VERIFY | Change required (RC-3) | FD-2, TC-2 4 6 |
| startStaffLogin | POST `/staff/auth/challenges` | none | STAFF_AUTH | Implied | FD-2, FD-5, TC-2 4 5 9 |
| completeStaffFirstFactor | POST `/staff/auth/verifications` | none | STAFF_AUTH | Implied | FD-5, TC-2 4 9 |
| completeStaffMfa | POST `/staff/auth/mfa/verifications` | pre-MFA cookie + CSRF | STAFF_AUTH | Implied | FD-5, TC-4 9 |
| getStaffSession | GET `/staff/session` | staff cookie | ACCOUNT_READ | Implied | TC-9 |
| logoutStaff | POST `/staff/auth/logout` | staff or pre-MFA cookie + CSRF | SESSION_MANAGEMENT | Implied | TC-9 |

**Authorization.** What a person may do is read from the database on every request, not from a credential claim: a person is an
ACTIVE or SUSPENDED `user_account`; staff roles come from ACTIVE `operator_profile` / `admin_profile` rows on an ACTIVE account.
Deny by default; a suspended account gets `accessScope = SOS_ONLY` (FD-3). **Flows.** *Signup:* `startSignup` always answers `202`
with a `challengeId` (a decoy when nothing was sent); a code goes out only if the identifier is free; `completeSignup` creates, in
one transaction, the account, the verified primary identifier, the device registration and the first session. *Login:* same two
steps; every failure is the same `422 CHALLENGE_INVALID`. *Staff:* first factor opens a pre-MFA cookie usable only for the second
factor; a staff account with no provisioned second factor cannot sign in (fail closed) until RC-4 defines provisioning.

**Conventions (TC-1).** JSON only; lowerCamelCase; UUIDs; RFC 3339 UTC; `/api/v1`; unknown request fields rejected; every string
bounded; one error envelope `{code, message, correlationId, details[]}` with a closed `code` enum; `X-Correlation-Id` on every
response; `Cache-Control: no-store` on credential-bearing responses; codes, tokens, second-factor responses and CSRF tokens never
logged. Errors: `VALIDATION_FAILED` 400; `UNAUTHENTICATED` 401 (one body for every credential problem); `FORBIDDEN` and
`CSRF_INVALID` 403; `CHALLENGE_INVALID` 422 (any challenge, code or eligibility problem); `AUTHENTICATION_FAILED` 422 (second
factor); `RATE_LIMITED` 429 + `Retry-After`; `PAYLOAD_TOO_LARGE` 413; `UNSUPPORTED_MEDIA_TYPE` 415; `INTERNAL_ERROR` 500;
`SERVICE_UNAVAILABLE` 503. **Idempotency:** Stage 7's key is for safety-critical create/retry operations; none here is one (TC-8).

## 7. Database dependencies for the Database Architect review (no migration is changed)

These four gaps must be reviewed by the `database-architect` before any implementation. They are dependencies of this draft, not
changes made by it. The unresolved V3 findings stay deferred Pilot-readiness items and are not reopened.

| ID | Missing from the current schema (V1-V3) | Needed by | Review question |
|---|---|---|---|
| GAP-DB-01 | A table for authentication challenges: purpose, target identifier, code hash (never the code), attempt count, expiry, consumed time; and a place for the pending signup (display name) before the account exists | the 4 challenge-start and 4 verify operations | Shape, retention, who may write (`psa_api` only), cleanup without a runtime DELETE grant |
| GAP-DB-02 | `device_session` has a single `token_hash` and `expires_at`. Missing: a separate refresh credential with rotation family and reuse detection, session scope (FULL/SOS_ONLY), session kind (mobile vs staff cookie), last-used/idle time, MFA-verified time, CSRF token hash, link to `registered_device` | refresh, immediate revocation, staff session, FD-3 | Extend or add a table; interaction with the worker's session revocation at deletion (FR-009) |
| GAP-DB-03 | Storage for second factors and recovery material (encryption and key ownership are open in Stage 6) | `completeStaffMfa` (and enrolment if RC-4 is approved) | Where secrets live, encryption, rotation |
| GAP-DB-04 | A shared place for rate-limit counters. Redis is deliberately not approved (Stage 5): database counters, an edge/provider limiter, or a new technology decision (framework rule 14) | every rate class | Choice and cost of database-backed counters on the hot path |

## 8. Decisions

**Resolved**

- **R-1 Minor eligibility - resolved by FR-067** (see section 4). Guardian verification and child-consent rules remain open under FR-069; not part of this draft.
- **R-2 Suspension and deletion policy - resolved (founder, 2026-10-09):** suspension must not block SOS or interrupt alerts; deletion waits until the user's active incidents are resolved; existing incidents continue.

Statuses below: **open** = needs the founder's answer; **recommended** = a default is proposed and nothing further is needed unless you object.

| ID | Topic | Kind | Status | Recommended default |
|---|---|---|---|---|
| FD-1 | Approve, change or reject RC-1..RC-5 | Founder | **open** | Approve RC-1..RC-4, defer RC-5 to the admin-dashboard part |
| FD-2 | Credential model | Founder | **open** | Passwordless one-time code to a verified phone (primary) or e-mail |
| FD-3 | Capability of a suspended account | Founder (principle resolved by R-2) | **recommended** | Sign in with `SOS_ONLY` scope: raise SOS, see own account, sign out; nothing else |
| FD-4 | Total loss of every verified channel | Founder | **open** (not needed to approve this draft) | No self-service recovery in v1; design an audited, support-assisted process later |
| FD-5 | Staff provisioning and recovery (only if RC-4 approved) | Founder (operational policy) | **open** | A supervisor or administrator requests, an administrator approves, recovery only by an administrator with a fresh check, all audited |
| A-1 | A DELETION_PENDING account cannot sign in | Assumption pending the deletion part | **recommended** | Keep until the deletion flow defines it (FR-009 is silent) |
| TC-1 | API conventions | Technical | recommended | Section 6 |
| TC-2 | One-time-code parameters and delivery | Technical | recommended | 6 digits, 10 minutes, single use, 5 wrong attempts, 60 s resend cooldown; internal provider interface, fake in Local |
| TC-3 | Token model | Technical | recommended | Opaque tokens checked against the session record on every request (so revocation is immediate, FR-009); access 15 min; single-use rotating refresh 30 days with reuse detection; session cap per person |
| TC-4 | Rate limits and lockouts | Technical | recommended | Per identifier, per source address and per challenge; delay-then-block; start low (for example 5 code requests per identifier per hour) and tune from the pilot |
| TC-5 | Anti-enumeration | Technical | recommended | Uniform responses and timing target; no notice SMS to an existing holder at first |
| TC-6 | Identifier rules | Technical | recommended | E.164, Nigeria (+234) first (Product Definition); e-mail lower-cased; one phone and one e-mail; adding an identifier needs a sign-in within 15 minutes |
| TC-7 | Profile and signup field bounds | Technical | recommended | Display name 1-100 characters; no emergency-information field until defined |
| TC-8 | Idempotency of authentication flows | Technical | recommended | No `Idempotency-Key`; a lost response means requesting a new code |
| TC-9 | Staff session mechanics and second-factor type | Technical | recommended | `__Host-` cookies, SameSite=Strict, synchronizer CSRF token; idle 60 min, absolute 12 h with a warning before expiry; authenticator-app codes (TOTP) |

### FD-1 Approve, change or reject the requirement changes RC-1 to RC-5
Each removed operation stays removed unless its change is approved; approving also means writing the missing stories.

### FD-2 Credential model
FR-001 says only "supported identity methods". Passwordless one-time code is the only reading consistent with Stage 6 "verified account channels". You accept: SMS cost per sign-in, SIM-swap and recycled-number exposure, and dependence on an SMS/e-mail provider that is not selected.

### FD-3 What a suspended account can do
Principle settled by R-2. Confirm the minimal scope (default `SOS_ONLY`).

### FD-4 Total loss of every verified channel
Stage 6 says recovery uses verified account channels, which covers anyone who still controls one. The total-loss case has no approved process.

### FD-5 Staff provisioning and recovery
Who may become staff, how they are vetted, how the second factor is enrolled and recovered.

### TC-1 API conventions
Section 6. Also fills the blank API-conventions field of the project profile once approved.

### TC-2 One-time-code parameters and delivery
Defaults in the table; delivery through an internal provider interface.

### TC-3 Token model
Defaults in the table. Immediate revocation (FR-009) rules out accepting self-contained tokens until expiry.

### TC-4 Rate limits and lockouts
Limit per identifier, source and challenge; challenge classes also limit per identifier because code delivery costs money and can harass a number.

### TC-5 Anti-enumeration
Extends the approved join-link rule to authentication.

### TC-6 Identifier rules
Defaults in the table.

### TC-7 Profile and signup field bounds
Defaults in the table.

### TC-8 Idempotency of authentication flows
Defaults in the table.

### TC-9 Staff session mechanics and second-factor type
Defaults in the table; the dashboard origin is the only CORS origin.

Unchanged and not decisions of this part: the `psa_admin` credential placement (DB-003), the authority rules D1-D8, and every other V3 database/security finding - deferred Pilot-readiness items.

## 9. API coverage map

| Requirement / reference | Operations | Note |
|---|---|---|
| FR-001 | startSignup, completeSignup (explicit); startIdentifierAdd, completeIdentifierAdd (conditional, RC-3) | |
| FR-002 | completeSignup, getCurrentUser, updateProfile, listIdentifiers | optional emergency information undefined |
| FR-008, FR-061 | none | interface only: verified normalised identifiers; join/accept operations belong to the contacts and family parts |
| FR-009 | completeLogin, refreshSession (refuse revoked/deleted) | revocation itself is a deletion-workflow action; A-1 |
| FR-067 | startSignup (note) | no minor path; FR-069 open |
| FR-102 | getStaffSession | role source only |
| NFR-031 | all staff operations; bearer vs cookie separation | |
| NFR-033 | all challenge, verify and refresh operations; rate classes | enumeration resistance is TC-5 |
| Stage 6 L115 | startLogin, completeLogin, refreshSession, logout, staff operations | recovery total loss = FD-4 |
| Stage 6 L122 | staff operations | CSP outside this API |
| Stage 8 decision 1 | listIdentifiers, startIdentifierAdd, completeIdentifierAdd | |
| US-010, US-016 | staff operations (assumed), completeLogin | no story for signup or sign-in (GAP-01) |

## 10. Requirement coverage gaps

- No user story or acceptance criteria exist for signup, sign-in, verification, identifiers, sign-out or staff sign-in. Until RC-1/RC-3/RC-4 are approved, the criteria are the behaviours in this document: proposals, not approved criteria.
- FR-002: optional emergency information is undefined.
- FR-009: when deletion begins, and whether sign-in is refused while pending, is unspecified (A-1).
- FR-008 and FR-061 join flows, consent capture at join, and minor onboarding (FR-067, FR-069) are for later parts.
- Signup consent: no list of consents or policy-version registry (FR-005 covers device permissions only); legal review pending (NFR-036).
- No SMS or e-mail provider selected (Stage 5): delivery cost, sender identity and reliability unspecified.
- FR-115: practice/live staff access is "access-controlled separately" but `operator_profile` has no such attribute.
- Not in this part: FR-027, FR-040, FR-100 to FR-109, FR-110 to FR-116, FR-120 to FR-125.

## 11. What the contract check proves and does not prove

In plain language: it reads the contract and the project's own documents and confirms the paperwork is consistent. It proves the
file is valid OpenAPI; that the audit table in section 3 and the contract list the same operations with the same class; that
every operation names a requirement that exists, an "explicitly required" one cites a numbered FR or NFR, and a "change required"
one names a requirement change defined in section 5; that each states its rate class, who may call it and the failures it can
return; that no dashboard state change lacks CSRF protection; that signup and sign-in questions answer the same whether or not an
account exists; that requests reject unknown or unbounded fields; that credential responses are `no-store`; that every error uses
one shape; that every decision it points to is written down; and that allowed values match the database. The fault tests show each
check can actually fail.

It does **not** prove the design is right or secure, that the requirements are fully covered, that any server behaves this way
(none exists), that mobile apps or the dashboard can use it, or that you approved it. A pass means "internally consistent".

## 12. Approval needed

Reply `APPROVE`, `MODIFY` (with changes) or `PAUSE`, and answer FD-1, FD-2, FD-5 (and FD-3 if you disagree with the default).
Approval would cover the conventions (TC-1) and the 16-operation contract as the basis for the next review steps. It would **not**
approve any implementation. Before implementation: approved requirement changes written as stories, a Database Architect review
of GAP-DB-01 to GAP-DB-04, and a Security review of the authentication design. Nothing is committed or published.
