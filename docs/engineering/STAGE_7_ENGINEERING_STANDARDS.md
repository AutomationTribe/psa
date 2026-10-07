# Stage 7 — Engineering Standards

Status: Founder-approved engineering baseline  
Date: 2026-10-07  
Applies to: Local and Pilot environments; Kotlin/Spring Boot backend, native Android/iOS apps and React/Next.js dashboard

## 1. Purpose and authority

These standards turn the approved product requirements, high-criticality profile, technology choices and Stage 6 architecture into consistent implementation rules. Safety-related behavior must remain traceable to an approved requirement or decision. If a standard conflicts with an approved product or architecture decision, stop and resolve the conflict before implementation.

This document does not set unmeasured service-level targets, supported OS versions, provider contracts or legal conclusions. Record those as decisions and validate them before the affected release gate.

## 2. Code readability and structure

- Use the approved Senior readability profile: abstractions are allowed when they isolate a real policy, boundary or repeated behavior; keep safety-critical flows explicit and easy to follow.
- Organize backend code by product module and keep HTTP, application, domain and persistence concerns distinct. Modules own their tables and expose explicit interfaces; no cross-module table writes.
- Keep Android and iOS platform behavior native. Share API contracts through OpenAPI-generated clients, not by hiding platform-specific permission, background, location or audio behavior.
- Organize dashboard code by feature and user permission boundary. Reuse accessible components for repeated interaction patterns.
- Prefer small functions with explicit names, typed inputs/outputs and visible failure paths. Avoid hidden global state, broad catch-all handlers and implicit behavior in critical workflows.
- Use immutable values by default. Mutability is permitted when it makes state transitions clearer and is protected by a defined owner.
- Name types and fields after the product domain. Avoid ambiguous names such as `data`, `status`, `manager` or `process` when a domain-specific term is available.
- Document non-obvious safety decisions and constraints; do not comment code by restating what the code already says.

## 3. API, validation and errors

- OpenAPI is the contract for backend HTTP APIs. Every endpoint defines authentication, authorization, request validation, response shape, error cases and idempotency behavior where applicable.
- Validate all untrusted input at the API boundary and again at trust boundaries such as provider callbacks. Apply server-side object authorization on every read and write.
- Use stable machine-readable error codes and plain, non-sensitive user messages. Never expose stack traces, SQL, credentials, internal provider payloads or another user's data.
- Represent incident, location, notification and evidence states with explicit types/enums and valid transitions. Reject invalid transitions; do not silently coerce state.
- All safety-critical create/retry APIs accept an idempotency key and bind it to the principal, operation and canonical request payload. Replays return the original result; key reuse with a different payload is rejected and audited.
- Keep provider adapters behind internal interfaces. Normalize provider outcomes without erasing the distinction between accepted, delivered, acknowledged, failed and unknown.
- Use versioned contracts when a change is incompatible. Generate or validate client types in CI; do not hand-maintain duplicated API schemas.

## 4. Data, time and migrations

- Store instants in UTC; retain the original timezone and intended local time where a user-scheduled check-in needs them.
- Store location capture time, server receipt time, source, reported accuracy and freshness classification separately. Preserve uncertain device timestamps as untrusted evidence.
- Use transactions for coupled state changes, especially incident creation with outbox records and state changes with audit events.
- Use database constraints for invariants that must survive concurrent requests. Application checks alone are insufficient for uniqueness or referential rules.
- Migrations are versioned, reviewed and forward-compatible. Use expand/migrate/contract for changes that span deployed code versions; avoid destructive migration in the same release that stops using the old schema.
- Migration jobs use a separate credential from application runtime. Runtime roles cannot create schemas, alter tables or bypass application authorization controls.
- Queries on location/event history must use bounded result sizes, indexes and retention-aware access patterns. Do not load unbounded history into memory.
- Data deletion and retention changes are auditable and must account for database rows, object storage, exports and derived copies.

## 5. Security, privacy and abuse controls

- Apply least privilege at user, family, operator, supervisor, administrator and partner boundaries. Deny by default; identifiers are never authorization.
- Do not store passwords, rescue PINs, access tokens or provider secrets in plain text. Secrets must not enter source control, mobile binaries, client-visible configuration, analytics or logs.
- Keep sessions revocable. Protect dashboard cookies with secure, HTTP-only and same-site settings, plus CSRF defenses for state-changing requests.
- Rate-limit login/OTP, SOS creation, location queries, PIN attempts, invitations, callbacks and other abuse-sensitive operations. Record security-relevant outcomes without recording secret values.
- Precise locations and audio are sensitive data. Collect only for an active approved purpose, limit access, audit access, and apply approved retention/deletion policy.
- Use private object storage and short-lived, narrowly scoped URLs for audio/evidence. Authorize before issuing each URL and audit issuance and access where available.
- Escape/encode output for its context, use parameterized database access, enforce content-type and size limits, and validate callback signatures and replay windows.
- Threat-model high-risk changes before implementation, including location sharing, family/guardian access, SOS cancellation, audio, partner APIs and operator tools. Resolve coercive-control and duress behavior before enabling affected capabilities.
- Keep practice incidents visibly distinct and prevent practice routing from contacting real authorities. A practice/live mode must not be changeable after creation.

## 6. Mobile platform behavior

- Treat Android and iOS location/background behavior as separate implementations with separate evidence. Do not claim a common update frequency or guaranteed background execution.
- Request only permissions needed for a user-enabled feature. Explain why background location, microphone or notifications are needed and provide clear state when permission is unavailable or revoked.
- Use OS-supported location and background mechanisms, adapt sampling to active mode and battery, and make capture freshness visible. Avoid tight polling loops.
- Persist SOS metadata locally before retrying transmission. Use encrypted bounded queues and stable idempotency keys; prioritize SOS metadata over audio transfer.
- Show whether an event is stored on-device, received by the server, accepted by a provider, delivered where evidence exists, and acknowledged by a human. Never report success based only on a local attempt.
- Audio recording requires explicit permission and an approved active SOS state. Test interrupted recording, permission revocation, storage exhaustion, upload retry and deletion behavior.
- Test supported devices across permission, OS background restriction, app termination/restart, reboot, low battery, weak/no network and location-service-disabled conditions. Record device model, OS version and configuration with test evidence.

## 7. Logging and observability

- Use structured logs with timestamp, service, environment, severity, correlation ID and safe event identifiers.
- Metrics and traces must distinguish device capture, server receipt, durable commit, provider attempt/result, operator visibility, contact acknowledgement and operator acknowledgement.
- Never log passwords, tokens, rescue PINs, audio, full provider secrets or unnecessary precise coordinates. Use redaction tests for sensitive fields.
- Include environment and practice/live classification in operational views and telemetry labels without placing personal data in metric labels.
- Instrument failures and queue age, not just request success. Alert thresholds and service targets require measured pilot evidence and an approved operating owner.
- Health/readiness checks must not expose personal or security-sensitive data. Readiness reflects the ability to durably persist incident and outbox work.

## 8. Testing and review

- Required layers: unit tests for domain rules; API/integration tests against disposable PostgreSQL/PostGIS; contract tests for OpenAPI/provider adapters; UI/E2E tests for critical journeys; and real-device tests for mobile background/location/audio behavior.
- Every critical state transition has positive, negative, retry, concurrency and authorization tests.
- Time-dependent logic uses a controllable clock. Scheduler tests cover worker restart, overdue work, duplicate execution, timezone changes and concurrent check-in/cancel operations.
- Failure tests cover database/provider outage, ambiguous timeout, duplicate callback, queue backlog, full device storage, offline capture and reconnection.
- Test data is synthetic in Local. Pilot practice tests use explicit practice routing and must never access Pilot live incident data or invoke live authority escalation.
- Critical changes receive independent review of requirements traceability, authorization, migrations, failure behavior, tests, observability and rollback steps.
- Define risk-based coverage thresholds before implementation; coverage percentage alone does not establish safety or correctness.
- Do not mark work complete until the relevant tests have run and their results are recorded in `docs/PROJECT_STATUS.md`.

## 9. Dependencies, configuration and release

- Pin dependency versions and use lockfiles. Review ownership, maintenance activity, license, security advisories, transitive dependencies and mobile/runtime impact before adoption.
- Remove unused dependencies. Prefer platform/framework capabilities over adding libraries to critical paths without a clear need.
- Run formatting, lint, static analysis, secret scanning, dependency vulnerability checks, tests, OpenAPI compatibility checks and container scans in CI before merge.
- Use separate Local and Pilot credentials, databases and provider configuration. Never copy Pilot data or secrets into Local.
- Store configuration outside source code and validate required values at startup. Fail closed when a safety-critical setting is absent or invalid.
- Deploy each approved feature slice to Pilot only after required CI checks, migration review, rollback planning and smoke testing. Keep incomplete features disabled.
- Enabling a capability for live monitored users additionally requires explicit release approval, operational readiness and the relevant Stage 4 release gates.
- Roll back application code when needed; do not assume a schema migration can be reversed safely. Prefer forward-compatible migrations and documented repair procedures.

## 10. Definition of done for a vertical slice

A slice is ready for review when it has:

1. Approved requirements and acceptance criteria linked to implementation.
2. Reviewed code following these standards and no unresolved critical security findings.
3. Migration and rollback/forward-repair plan where data changes.
4. Tests for normal, failure, retry, authorization and relevant device behavior.
5. Updated OpenAPI and generated clients when the API changes.
6. Required metrics, safe logs, dashboards/alerts and operator-facing failure states.
7. Updated user-facing privacy/permission explanation where data collection changes.
8. A Local verification record and a Pilot deployment/smoke-test plan.
9. `docs/PROJECT_STATUS.md` updated with actual work, test results, blockers and next three tasks.

## Review notes and open decisions

- This is a standards draft, not a claim that a codebase or CI pipeline already exists.
- Set exact supported OS/device versions, coverage thresholds, service targets, dependency update cadence and alert thresholds before the related implementation or release gate.
- Confirm legal/privacy review for Nigerian data protection and later African markets before live launch.
- Founder approved Stage 7 on 2026-10-07. The standards guide future implementation; it does not mean implementation or CI has been completed or tested.
