# Stage 3 Traceability and Review

Status: Stage 3 baseline; founder decisions from 2026-10-07 incorporated as a review draft; USSD remains deferred.

Date: 2026-10-06

| Product capability | Functional requirements | User stories | Key NFRs |
|---|---|---|---|
| Account, consent and trusted-circle membership/deletion | FR-001–009 | US-001, US-016 | NFR-030–037, NFR-040–043, NFR-050–052 |
| Continuous safety monitoring | FR-010–014, FR-030–041 | US-002, US-003, US-006, US-010 | NFR-001–005, NFR-020–022, NFR-050–052 |
| Trips with/without check-ins | FR-020–028 | US-004, US-005 | NFR-001, NFR-070, NFR-080 |
| Location modes and degraded connectivity | FR-046–059 | US-003, US-004, US-006, US-013, US-015 | NFR-010–019, NFR-040, NFR-044 |
| Family option, consented location visibility, multi-family heads and SOS alerts | FR-060–069, FR-034, FR-051 | US-007, US-008, US-003, US-006, US-016 | NFR-010–019, NFR-031–038, NFR-040–042 |
| Fake call | FR-070–074 | US-002, US-009 | NFR-051, NFR-071 |
| SOS audio | FR-080–084 | US-003, US-010 | NFR-030–037, NFR-083 |
| USSD | FR-090–093 | US-011 | NFR-003, NFR-033, NFR-037 |
| Monitoring dashboard | FR-100–109 | US-010 | NFR-020–022, NFR-050, NFR-060–063 |
| Partner API | FR-110–116 | US-012 | NFR-001–003, NFR-030–037, NFR-072 |
| Subscription configuration | FR-120–125 | US-014 | NFR-031–035, NFR-070, NFR-072 |
| Cross-cutting service quality | All applicable requirements | All applicable stories | NFR-004–005, NFR-041–043, NFR-061–063, NFR-070–073, NFR-080–083 |

## Output review

**Correctness:** PASS. Requirements match the approved product definition and founder review decisions. USSD remains documented but is deferred from version 1.

**Completeness:** Requirements and stories are mapped to the approved product capabilities. The 2026-10-07 trusted-contact and family-flow revisions still require founder review before their database design is treated as implementation-ready. Numeric targets and operational rules remain open pending evidence.

**Invitation and location rules:** Non-platform trusted members are added without acceptance and receive SOS-only SMS. The add notice and SOS SMS carry signup links until the contact joins; existing platform members receive no signup link. Signup via the link and invited identity verification automatically adds the person to the originating trusted circle. Family members need platform accounts; existing users accept/decline and new users are added after onboarding. A user may head multiple families. Family heads select consenting members to track; members are notified and can stop/revoke routine tracking. Account deletion removes family membership; deleting a family head dissolves the family, stops its monitoring and notifies its members by SMS/email. Trusted-circle members are not notified. Record-class retention is configurable through the admin dashboard/backend and subject to legal holds.

**Admin dashboard:** One administrative application serves operators and administrators. It combines incident monitoring and response with broader platform settings, subscriptions, configurable retention, user/family administration and audit review. Configuration changes are permission-controlled, versioned and audited.

**Complexity review:** The overall vision is broad. Feature flags and staged delivery are required for USSD, partner APIs, audio, family location visibility and general release. Stages 5 and 6 subsequently selected the technology stack and architecture.

**Confirmed during founder review:** minors join only through a family-head invitation; cancellation uses a security/rescue PIN; check-in rules are administratively configurable; users configure location frequency and receive a low-battery recommendation at 25%; evidence defaults to 60-day retention with controlled administration; the dashboard supports 24-hour operation while staffing follows measured workload; USSD is post-version 1; subscriptions are backend-configurable.

**Tracked implementation/policy decisions:** exact guardian/child-consent verification; separate duress PIN behavior; default location-freshness values within the configurable model; detailed Critical authority playbook; and exact supported OS/device matrix. Post-version-1 USSD work is tracked in `docs/tags/USSD.md`.

**Exit gate:** The original Stage 3 baseline was approved on 2026-10-06. The founder's additional trusted-circle and account-deletion decisions dated 2026-10-07 are incorporated here for review. Tracked decisions must not be silently invented during implementation.
