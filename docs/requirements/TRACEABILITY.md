# Stage 3 Traceability and Review

Status: Approved on 2026-10-06, with USSD deferred and excluded from version 1.

Date: 2026-10-06

| Product capability | Functional requirements | User stories | Key NFRs |
|---|---|---|---|
| Account, consent and setup | FR-001–007 | US-001 | NFR-030–037, NFR-040–043, NFR-050–052 |
| Continuous safety monitoring | FR-010–014, FR-030–041 | US-002, US-003, US-006, US-010 | NFR-001–005, NFR-020–022, NFR-050–052 |
| Trips with/without check-ins | FR-020–028 | US-004, US-005 | NFR-001, NFR-070, NFR-080 |
| Location modes and degraded connectivity | FR-046–059 | US-003, US-004, US-006, US-013, US-015 | NFR-010–019, NFR-040, NFR-044 |
| Family option | FR-060–069 | US-007, US-008 | NFR-031–038, NFR-042 |
| Fake call | FR-070–074 | US-002, US-009 | NFR-051, NFR-071 |
| SOS audio | FR-080–084 | US-003, US-010 | NFR-030–037, NFR-083 |
| USSD | FR-090–093 | US-011 | NFR-003, NFR-033, NFR-037 |
| Monitoring dashboard | FR-100–109 | US-010 | NFR-020–022, NFR-050, NFR-060–063 |
| Partner API | FR-110–116 | US-012 | NFR-001–003, NFR-030–037, NFR-072 |
| Subscription configuration | FR-120–125 | US-014 | NFR-031–035, NFR-070, NFR-072 |
| Cross-cutting service quality | All applicable requirements | All applicable stories | NFR-004–005, NFR-041–043, NFR-061–063, NFR-070–073, NFR-080–083 |

## Output review

**Correctness:** PASS. Requirements match the approved product definition and founder review decisions. USSD remains documented but is deferred from version 1.

**Completeness for the next stage:** Sufficient for Stage 4 criticality and engineering-profile selection. Numeric targets and operational rules are intentionally open pending evidence.

**Contradictions found:** The older Stage 1 discovery says selected named contacts may request location. Stage 2 supersedes this: only a consenting family member's family head may request location on demand. Stage 3 follows Stage 2.

**Complexity review:** The overall vision is broad. Feature flags and staged delivery are required for USSD, partner APIs, audio, family queries and general release. No stack or architecture has been selected.

**Confirmed during founder review:** minors join only through a family-head invitation; cancellation uses a security/rescue PIN; check-in rules are administratively configurable; users configure location frequency and receive a low-battery recommendation at 25%; evidence defaults to 60-day retention with controlled administration; the dashboard supports 24-hour operation while staffing follows measured workload; USSD is post-version 1; subscriptions are backend-configurable.

**Tracked implementation/policy decisions:** exact guardian/child-consent verification; separate duress PIN behavior; default location-freshness values within the configurable model; detailed Critical authority playbook; and exact supported OS/device matrix. Post-version-1 USSD work is tracked in `docs/tags/USSD.md`.

**Exit gate:** APPROVED. Proceed to Stage 4. Tracked decisions must not be silently invented during implementation.
