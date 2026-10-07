# User Stories and Acceptance Criteria

Status: Stage 3 baseline; founder decisions from 2026-10-07 incorporated as a review draft; USSD deferred under `docs/tags/USSD.md`
Date: 2026-10-07

## US-001 — Prepare a trusted circle

As a user, I want to add trusted members who can receive SOS SMS even if they do not use the app.

Acceptance criteria:

1. The user can add a trusted member by phone without requiring that person to have an account or accept an invitation.
2. A non-platform trusted member receives SOS-only SMS and never routine location updates or on-demand location access.
3. The notice that the member was added includes a signup link by SMS and, if supplied, email; SOS SMS includes the link until the member joins.
4. Existing platform members receive no signup link. A non-member who signs up through either link and verifies the invited identity is automatically linked to the originating circle, and the owner is notified.
5. The user selects which trusted members receive SOS alerts; SMS requires a valid phone number.
6. Removing/revoking a member prevents future alerts but preserves required incident audit history.
7. A trusted member cannot request the user's location on demand.

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
6. Authorized administrators can configure reminder and grace-period defaults with audit history.

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

1. Existing platform users can accept or decline a family invitation and see a clear explanation of membership and location tracking.
2. A non-user is told to sign up; accepting the disclosed location consent and completing onboarding through the invitation adds them to the family immediately.
3. Acceptance/onboarding includes explicit, recorded consent for family location tracking under the member's configured location mode.
4. The family head opens the family, selects an accepted member and starts tracking; the member is notified.
5. A member can stop or revoke routine family tracking; leaving/removal revokes family access and SOS-circle delivery. An explicit SOS uses the separate SOS-only sharing mode.
6. A decline does not add the invitee and updates the family head.
7. The family head is updated when an invited member joins.
8. A minor joins only through an adult family-head invitation sent by SMS or email and completes onboarding into that family.
9. Guardian authority and applicable child-consent rules must be verified before the minor's safety permissions become active.
10. Accepted family-circle members receive SMS when a member raises SOS, with available coordinates and capture time/accuracy; unavailable or stale location is clearly labelled.
11. A user may be head of more than one family.

## US-008 — Monitor a family member's location

As a family head, I want to select an accepted family member to track and see their latest consented location.

Acceptance criteria:

1. Only active family members who accepted/joined with disclosed location consent can be selected.
2. The family head explicitly selects a member to start tracking; selection is logged and the member is notified.
3. A member may stop/revoke routine tracking, which prevents further family reads; SOS-only incident sharing remains a separate mode.
4. The result identifies capture time, freshness, accuracy and unavailable state and follows the member's location mode.
5. The member can see tracking state, views/requests and the requester in access history.
6. No other trusted contact or partner receives this capability.

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
6. A Critical classification immediately notifies the operator and exposes the controlled authority-escalation action.
7. Non-Critical classifications do not automatically contact authorities.

## US-011 — Raise SOS through USSD

Status: Deferred; excluded from version 1.

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

## US-013 — Configure location frequency

As a user, I want to balance location freshness and battery consumption.

Acceptance criteria:

1. The user selects an allowed preset or update interval for periodic and always-available sharing.
2. At 25% battery or below, the app recommends a lower-power setting and explains the trade-off.
3. The setting changes only after the user accepts it, except where the operating system prevents collection.
4. Every shared location continues to show capture time, freshness and accuracy.
5. Freshness thresholds are administratively configurable by active safety mode.

## US-015 — Preserve safety evidence without data coverage

As a user in poor coverage, I want the app to preserve and forward the best location evidence it can obtain.

Acceptance criteria:

1. The app distinguishes obtaining a device location from transmitting it to the service.
2. Timestamped emergency events and location samples are encrypted and queued locally when transmission fails.
3. The app retries through approved available paths without creating duplicate incidents.
4. Historical, estimated and current locations are visibly different.
5. When connectivity returns, queued evidence is synchronized with its original capture time and source.

## US-016 — Delete an account and end its family access

As a user, I want account deletion to revoke my access and stop family tracking under my account.

Acceptance criteria:

1. Deletion revokes active sessions and removes the user from family memberships immediately.
2. If the deleted user heads a family, that family is dissolved, its monitoring stops, and its members are notified by SMS and email using available verified channels.
3. Trusted contacts are not notified when an account is deleted.
4. Active incidents and other records follow retention durations configurable by record class in the admin dashboard/backend, subject to applicable legal holds.
5. Personal SOS functionality belonging to other family members is not disabled by the head's account deletion.

## US-014 — Configure subscription packages

As an administrator, I want to create packages without releasing a new mobile-app version.

Acceptance criteria:

1. A package can combine features, limits, price, currency and billing period.
2. A package can be free, paid or have a configurable trial such as 14 or 30 days.
3. Package versions define how existing subscribers are affected.
4. The backend enforces entitlements and the apps display the active catalogue.
5. Package changes are audited.
