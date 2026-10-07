# Project Status — Personal Safety App

Date: 2026-10-07
Branch: `main`
Commit: base `a76eb61`; V2 migration, tests and docs founder-approved 2026-10-07 and committed on `main` (hash recorded after publication)

## Work actually completed

- Stage 0 idea intake and Stage 1 desk discovery were completed in ChatGPT. The Stage 1 discovery record is now in `docs/discovery/STAGE_1_DISCOVERY.md`.
- Approved Stage 2 product definition: continuous safety monitoring; trips with or without check-ins; automatic SOS after a missed scheduled check-in; family-head visibility of accepted members' consented locations; family-circle SOS SMS with coordinates and monitoring-dashboard location; Lagos pilot with no fixed participant count; 24-hour monitoring goal; partner API trial after the consumer/monitoring pilot.
- Created this status handoff and `CLAUDE.md` to require future status updates.
- Published and verified the approved project documentation and database foundation on GitHub `main` in commit `35adaf3`.
- Drafted Stage 3 functional requirements, user stories with acceptance criteria, non-functional requirements and requirements traceability.
- Reviewed Stage 3 against the approved product definition, incorporated founder changes and received founder approval.
- Corrected the delivery framework after Stage 3 was mistakenly published as a draft before founder review; future stages require approval before commit or publication.
- Incorporated founder review decisions into the local Stage 3 drafts: family-only minor onboarding; PIN-based SOS cancellation; configurable check-in rules, location frequency, 60-day default retention and subscription packages; low-battery guidance; post-version-1 USSD; and 24-hour dashboard capability.
- Added local draft requirements for operator-controlled Critical authority escalation, configurable location freshness, multi-source device location, encrypted offline evidence, retry after reconnection and battery-adaptive acquisition.
- Founder approved Stage 3 on 2026-10-06, excluding USSD from version 1. USSD is paused and tracked in `docs/tags/USSD.md`.
- Added the corrected stage-gate rule: founder review and approval must happen before commit or publication.
- Founder approved the Stage 4 safety-sensitive, high-criticality classification and Senior code-readability engineering profile on 2026-10-06.
- Founder approved Stage 5: native Kotlin Android, native Swift iPhone, Kotlin/Spring Boot backend, React/Next.js dashboard, Railway hosting and Neon PostgreSQL/PostGIS.
- Approved incremental deployment of each completed and tested vertical feature slice instead of a big-bang release.
- Revised Stage 6 architecture after criticality review. Added durable scheduler recovery, outbox delivery semantics, authorization/PIN security, offline evidence protections, retention/deletion, outage degradation, backup/recovery gates, and clarified Grafana, Swagger/OpenAPI and CI/CD controls.
- Founder approved the Stage 6 architecture baseline on 2026-10-07 for MVP and controlled-pilot design. Approval does not establish production readiness, measured scale or operational coverage.
- Founder approved the two-environment model: Local for development/testing and Pilot for hosted practice plus approved live-pilot use. Updated the architecture, engineering profile, technology selection, FR-115 and partner product wording. Practice and live incidents are separated through data, permissions, dashboards and provider routing within Pilot.
- Committed the two-environment updates as `ca65852`. Attempted to publish to GitHub, but the configured network proxy was unavailable.
- Founder approved Stage 7 Engineering Standards on 2026-10-07. Committed as `e8f12e4`; the standards document is now the implementation baseline. No implementation or CI has been completed or tested.
- Attempted to publish `e8f12e4` to GitHub; the configured network proxy remained unavailable.
- Drafted and received founder approval for Stage 8 logical database design at `docs/database/STAGE_8_DATABASE_DESIGN.md`.
- Updated Stage 8 database design with founder decisions, including one SMS per resolved person per incident across multiple family/trusted-circle relationships, while preserving all eligibility reasons in the incident snapshot/audit. Removed this resolved item from the numbered decision list; the rule remains in the safety-critical constraints.
- Replaced the mismatched numbered decision summary with a status table matching the founder's original eight questions; each is marked approved/configurable, and trusted-contact rules reflect the later updated flow.
- Clarified product, FR, stories, traceability and architecture: account deletion dissolves a family headed by the deleted user, stops that family's monitoring, notifies family members via SMS/email, and does not notify trusted-circle members. The single web admin dashboard includes incident monitoring and broader settings/configuration, subscriptions, retention, user/family administration and audit review.
- Added initial Flyway migration `database/migrations/V1__initial_schema.sql`, PostGIS Local Docker Compose setup, environment example, ignore rules and database setup instructions. Flyway Community SQL migrations are selected. Migration execution against PostgreSQL/PostGIS remains unverified.
- Executed `V1__initial_schema.sql` against disposable Local PostgreSQL 16.4 / PostGIS 3.4 with Flyway 13.9.0 via the project Docker Compose setup; it applied cleanly. Findings are listed under Tests and Blockers. No design or migration change was made.
- Added `database/migrations/V2__enforce_incident_mode_and_audit_integrity.sql` (V1 untouched), revised after founder review of audit retention:
  - A trigger rejects any change to `incident.incident_mode`.
  - `incident_audit_event` and `system_audit_event` accept inserts; UPDATE and TRUNCATE are always rejected for every role.
  - DELETE is rejected for all roles except the NOLOGIN role `psa_audit_retention`, and even for that role a row trigger permits it only when `retain_until` has passed and no active `legal_hold` covers the event (or, for incident audit events, the incident). The retention role has only SELECT/DELETE on the audit tables and SELECT on `legal_hold`; no UPDATE/TRUNCATE.
  - Both audit tables gained `retain_until` and `retention_policy_version_id`, set by an insert trigger from the effective `retention_policy_version` for class `INCIDENT_AUDIT_EVENT`/`SYSTEM_AUDIT_EVENT` using server time (caller-supplied values are discarded). No effective policy means `retain_until` is NULL and the row is kept indefinitely.
  - `purge_expired_audit_events(batch_limit)` (SECURITY DEFINER, owned by the retention role, batch 1-10000, EXECUTE not granted to PUBLIC) is the controlled cleanup path.
  - Added `database/tests/v2_audit_and_mode_integrity_test.sql` (41 checks, rolled-back transaction, Local only).
  - Legal-hold/purge concurrency control: the purge function and the delete guard call `lock_legal_holds_for_purge()` (a SECURITY DEFINER helper, executable only by the retention role) which takes `LOCK TABLE legal_hold IN SHARE MODE`. This waits for in-flight hold writers and blocks new hold writes until the purge transaction ends, and the guard re-reads holds after the lock with a fresh snapshot. A direct `LOCK` by the retention role is impossible without write privileges on `legal_hold`, hence the helper. Hold commits first: the row is kept. Purge commits first: a later or woken hold on the purged event is rejected (no orphan). Overlapping purges that select the same rows wait on each other's row locks until the first commits.
  - Isolation level: the lock protocol is only correct under READ COMMITTED (fresh statement snapshot after the lock wait). The first concurrency tests ran only at READ COMMITTED (psql default, never set explicitly). Under REPEATABLE READ/SERIALIZABLE the snapshot predates the wait and a covered row can be deleted (shown by the negative control below). The helper therefore raises `invalid_transaction_state` unless `transaction_isolation` is `read committed`, which covers the purge function and the delete guard. The retention job must use the default READ COMMITTED.
  - Orphan holds: trigger `trg_legal_hold_target` (`guard_legal_hold_target`, SECURITY DEFINER) rejects an active hold (insert, or update that re-activates) on an `INCIDENT_AUDIT_EVENT`, `SYSTEM_AUDIT_EVENT` or `INCIDENT` target that does not exist (`foreign_key_violation`), checked with a fresh snapshot after any wait on a purge. Event-level holds must also be written under READ COMMITTED (rejected otherwise). Other `legal_hold.record_type` values are not validated.
  - Added `database/tests/v2_legal_hold_concurrency_test.sh` (two coordinated psql sessions on a scratch copy of the migrated database; optional `NEGATIVE_CONTROL=1`).
- Founder approved V2 (incident-mode immutability, append-only audit with controlled retention, legal-hold/purge concurrency, READ COMMITTED enforcement, orphan-hold guard) on 2026-10-07. Approval covers the Local-validated migration and tests only; the blockers below must be resolved before audit retention is enabled or Pilot deployment.
- Fixed a stale commit reference in this file and updated `database/README.md` with the verified status and the Apple Silicon platform note.
- No mobile app, backend API or dashboard feature has been implemented yet.

## Tests actually executed

Local database validation, 2026-10-07 (Docker 29.4.1, Compose v5.1.3, disposable Local DB, synthetic data only):

- `docker compose up -d postgres` (postgis/postgis:16-3.4): healthy.
- `docker compose run --rm migrate`: Flyway validated and applied V1 (`success = true`, ~0.7s). On Apple Silicon the Flyway image has no arm64 manifest, so it required `DOCKER_DEFAULT_PLATFORM=linux/amd64` (no file change); Postgres also runs under amd64 emulation.
- Schema: 50 application tables (plus `flyway_schema_history` and PostGIS `spatial_ref_sys`), 74 foreign keys, 77 unique constraints, 123 check constraints, 38 declared indexes in the migration, one GiST index (`ix_location_position_gist` on `location_sample.position`, geography Point 4326). Matches the 50 `CREATE TABLE` statements.
- Replay: re-running migrate was a no-op ("up to date"). `docker compose down --volumes`, restart and re-migrate on a clean database succeeded with the same 52 tables.
- Constraint checks inside a rolled-back transaction, all PASS: verified-identifier uniqueness (unverified duplicates allowed), idempotency key scoped by principal/operation, `incident_mode` domain check, one recipient per incident, one delivery per recipient/channel/purpose, provider-callback uniqueness, user delete restricted by incident references, PostGIS insert and `ST_DWithin` query.
- Static/repo checks from earlier work still stand: 97 functional requirements, 16 user stories, no duplicate IDs.
- Not run: application tests (no application code exists), concurrency tests, query plans on representative data, runtime-role privilege tests, partitioning, migration from a previous released schema (none exists), CI.
- V2 verification (same Local setup, 2026-10-07; revised V2 with audit retention path):
  - Migration: fresh database applied V1+V2; V1-only database upgraded to V2; replay was a no-op at v2; V1 file unmodified.
  - `database/tests/v2_audit_and_mode_integrity_test.sql`: 41 PASS / 0 FAIL on the fresh database and again on the V1-to-V2 upgraded database (one earlier test-design error was fixed: SET ROLE is checked against the session user, so the test now authenticates as the app role first).
  - Blocked for an ordinary role with full table privileges (UPDATE/DELETE/TRUNCATE granted, so triggers are what block): incident-mode change (single and bulk); UPDATE of audit rows and of `retain_until`; DELETE of even an expired audit row on both tables; TRUNCATE on both tables; setting a GUC to unlock deletion; calling the purge function; reading `legal_hold`; SET ROLE to the retention role from an app session.
  - Retention role used directly: UPDATE and TRUNCATE rejected; DELETE rejected for unexpired, no-deadline, row-held and incident-held rows (both tables) and for a bulk DELETE containing any ineligible row; all ineligible rows verified still present.
  - Permitted cleanup via `purge_expired_audit_events`: removed expired unheld rows in both tables; kept held, unexpired, NULL-deadline and normally inserted (30-day) rows; rows became removable after their hold was released; a run with nothing eligible was a no-op; `batch_limit` 2 deleted exactly 2; limits 0 and 10001 rejected; callable only by a role granted EXECUTE.
  - Inserts allowed for the ordinary role on both audit tables; a backdated caller-supplied `retain_until` was overridden with the server-computed ~30-day value and policy version.
  - Concurrency (`database/tests/v2_legal_hold_concurrency_test.sh`, 40 checks): 40 PASS / 0 FAIL on the fresh database and 40 PASS / 0 FAIL on the V1-to-V2 upgraded database. Sessions A (hold writer) and B (purge) were asserted to run at READ COMMITTED; S1-S5 and S3c-S3e run at READ COMMITTED, S6 deliberately uses REPEATABLE READ and SERIALIZABLE. Scenarios: S1 hold committed before purge, row kept; S2 hold written but uncommitted when purge starts, purge verified waiting, then the committed hold protects the row; S3 hold attempted while a purge transaction is open: write verified waiting and not committable, purge commits first and removes the row, the woken hold is rejected as an orphan and no hold row exists; S3c a hold attempted after the purge is rejected; S3d re-activating a released hold on a purged event is rejected; S3e an event-level hold written under REPEATABLE READ is rejected; S3b purge rolls back, hold commits, row kept and survives a later purge; S4 direct DELETE by the retention role whose statement began before the hold committed waits, then is rejected; S5 two purges with no common rows do not block each other; S6 purge and direct DELETE under REPEATABLE READ and SERIALIZABLE (and with a session default of REPEATABLE READ) return immediately with an error while a hold is in flight, and the covered row survives after the hold commits.
  - Negative controls (same script, failed checks are the expected outcome): locks removed, 19 PASS / 21 FAIL (including S2 and S4 deleting covered rows, and orphan holds committing); only the READ COMMITTED enforcement removed (`NEGATIVE_CONTROL=isolation`), 30 PASS / 10 FAIL, including "row covered by committed hold retained" failing for purge under REPEATABLE READ and SERIALIZABLE and for direct DELETE under REPEATABLE READ, i.e. the isolation race is real without the enforcement. An earlier version of S6 ended in ROLLBACK and so could not show the deletion; it was corrected to COMMIT before these results.
  - Existing 41-check suite re-run after the isolation and orphan-hold changes: 41 PASS / 0 FAIL on both databases. Migration replay: no-op at v2 on both.
  - Not tested: pooled-connection (e.g. transaction-pooler) isolation settings, purge performance at volume, lock wait timeouts/`lock_timeout` settings for the retention job and admin hold writes, multi-statement admin transactions that touch `legal_hold` for a long time (they delay purges), failover behavior, Neon permissions, behavior under superuser/owner bypass, integration with real application roles (none exist).
- V1-only findings (RESOLVED by V2 as shown above; recorded for history):
  - `incident.incident_mode` can be changed by UPDATE; Stage 8 constraint 4 says it is immutable. No DB trigger enforces this.
  - `incident_audit_event` rows can be UPDATEd; Stage 8 constraint 13 says application roles cannot edit audit events. No trigger or role privileges exist (V1 has no GRANT/REVOKE/ROLE statements).

## Deployment/demo

- None.

## Current blockers

- **Must be resolved before audit retention is enabled or any real audit data is stored:** (a) V3 must define the least-privilege runtime roles (API, worker, retention job) and grant the retention job login/EXECUTE on `purge_expired_audit_events` only, plus run it and admin hold writes at READ COMMITTED (enforced for the purge and event-level holds; confirm the connection pool does not override it) and set `lock_timeout`/`statement_timeout` for it and for admin legal-hold writes (a long-open transaction writing `legal_hold` delays purges, and an open purge delays hold writes); (b) the admin dashboard/backend must create `retention_policy_version` rows for classes `INCIDENT_AUDIT_EVENT` and `SYSTEM_AUDIT_EVENT` (until then rows are kept forever by design) and create/release `legal_hold` rows using the record types documented in V2; (c) existing audit rows inserted before a policy exists have `retain_until` NULL and cannot be given a deadline because UPDATE is blocked, so any backfill needs a separately reviewed owner-run migration; (d) creating `psa_audit_retention` and `ALTER FUNCTION ... OWNER` need privileges not yet verified on Neon; (e) audit retention periods and legal bounds still need founder/legal confirmation.
- V2 triggers can be disabled by the table owner or a superuser; runtime roles must not own tables or hold DDL/TRIGGER privileges.
- Flyway image lacks arm64; Local on Apple Silicon needs `DOCKER_DEFAULT_PLATFORM=linux/amd64` (emulation). Consider a Flyway tag with an arm64 build or document the override permanently.
- Production-scale capacity, recovery, security and device behavior remain untested because implementation has not started.
- A 24-hour staffing rota, backup coverage and response process are not yet verified. A live monitored pilot cannot claim 24-hour coverage until those are in place.
- Field interviews and live alert and location tests remain open.
- Child-consent verification, separate duress behavior, default freshness values, the detailed Critical escalation playbook and supported device matrix require implementation-stage resolution.
- USSD is intentionally paused until explicitly resumed through the `USSD` tag.
- The 24-hour staffing rota, provider agreements and live location/battery/alert field evidence remain unavailable.

## Next three recommended tasks

1. Review and approve V2, then commit; define and test least-privilege runtime roles (non-owner API/worker/retention job, no DDL/TRIGGER) in a V3 migration, closing the blocker above.
2. Wire the migration and `database/tests/` scripts into CI against disposable PostgreSQL/PostGIS, and verify role creation/ownership on Neon.
3. Start the Spring Boot repository foundation (pinned Flyway PostgreSQL module and JDBC driver) with integration tests against the Local database.

Update this file after every coding task with the date, branch and commit, verified work, tests actually run and results, deployment/demo URL if any, blockers, and the next three tasks. Do not mark untested implementation complete. Consult this file and the relevant product and technical source-of-truth documents before planning implementation.
