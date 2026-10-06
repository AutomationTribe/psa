# User Stories and Acceptance Criteria

Status: Stage 3 draft for approval  
Date: 2026-10-06

## US-001 — Prepare a trusted circle

As a user, I want accepted trusted contacts to receive my emergency alerts.

Acceptance criteria:

1. An invitation does not grant access until accepted.
2. The user selects which accepted contacts receive SOS alerts.
3. Removing a contact prevents new access but preserves required incident audit history.
4. A normal trusted contact cannot request the user's location on demand.

## US-002 — Use continuous safety monitoring

As a user, I want SOS and fake call available without creating a trip.

Acceptance criteria:

1. The user can enable monitoring without enabling continuous location sharing.
2. Manual SOS remains available while monitoring is active.
3. The app shows permission, connection and monitoring limitations clearly.
4. Disabling monitoring does not silently change the user's saved sharing permissions.

## US-003 — Trigger SOS manually

As a user in danger, I want to raise an SOS quickly.

Acceptance criteria:

1. SOS can be triggered with or without an active trip.
2. One incident is created for one activation.
3. The incident includes the best available location, its time and accuracy, or `unavailable`.
4. Selected contacts and the monitoring queue receive alert attempts with traceable states.
5. Any audio failure is shown as a failure rather than as an active recording.

## US-004 — Create a trip without check-ins

As a user, I want to share a trip without automatic missed-check-in alerts.

Acceptance criteria:

1. The trip can start without check-in times.
2. Manual SOS and selected location sharing work during the trip.
3. The system never creates a missed-check-in SOS for this trip.
4. The user can end the trip manually.

## US-005 — Create a trip with check-ins

As a user, I want automatic escalation if I miss a safety check-in.

Acceptance criteria:

1. At least one valid check-in time is required.
2. The user receives a reminder before or at the due time.
3. The user may confirm safety during the allowed window.
4. An unconfirmed check-in triggers one SOS after the configured grace period.
5. Confirmation before trigger prevents that automatic incident and is logged.

## US-006 — Receive and acknowledge an SOS

As a trusted contact, I want enough verified context to respond appropriately.

Acceptance criteria:

1. The alert identifies the person, trigger time and approved incident link or message.
2. Location is labelled with age and accuracy; old data is not labelled live.
3. The contact can acknowledge the alert.
4. The user and operator can see that acknowledgement.
5. The contact sees only authorized incident information.

## US-007 — Manage a family circle

As a family head, I want to invite relatives and manage the family circle.

Acceptance criteria:

1. Each member accepts their invitation.
2. Adult members decide separately whether the family head may request location.
3. Trusted-contact and family-head permissions are shown as different permissions.
4. Leaving or removal revokes future family access.
5. Minor accounts are blocked until the governing policy is approved.

## US-008 — Request a family member's location

As a family head, I want to request a consenting member's location.

Acceptance criteria:

1. The request is allowed only for an active family member who granted permission.
2. A denied or revoked permission returns no location.
3. The result identifies capture time, freshness, accuracy and unavailable state.
4. The member can see the request and requester in access history.
5. No other trusted contact or partner receives this capability.

## US-009 — Schedule a fake call

As a user who feels uncomfortable, I want a scheduled fake call to help me exit.

Acceptance criteria:

1. The user chooses a future trigger time and approved caller presentation.
2. The user can cancel it before execution.
3. The app records executed, cancelled or failed status.
4. A fake call does not raise SOS by itself.

## US-010 — Handle an incident

As an operator, I want a complete response timeline and clear next actions.

Acceptance criteria:

1. Live and practice alerts cannot be confused.
2. The operator acknowledges and assumes or receives ownership.
3. Location provenance, alert delivery and contact acknowledgements are visible.
4. Contact attempts, notes, escalation, handoff and closure are audited.
5. Closure uses an approved reason and verification flow.

## US-011 — Raise SOS through USSD

As an authorized caller without access to the user's phone, I want to raise an alert through USSD.

Acceptance criteria:

1. The feature is unavailable until an approved provider and feature flag are active.
2. The flow verifies the registered user and applies anti-abuse controls.
3. The alert identifies location provenance and does not claim access to the absent phone's GPS.
4. The incident enters the same monitored lifecycle with source `USSD`.

## US-012 — Integrate a partner platform

As an approved partner, I want to send consented safety alerts into the response flow.

Acceptance criteria:

1. Partner and end-user identity and consent are verified.
2. Repeating the same request does not create duplicate incidents.
3. Test traffic is separated from live traffic.
4. Status callbacks are authenticated and auditable.
5. The partner cannot query family locations or search users by phone number.

