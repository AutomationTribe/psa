# Stage 4 — Project Criticality and Engineering Profile

Status: Approved  
Date: 2026-10-06

## Recommended classification

**Safety-sensitive, high-criticality consumer platform.**

The product is not itself an emergency service and must not guarantee rescue. However, failures can delay assistance, expose precise location or audio, enable stalking, create false alerts or cause users and operators to act on stale information. It therefore requires stronger controls than an ordinary consumer application.

## Critical domains

| Domain | Criticality | Reason |
|---|---|---|
| SOS creation and incident state | Critical | Lost, duplicated or incorrect alerts can cause direct harm. |
| Location capture and freshness | Critical | Stale or inaccurate location can misdirect responders. |
| Alert delivery and acknowledgement | Critical | Provider acceptance is not proof of human receipt. |
| Operator workflow and escalation | Critical | Delayed or unauthorized actions can affect safety. |
| Family location access | Critical | Abuse can enable surveillance or stalking. |
| Authentication, consent and audit | Critical | Account takeover exposes safety and location data. |
| Audio evidence | High | Sensitive evidence requires strict access and retention. |
| Trips and check-in scheduler | High | Timing defects can miss or falsely trigger emergencies. |
| Subscription and fake call | Standard | Important, but failure normally has lower direct safety impact. |
| USSD | Deferred | Excluded from version 1 and tracked under the `USSD` tag. |

## Engineering profile

- **Architecture posture:** Conservative, fault-tolerant and observable; avoid experimental dependencies in critical paths.
- **Code readability:** Senior-level, with justified abstractions, explicit safety rules and simple incident-state transitions.
- **Change control:** Requirements traceability, reviewed migrations, independent review and rollback plans for critical changes.
- **Testing:** Unit, API/integration, headed mobile/UI, failure-injection, permission, weak-network, offline, battery and real-device tests.
- **Security:** Threat modelling, least privilege, encryption, strong secrets management, abuse controls and tamper-evident audit logs.
- **Reliability:** Idempotent incident creation, retry-safe delivery, offline queueing and explicit degraded states.
- **Operations:** 24-hour-capable dashboard, monitoring, alerting, runbooks, shift handover and incident ownership.
- **Privacy:** Data minimization, purpose limitation, configurable bounded retention, consent history and access history.

## Mandatory release gates

1. No critical feature ships without automated tests and real-device evidence for its main failure modes.
2. No alert channel is described as delivered without channel-specific delivery evidence.
3. No location is described as live without timestamp, accuracy and freshness classification.
4. No 24-hour monitoring claim is made before the staffing rota, backup and escalation process are operational.
5. Critical production changes require an independent review and rollback procedure.
6. Practice and live incidents remain separated throughout the system.
7. Unresolved safety or privacy risks block release of the affected feature.

## Environment and evidence requirements

- Separate development, test/staging and production environments.
- Separate practice/test and live incident data.
- Synthetic monitoring of incident creation and provider connectivity.
- Representative low-end and midrange Android devices plus supported iPhones.
- Weak network, no data, permission denial, background restriction and low-battery test scenarios.
- Audit evidence for access, escalation, configuration and package changes.

## Stage review

**Recommendation:** Approve the safety-sensitive, high-criticality profile and Senior code-readability profile.

**Impact:** Delivery will be slower than a basic consumer MVP, but the controls focus on functions whose failure could expose or endanger users. Lower-risk features may use proportionate controls.

**Exit gate:** APPROVED on 2026-10-06. Proceed to Technology Selection.
