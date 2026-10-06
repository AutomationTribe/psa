# Personal Safety Platform — Product Definition

Status: **Approved product definition (2026-10-05)**

Date: 2026-10-05

Input: Stage 0 intake and [Stage 1 discovery](../discovery/STAGE_1_DISCOVERY.md)

## Vision and position

Help people raise a clear, actionable alert to trusted contacts and a staffed monitoring team whenever they feel unsafe, whether or not they have started a trip. Offer the same alert and response workflow to approved partner platforms through an API. Start in Nigeria and expand country by country after validating local delivery, privacy, telecom and response operations.

This is a safety coordination service. It must disclose its actual monitoring hours and response scope. It must not imply guaranteed rescue, guaranteed delivery, current location when only an old fix exists, or automatic official emergency dispatch without an operational agreement.

## Users and jobs

| User | Job |
|---|---|
| Individual, family member, student, commuter | Use continuous safety monitoring or create a trip, trigger SOS or a fake call, and control when location is shared. |
| Trusted contact | Receive an SOS, know the latest location's age and accuracy, acknowledge it, and coordinate help. |
| Family head | Invite members into a family circle and request a member's location only after that member has granted this permission. |
| Monitoring operator | Triage alerts, attempt contact, follow a documented escalation playbook, record actions and close an incident. |
| Partner platform | Enrol consenting users, create and update incidents, receive status, and route its users to this response flow. |

## Requested product scope

- Android and iPhone apps; manual SOS at any time; missed-check-in SOS for trips with check-ins; SMS to selected trusted contacts; optional audio capture during SOS.
- **Continuous safety monitoring:** The user can remain protected without starting a trip and trigger manual SOS or a scheduled fake call whenever needed. This is separate from optional continuous location sharing. The service aims for 24-hour human alert monitoring; it does not require constant GPS use for every user.
- **Trip mode:** The user can create a trip with or without scheduled check-ins. A trip with check-ins prompts the user to confirm safety; after a missed check-in, reminder and grace period, it triggers SOS. A trip without check-ins supports manual SOS and chosen location sharing, but has no missed-check-in trigger.
- **Location modes:** The user chooses SOS-only, periodic, or always-available sharing, with or without an active trip. Location freshness and accuracy are shown; capabilities depend on device permission, connectivity and battery.
- **Family option:** A family head can invite members into a family circle. Only in this option can the family head request a member's location on demand, and only with that member's explicit, revocable permission. Requests are logged and visible to the member. Other named contacts can receive SOS or user-initiated sharing but cannot query location on demand. Child/guardian permissions require separate product and legal review.
- Scheduled fake call; USSD initiation from another available phone; monitoring dashboard; partner API.
- Approved additions: alert acknowledgement and escalation, visible location age/accuracy, practice mode, and consent/access history.

These are product goals, not assertions that every platform or network condition can support them reliably.

## Approved pilot direction

**What a trip means:** An optional session that the user starts before travel, possibly with destination, arrival time, and check-ins. Only a missed scheduled check-in triggers automatic SOS. Manual SOS and fake call remain available with or without a trip.

**Pilot:** Start in Lagos with any practical number of consenting participants across the target groups; no fixed participant count is a release condition. Test continuous safety monitoring, trips with and without check-ins, trusted-contact alerts, family permissions, and the operator workflow. Begin with clearly labelled practice alerts and controlled drills; move to a live monitored pilot only after staffing, escalation procedures, contact consent, and alert delivery checks are ready. Set duration and coverage through a specific pilot plan.

**Monitoring decision:** The intended service is 24 hours a day, seven days a week. Launching it as a live monitored service requires a staffed rota, handover, backup coverage, incident escalation process and operational checks. Until those exist, trials must be labelled as drills and must not claim 24-hour human monitoring.

| Include in pilot | Validate before general release | Follow after pilot |
|---|---|---|
| Trusted circle with contact acceptance; continuous safety monitoring with manual SOS and scheduled fake call; trips with and without check-ins; missed-check-in trigger; explicit cancel/test mode; consented location sharing; family head request permission and audit; last-known timestamp/accuracy; server-side SMS and delivery state; operator dashboard with acknowledgement, escalation and audit log | Real-device location age, battery drain, background and no-data behavior; false alarms; actual SMS receipt and operator response; audio recording reliability; 24-hour staffing and retention controls | Scale always-available location and family queries after validating battery and abuse controls; partner API pilot after the consumer/monitoring pilot; wider partner rollout; multi-country expansion |
| USSD prototype only if an aggregator confirms identity, coverage and location behavior | USSD live end-to-end trial | General USSD availability after contractual and regulatory validation |

The deferred items remain in the product vision. They are not silently removed. Direct device SMS on Android and an iPhone offline fallback require platform-specific feasibility tests; server-side SMS requires the app to reach the server.

## Initial response flow

1. A user starts SOS from continuous monitoring or a trip, or misses a scheduled trip check-in after reminder and grace period. The system records trigger source and the most recent verified location with source, time and accuracy, including an explicit `unknown` state. A trip without check-ins cannot trigger SOS merely because no check-in exists.
2. It attempts alerts to the selected contacts and monitoring team, recording queued, provider-accepted and confirmed states separately. Do not infer human receipt from a provider acknowledgement.
3. A staffed operator acknowledges, attempts safe verification, follows an escalation playbook, and records every action and handoff. Contacts can acknowledge and see authorized incident updates.
4. Cancellation and closure are logged. Practice mode is unmistakably labelled and never represented as a live emergency.

Exact response targets, triggers, cancellation controls and authority handoffs must be set after observed pilot drills and staffing decisions.

## Partner product boundaries

Partners must present verified end-user consent; access to incident location is scoped to the specific user and active purpose. A partner cannot use the family head's on-demand location request privilege or query a person's location merely by knowing a phone number. A partner integration needs credentials, a safe test environment, repeat-safe alert requests, incident status updates, signed callbacks, and a clear division of support and privacy responsibilities. These are product expectations, not an API contract or technology choice.

## Success measures for supervised pilot

Track, without promising a target before measurement: SOS initiation success by device/network condition; time to first usable location and its age/accuracy; contact alert receipt and acknowledgement; operator acknowledgement time across day and night shifts; missed-checkpoint false-alert rate; battery impact against idle baseline; and incident closure quality. Measure partner integration separately after the consumer and operator workflow is validated. Record failures and unknown states in the denominator.

## Decisions and evidence needed before baseline

1. Build and verify the 24-hour staffing rota, backup coverage, escalation playbook and handover before live monitoring claims.
2. Define detailed consent and permissions for family members, especially minors; assess privacy, recording consent, data retention and operator access with qualified Nigerian counsel.
3. Validate pricing and willingness to pay through interviews; do not assume demand from competitor feature lists.
4. Verify a USSD provider, device/OS behavior, battery impact and SMS delivery with live trials.
5. Find a design partner for the API trial after the consumer/monitoring pilot.

## Output review

This approved definition preserves all user-requested capabilities and approved suggestions. Continuous monitoring and optional trips are distinct modes; only the family head may request a member's location on demand, subject to permission. Lagos and partner API sequencing are approved, and there is no fixed pilot participant count. The 24-hour monitoring goal is recorded, while operational readiness remains unverified. No architecture, stack, database or implementation has been selected.
