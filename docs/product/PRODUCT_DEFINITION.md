# Personal Safety Platform — Product Definition

Status: **Approved product definition, with founder-approved family-flow update (2026-10-07)**

Date: 2026-10-05

Input: Stage 0 intake and [Stage 1 discovery](../discovery/STAGE_1_DISCOVERY.md)

## Vision and position

Help people raise a clear, actionable alert to trusted contacts and a staffed monitoring team whenever they feel unsafe, whether or not they have started a trip. Offer the same alert and response workflow to approved partner platforms through an API. Start in Nigeria and expand country by country after validating local delivery, privacy, telecom and response operations.

This is a safety coordination service. It must disclose its actual monitoring hours and response scope. It must not imply guaranteed rescue, guaranteed delivery, current location when only an old fix exists, or automatic official emergency dispatch without an operational agreement.

## Users and jobs

| User | Job |
|---|---|
| Individual, family member, student, commuter | Use continuous safety monitoring or create a trip, trigger SOS or a fake call, and control when location is shared. |
| Trusted contact | Receive SOS-only SMS alerts without needing an app account; may join the platform through an optional link. |
| Family head | Head one or more family circles, invite platform users and select accepted members whose location they are authorized to track. |
| Monitoring operator | Use the admin dashboard to triage alerts, attempt contact, follow a documented escalation playbook, record actions and close an incident. |
| Administrator | Use the same admin dashboard to manage platform settings, subscriptions, retention, access and operational configuration. |
| Partner platform | Enrol consenting users, create and update incidents, receive status, and route its users to this response flow. |

## Requested product scope

- Android and iPhone apps; manual SOS at any time; missed-check-in SOS for trips with check-ins; SOS SMS to selected trusted-circle members and relevant family members; optional audio capture during SOS.
- **Trusted circle:** A user may add a non-platform person by phone number as a trusted member without requiring acceptance or account creation. They receive SMS only when an SOS is triggered; they cannot query location or receive routine location sharing. An SMS/email notice that they were added contains a signup link, and SOS SMS also contains it while they are not a platform member. Existing platform members receive no signup link. If a non-member joins through either link and verifies the invited identity, they are automatically linked to that user's trusted circle. A valid phone number is required for SOS SMS. Removing the relationship stops future alerts.
- **Continuous safety monitoring:** The user can remain protected without starting a trip and trigger manual SOS or a scheduled fake call whenever needed. This is separate from optional continuous location sharing. The service aims for 24-hour human alert monitoring; it does not require constant GPS use for every user.
- **Trip mode:** The user can create a trip with or without scheduled check-ins. A trip with check-ins prompts the user to confirm safety; after a missed check-in, reminder and grace period, it triggers SOS. A trip without check-ins supports manual SOS and chosen location sharing, but has no missed-check-in trigger.
- **Location modes:** The user chooses SOS-only, periodic, or always-available sharing, with or without an active trip. Location freshness and accuracy are shown; capabilities depend on device permission, connectivity and battery.
- **Family option:** A user may head more than one family. Every family member must have an app account. Existing users can accept or decline an invitation. A person without an account follows the invite link, signs up and completes onboarding; the system then adds them to the family immediately. The family head is notified when an invite is declined or a person joins. The family head opens a family, selects an accepted member and starts location tracking. The member sees that tracking is active, has clearly consented to family location access, and can stop or revoke it. Tracking follows the member's location mode, device permissions and available connectivity; locations show capture time, accuracy and freshness. Routine family tracking can be stopped or revoked without disabling SOS-only location sharing. When a member raises SOS, family members and the owner's selected trusted members receive SMS with available coordinates and time/accuracy context; non-platform trusted members receive SOS-only SMS. The monitoring dashboard receives the same incident and location evidence. If no location is available, the alert says so; stale locations are labelled. Only the family head may start tracking or request an on-demand refresh; these actions are logged and visible to the member. Other named contacts cannot query location on demand. Child/guardian permissions require separate product and legal review.
- **Account deletion:** Deletion immediately disables the account and its sessions and removes it from family membership. If the deleted account heads a family, the family is dissolved, its monitoring/tracking stops, and its members are notified by SMS and email using available verified contact channels. Trusted-circle members are not notified. Active incidents and other records follow retention durations configured by record class in the admin dashboard/backend, subject to legal holds and applicable law.
- Scheduled fake call; USSD initiation from another available phone; admin dashboard for incident monitoring and broader administration/configuration; partner API.
- Approved additions: alert acknowledgement and escalation, visible location age/accuracy, practice mode, and consent/access history.

These are product goals, not assertions that every platform or network condition can support them reliably.

## Approved pilot direction

**What a trip means:** An optional session that the user starts before travel, possibly with destination, arrival time, and check-ins. Only a missed scheduled check-in triggers automatic SOS. Manual SOS and fake call remain available with or without a trip.

**Pilot:** Start in Lagos with any practical number of consenting participants across the target groups; no fixed participant count is a release condition. Test continuous safety monitoring, trips with and without check-ins, trusted-contact alerts, family permissions, and the operator workflow. Begin with clearly labelled practice alerts and controlled drills; move to a live monitored pilot only after staffing, escalation procedures, contact consent, and alert delivery checks are ready. Set duration and coverage through a specific pilot plan.

**Monitoring decision:** The intended service is 24 hours a day, seven days a week. Launching it as a live monitored service requires a staffed rota, handover, backup coverage, incident escalation process and operational checks. Until those exist, trials must be labelled as drills and must not claim 24-hour human monitoring.

| Include in pilot | Validate before general release | Follow after pilot |
|---|---|---|
| Trusted circle with SOS-only SMS for non-platform members; continuous safety monitoring with manual SOS and scheduled fake call; trips with and without check-ins; missed-check-in trigger; explicit cancel/test mode; consented location sharing; family member location visibility and revocation; family SOS SMS with coordinates and delivery state; operator dashboard with matching incident/location, acknowledgement, escalation and audit log | Real-device location age, battery drain, background and no-data behavior; false alarms; actual SMS receipt and operator response; audio recording reliability; 24-hour staffing and retention controls | Scale always-available location and family monitoring after validating battery and abuse controls; partner API pilot after the consumer/monitoring pilot; wider partner rollout; multi-country expansion |
| USSD prototype only if an aggregator confirms identity, coverage and location behavior | USSD live end-to-end trial | General USSD availability after contractual and regulatory validation |

The deferred items remain in the product vision. They are not silently removed. Direct device SMS on Android and an iPhone offline fallback require platform-specific feasibility tests; server-side SMS requires the app to reach the server.

## Initial response flow

1. A user starts SOS from continuous monitoring or a trip, or misses a scheduled trip check-in after reminder and grace period. The system records trigger source and the most recent verified location with source, time and accuracy, including an explicit `unknown` state. A trip without check-ins cannot trigger SOS merely because no check-in exists.
2. It attempts SOS SMS to selected trusted-circle members and relevant family members, and sends the incident and same location evidence to monitoring. Non-platform trusted members' SMS includes a signup link; platform members' messages do not. SMS includes coordinates when available, capture time and accuracy; unavailable or stale location is labelled. Delivery states remain separate; do not infer human receipt from provider acceptance.
3. A staffed operator acknowledges, attempts safe verification, follows an escalation playbook, and records every action and handoff. Contacts can acknowledge and see authorized incident updates.
4. Cancellation and closure are logged. Practice mode is unmistakably labelled and never represented as a live emergency.

Exact response targets, triggers, cancellation controls and authority handoffs must be set after observed pilot drills and staffing decisions.

## Partner product boundaries

Partners must present verified end-user consent; access to incident location is scoped to the specific user and active purpose. A partner cannot use the family head's on-demand location request privilege or query a person's location merely by knowing a phone number. A partner integration needs credentials, safe Local testing and Pilot practice controls, repeat-safe alert requests, incident status updates, signed callbacks, and a clear division of support and privacy responsibilities. These are product expectations, not an API contract or technology choice.

## Success measures for supervised pilot

Track, without promising a target before measurement: SOS initiation success by device/network condition; time to first usable location and its age/accuracy; contact alert receipt and acknowledgement; operator acknowledgement time across day and night shifts; missed-checkpoint false-alert rate; battery impact against idle baseline; and incident closure quality. Measure partner integration separately after the consumer and operator workflow is validated. Record failures and unknown states in the denominator.

## Decisions and evidence needed before baseline

1. Build and verify the 24-hour staffing rota, backup coverage, escalation playbook and handover before live monitoring claims.
2. Define detailed consent and permissions for family members, especially minors; assess privacy, recording consent, data retention and operator access with qualified Nigerian counsel.
3. Validate pricing and willingness to pay through interviews; do not assume demand from competitor feature lists.
4. Verify a USSD provider, device/OS behavior, battery impact and SMS delivery with live trials.
5. Find a design partner for the API trial after the consumer/monitoring pilot.

## Output review

This definition was updated on 2026-10-07 following founder clarifications. Non-platform trusted members are added without acceptance and receive SOS-only SMS; signup links auto-link them to the circle, while existing platform members receive no signup link. A user may head multiple families; family members must have accounts. Account deletion dissolves a family headed by that user, stops its monitoring, notifies members by SMS and email, and applies configurable record retention. The admin dashboard supports incident monitoring and broader administration/configuration.
