# Nonfunctional Requirements

Status: Stage 3 approved; USSD-specific work deferred under `docs/tags/USSD.md`
Date: 2026-10-06

Numeric service targets will be baselined after feasibility measurements and the 24-hour operating plan. Until then, these requirements define what must be measured and controlled.

## Reliability and delivery

- **NFR-001:** Incident creation and alert processing shall be retry-safe and prevent duplicate incidents from repeated device, provider or partner requests.
- **NFR-002:** Each alert attempt shall have an observable state and failure reason where available.
- **NFR-003:** Critical workflows shall degrade explicitly when location, data, SMS, push, microphone or monitoring service is unavailable.
- **NFR-004:** Recovery procedures shall preserve open incidents and audit history.
- **NFR-005:** Availability, recovery and data-loss targets shall be set before the live pilot from measured architecture and operating capacity.

## Location and battery

- **NFR-010:** Location responses shall carry capture time, source, reported accuracy and freshness classification.
- **NFR-011:** The mobile apps shall minimize background location collection according to active mode and platform guidance.
- **NFR-012:** Battery impact shall be measured on representative low-end and midrange Android devices and supported iPhones for idle monitoring, periodic sharing, trips and active SOS.
- **NFR-013:** Battery and location budgets shall be approved before general release; unmeasured claims shall not appear in product messaging.
- **NFR-014:** Location configuration shall use understandable presets and safe bounds rather than unrestricted intervals that could make tracking ineffective or exhaust the battery.
- **NFR-015:** The 25% low-battery recommendation and any automatic platform degradation shall be measurable and visible to the user.
- **NFR-016:** Location acquisition and transmission shall be independently observable because a device may obtain coordinates while unable to send them.
- **NFR-017:** Idle monitoring shall prefer passive, significant-change, motion-aware, geofence or batched updates where supported; high-accuracy continuous tracking shall be reserved for an active SOS or explicit high-accuracy mode.
- **NFR-018:** Low-battery operation shall reduce noncritical sampling, batch network traffic and preserve enough capacity for SOS capture and transmission attempts.
- **NFR-019:** Offline emergency events shall be encrypted, integrity-protected, bounded in storage and synchronized idempotently after reconnection.

## Performance

- **NFR-020:** SOS initiation, first incident visibility, first location availability, alert-provider acceptance and operator acknowledgement shall be measured separately.
- **NFR-021:** Performance targets shall include weak-network and backgrounded-device conditions, not only ideal connections.
- **NFR-022:** The dashboard shall keep new live incidents visible and actionable under the validated pilot concurrency level.

## Security and privacy

- **NFR-030:** Data shall be encrypted in transit and sensitive stored data encrypted using approved platform controls.
- **NFR-031:** Access shall follow least privilege, with separate user, family-head, operator, supervisor and partner permissions.
- **NFR-032:** Family location requests, incident access, audio access, operator actions and partner calls shall be tamper-evident and auditable.
- **NFR-033:** The system shall protect against account takeover, forged alerts, replayed requests, insecure direct object access, injection, abusive location queries and excessive automated requests.
- **NFR-034:** Secrets shall not be embedded in mobile apps, source control, logs or client-visible configuration.
- **NFR-035:** Logs shall exclude passwords, tokens, raw secrets and unnecessary precise-location or audio data.
- **NFR-036:** Consent, retention, deletion, breach response and partner controller/processor responsibilities shall be reviewed against Nigerian requirements before live release.
- **NFR-038:** Safety evidence shall default to 60-day retention; administrative changes shall be bounded, audited and subject to deletion and legal-hold rules.
- **NFR-037:** High-risk features including family location, USSD identity, audio and partner incidents shall receive threat modelling before implementation.

## Safety and abuse prevention

- **NFR-040:** The interface shall prevent old or low-confidence location from being mistaken for a current precise fix.
- **NFR-041:** Practice alerts shall remain visibly separate throughout mobile, messaging and dashboard workflows.
- **NFR-042:** Cancellation, duress, false alerts, malicious family heads, compromised contacts and operator misuse shall have documented controls before live use.
- **NFR-043:** The service shall avoid guaranteed rescue or delivery claims unless supported by verified contracts and measured operations.
- **NFR-044:** The product shall not claim guaranteed location under total radio outage, disabled location services, denied permissions, powered-off hardware or a depleted battery.

## Accessibility and usability

- **NFR-050:** Critical mobile and dashboard flows shall support screen readers, meaningful labels, adequate contrast, scalable text, clear focus and keyboard navigation where applicable.
- **NFR-051:** SOS and cancellation interactions shall be usable under stress and tested for accidental activation and dangerous delay.
- **NFR-052:** Status and errors shall use plain language and shall not rely only on color, sound or vibration.

## Observability and operations

- **NFR-060:** The system shall produce structured logs, metrics and alerts for incident creation, delivery failures, location failures, operator acknowledgement, queue backlog and integration health.
- **NFR-061:** Operational dashboards shall distinguish system availability, provider availability and human monitoring coverage.
- **NFR-062:** Health checks shall cover critical dependencies without exposing sensitive data.
- **NFR-063:** The dashboard shall technically support continuous 24-hour operation. A verified rota, backup coverage, incident ownership, escalation, handover and outage communication process shall be required before monitored launch, with staffing scaled from measured workload.

## Maintainability and compatibility

- **NFR-070:** Business rules such as grace periods, retries, location freshness, retention and escalation shall be configurable with validation and audit history.
- **NFR-071:** The product shall support the widest practical Android and iOS range that passes security, background-operation and critical-flow tests; unsupported versions shall be documented rather than assumed safe.
- **NFR-072:** API contracts shall be versioned when required, documented in OpenAPI and kept synchronized with implementation.
- **NFR-073:** Significant dependencies shall be reviewed for maintenance, security, licensing, runtime impact and ownership.

## Testability

- **NFR-080:** Time-based workflows shall support controlled clocks or equivalent test mechanisms.
- **NFR-081:** Location, SMS, push, audio, connectivity and provider failures shall be reproducible in non-production tests.
- **NFR-082:** Unit, API/integration, headed UI/E2E, smoke, critical-journey and regression suites shall be maintained according to feature risk.
- **NFR-083:** Test evidence shall identify device, OS, network condition, permission state and location freshness where relevant.
