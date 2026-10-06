# Functional Requirements

Status: Stage 3 draft for approval  
Date: 2026-10-06  
Source: [Approved Product Definition](../product/PRODUCT_DEFINITION.md)

## Actors

- **User:** Uses safety monitoring, trips, SOS, fake call and location sharing.
- **Trusted contact:** Receives and acknowledges alerts. Cannot request location on demand.
- **Family member:** A user inside a family circle.
- **Family head:** Manages the family circle and may request a consenting member's location.
- **Operator:** Handles incidents through the monitoring dashboard.
- **Supervisor:** Manages operators, playbooks and controlled access.
- **Partner system:** Integrates later through approved APIs.

## Account, consent and safety setup

- **FR-001:** A user shall create and verify an account using supported identity methods.
- **FR-002:** A user shall maintain a safety profile containing their name, verified phone number and optional information approved for emergency use.
- **FR-003:** A user shall invite trusted contacts, and a contact must accept before receiving routine location sharing or incident access.
- **FR-004:** A user shall select which accepted contacts receive SOS alerts.
- **FR-005:** The system shall explain each requested device permission and show the resulting capability when permission is granted, limited or denied.
- **FR-006:** The system shall provide a guided practice alert that is clearly labelled as a test for the user, contacts and operators.
- **FR-007:** A user shall see and revoke active sharing permissions and contact access.

## Continuous safety monitoring

- **FR-010:** A user shall enable or disable continuous safety monitoring without creating a trip.
- **FR-011:** Continuous safety monitoring shall keep manual SOS and scheduled fake call available while enabled.
- **FR-012:** Enabling safety monitoring shall not automatically enable continuous GPS sharing; location mode remains a separate user choice.
- **FR-013:** The app shall show whether monitoring is active, whether location and notification permissions are sufficient, and whether the device can currently communicate with the service.
- **FR-014:** If the service cannot provide a promised monitoring capability, the app shall show the limitation without claiming full protection.

## Trips and check-ins

- **FR-020:** A user shall create a trip with an optional destination, expected arrival time, notes and selected contacts.
- **FR-021:** A trip may have no scheduled check-ins or one or more scheduled check-ins.
- **FR-022:** A trip without check-ins shall support manual SOS and the user's selected location-sharing mode but shall not create a missed-check-in SOS.
- **FR-023:** Before a scheduled check-in becomes overdue, the system shall remind the user to confirm safety.
- **FR-024:** A user shall confirm a check-in, extend it where permitted, or end the trip.
- **FR-025:** If a scheduled check-in remains unconfirmed after the configured grace period, the system shall create an SOS incident automatically.
- **FR-026:** The system shall prevent duplicate incidents for the same missed check-in.
- **FR-027:** A user shall be able to cancel a pending automatic trigger during the grace period using the approved safe-cancellation method.
- **FR-028:** Trip state changes, reminders, check-ins, missed check-ins and cancellations shall be recorded with timestamps.

## SOS and incident lifecycle

- **FR-030:** A user shall trigger SOS manually from the main safety interface whether monitoring or a trip is active.
- **FR-031:** The app shall provide an accessible trigger designed to reduce accidental activation while remaining fast in an emergency.
- **FR-032:** An SOS incident shall record its trigger source: manual, missed check-in, USSD, partner API or another approved source.
- **FR-033:** On trigger, the system shall capture the latest available location with its source, timestamp and accuracy, or explicitly record location as unavailable.
- **FR-034:** The system shall notify the monitoring team and attempt alerts to the user's selected contacts through configured channels.
- **FR-035:** Delivery state shall distinguish app queueing, provider acceptance, delivery evidence where available, contact acknowledgement and failure.
- **FR-036:** The system shall retry eligible failed alert operations according to a controlled policy without creating duplicate incidents or duplicate uncontrolled escalations.
- **FR-037:** Contacts shall be able to acknowledge an SOS and see only the incident information authorized for them.
- **FR-038:** An operator shall acknowledge, classify, assign, update, escalate and close an incident.
- **FR-039:** Every operator action, access and handoff shall be timestamped and attributable.
- **FR-040:** Cancellation or closure shall require an approved verification flow and shall preserve the incident audit history.
- **FR-041:** Practice incidents shall be isolated from live incidents and visibly marked at every stage.

## Location and sharing

- **FR-050:** A user shall select one of these location modes: SOS only, periodic sharing or always available.
- **FR-051:** A user shall choose the recipients of periodic or user-initiated sharing from accepted contacts.
- **FR-052:** Every displayed location shall include its captured time, freshness status and available accuracy information.
- **FR-053:** The system shall distinguish a current fix, a recent cached fix, an old last-known fix and unavailable location.
- **FR-054:** The app shall adapt location collection to the active context, using lower power behavior when idle and higher urgency during a trip or SOS where the platform permits.
- **FR-055:** Loss of permission, connectivity, location services or battery capability shall update the visible status and be recorded when relevant to an active trip or incident.
- **FR-056:** A contact outside the family-head role shall not request another user's location on demand.

## Family option

- **FR-060:** A user shall create a family circle and become its initial family head.
- **FR-061:** The family head shall invite members, and each member must accept before joining.
- **FR-062:** An adult member shall explicitly grant or deny the family head permission to request their location on demand.
- **FR-063:** An adult member shall revoke that permission at any time, taking effect for new requests.
- **FR-064:** An approved family-head request shall return the best available location with timestamp, accuracy and freshness; it shall not present an old location as live.
- **FR-065:** Each request and result shall be logged and visible to the member, including requester and time.
- **FR-066:** Family-head status shall not allow silent access to microphone, audio recordings or unrelated incident history.
- **FR-067:** Adding minors and guardian-managed consent shall remain unavailable until its legal and product rules are approved.
- **FR-068:** Removing a member or leaving a family shall revoke future family-location access.

## Fake call

- **FR-070:** A user shall schedule a fake call for a chosen future time.
- **FR-071:** The user shall configure the approved caller presentation and may cancel the scheduled fake call.
- **FR-072:** The fake call shall be visibly distinguishable inside the app from a real network call where platform rules require this.
- **FR-073:** Triggering or answering a fake call shall not automatically create an SOS unless the user separately requests it or a later approved rule explicitly links them.
- **FR-074:** If platform state prevents the fake call, the app shall show a clear failure state and shall not claim it occurred.

## SOS audio

- **FR-080:** If the user has enabled SOS audio and permission is available, the app shall attempt to start recording when an SOS begins.
- **FR-081:** The incident shall show whether recording started, failed, stopped or uploaded.
- **FR-082:** Audio shall be encrypted in transit and at rest and accessible only to authorized incident roles.
- **FR-083:** Audio access, playback, download and deletion shall be audited.
- **FR-084:** Recording behavior, notices and retention shall follow approved jurisdiction-specific policy.

## USSD initiation

- **FR-090:** A verified USSD flow shall allow an authorized caller to initiate an alert for a registered user from another phone.
- **FR-091:** The flow shall use approved identity and anti-abuse checks without exposing sensitive profile information to the caller.
- **FR-092:** A USSD alert shall clearly identify the caller-supplied, network-supplied and previously known location sources; it shall not imply GPS from the absent user's phone.
- **FR-093:** USSD shall remain behind a feature flag until provider coverage, cost, identity, security and end-to-end behavior are validated.

## Monitoring dashboard

- **FR-100:** Operators shall see a prioritized queue separating live and practice incidents.
- **FR-101:** The incident view shall show trigger source, user/contact details permitted for response, location history with freshness, delivery state, acknowledgements and action timeline.
- **FR-102:** Only an assigned operator or authorized supervisor shall access full incident details.
- **FR-103:** The dashboard shall support assignment, escalation, notes, contact attempts, handoff and closure reason.
- **FR-104:** Shift handoff shall identify open incidents, ownership and pending actions.
- **FR-105:** Supervisors shall review audit logs and operational metrics without altering historical event records.
- **FR-106:** The dashboard shall not claim 24-hour coverage unless an approved operating rota and backup coverage are active.

## Partner API, later pilot

- **FR-110:** Approved partners shall authenticate using credentials scoped to their organization and environment.
- **FR-111:** Partners shall enrol only users whose consent and identity linkage have been verified.
- **FR-112:** Partners shall create incident alerts using repeat-safe requests and provide trigger, user and location provenance.
- **FR-113:** Partners shall receive incident status through authenticated retrieval or signed callbacks.
- **FR-114:** A partner shall not use the family-head on-demand location privilege or query by phone number alone.
- **FR-115:** Test and live events shall use separate environments and be visibly distinguishable.
- **FR-116:** Partner access, requests, responses, failures, revocation and rate-limit events shall be auditable.

## Configuration requiring pilot evidence

The following must be configurable and approved before live release: reminder timing; missed-check-in grace period; location freshness thresholds; update frequency; retry limits; escalation steps; operator acknowledgement target; contact ordering; evidence retention; audio retention; and incident closure rules.

## Deferred policy decisions

- Consent and control for minors.
- Exact safe-cancellation method and duress handling.
- Official authority and private responder integrations.
- Country-specific recording, retention and emergency-service rules.
- Commercial entitlements, subscriptions and limits.

