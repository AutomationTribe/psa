# Stage 3 Traceability and Review

Date: 2026-10-06

| Product capability | Functional requirements | User stories | Key NFRs |
|---|---|---|---|
| Account, consent and setup | FR-001–007 | US-001 | NFR-030–037, NFR-040–043, NFR-050–052 |
| Continuous safety monitoring | FR-010–014, FR-030–041 | US-002, US-003, US-006, US-010 | NFR-001–005, NFR-020–022, NFR-050–052 |
| Trips with/without check-ins | FR-020–028 | US-004, US-005 | NFR-001, NFR-070, NFR-080 |
| Location modes | FR-050–056 | US-003, US-004, US-006 | NFR-010–013, NFR-040 |
| Family option | FR-060–068 | US-007, US-008 | NFR-031–037, NFR-042 |
| Fake call | FR-070–074 | US-002, US-009 | NFR-051, NFR-071 |
| SOS audio | FR-080–084 | US-003, US-010 | NFR-030–037, NFR-083 |
| USSD | FR-090–093 | US-011 | NFR-003, NFR-033, NFR-037 |
| Monitoring dashboard | FR-100–106 | US-010 | NFR-020–022, NFR-050, NFR-060–063 |
| Partner API | FR-110–116 | US-012 | NFR-001–003, NFR-030–037, NFR-072 |
| Cross-cutting service quality | All applicable requirements | All applicable stories | NFR-004–005, NFR-041–043, NFR-061–063, NFR-070–073, NFR-080–083 |

## Output review

**Correctness:** PASS WITH OPEN DECISIONS. Requirements match the approved product definition, including continuous monitoring, trips with and without check-ins, family-head-only location requests, 24-hour monitoring goal, USSD and later partner API.

**Completeness for the next stage:** Sufficient for Stage 4 criticality and engineering-profile selection. Numeric targets and operational rules are intentionally open pending evidence.

**Contradictions found:** The older Stage 1 discovery says selected named contacts may request location. Stage 2 supersedes this: only a consenting family member's family head may request location on demand. Stage 3 follows Stage 2.

**Complexity review:** The overall vision is broad. Feature flags and staged delivery are required for USSD, partner APIs, audio, family queries and general release. No stack or architecture has been selected.

**Open decisions:** minors/guardian consent; duress and cancellation; retention; timing thresholds; authority/responder integration; subscriptions; supported OS/device matrix; live operating targets.

**Exit gate:** Stage 3 can be approved with these items tracked as explicit decisions. None should be silently invented during implementation.
