# Local database

This folder contains the versioned PostgreSQL/PostGIS migrations and a disposable Local database runner. The initial migration was executed successfully against Local PostgreSQL 16 / PostGIS 3.4 on 2026-10-07 (see `docs/PROJECT_STATUS.md`); it remains subject to review before Pilot.

## Start Local PostgreSQL/PostGIS

```sh
cd database
cp .env.example .env
# Replace POSTGRES_PASSWORD with a password used only for this local database.
docker compose up -d postgres
docker compose run --rm migrate
```

On Apple Silicon the pinned Flyway image has no arm64 build; prefix the Compose commands with `DOCKER_DEFAULT_PLATFORM=linux/amd64`.

The database is exposed only on `127.0.0.1` at port `55432` by default. Change `POSTGRES_PORT` in `.env` if that port is already in use. Persistent data is stored in the Docker volume `psa-postgres-data` (Compose prefixes it with the project name, e.g. `database_psa-postgres-data`).

To stop the database while keeping its data:

```sh
docker compose down
```

To remove the Local database and its data after stopping it:

```sh
docker compose down --volumes
```

## Migration rules

- Flyway Community CLI is pinned in `compose.yaml`; SQL migrations use `V<number>__description.sql` names.
- Never edit a migration that has already run in Pilot. Add a forward migration instead.
- Local credentials are only for Local. Pilot must use separately provisioned credentials and a restricted migration job; do not reuse the Local user/password.
- The Local user owns its disposable database so it can install PostGIS and apply migrations. Production API/worker roles must be separate and must not have DDL privileges.
- V2 enforces, with database triggers, that `incident.incident_mode` cannot change after creation and that `incident_audit_event` and `system_audit_event` are append-only: inserts are allowed, UPDATE and TRUNCATE are always rejected.
- Audit retention: each audit row gets a server-computed `retain_until` at insert from the effective `retention_policy_version` (record classes `INCIDENT_AUDIT_EVENT` and `SYSTEM_AUDIT_EVENT`). With no policy the row is kept indefinitely. The only DELETE path is the `psa_audit_retention` role, usually through `purge_expired_audit_events(batch_limit)`, and the trigger allows it only for expired rows with no active `legal_hold` (record types `INCIDENT_AUDIT_EVENT`, `SYSTEM_AUDIT_EVENT`, or `INCIDENT` to hold all audit events of an incident).
- Legal holds vs purge: purge and the delete guard take a SHARE lock on `legal_hold` (through `lock_legal_holds_for_purge()`), so a purge never commits a deletion that races a committed hold: a hold writer in flight makes the purge wait, and hold writes wait while a purge transaction is open. Keep admin hold writes short and set lock timeouts for them and the retention job. The protocol requires READ COMMITTED (the default): the purge path and event-level hold writes raise an error under REPEATABLE READ or SERIALIZABLE. Holds on audit events that no longer exist are rejected, so a hold cannot be committed as an orphan after a purge.
- **Before audit retention is enabled:** a later migration must create the runtime and retention-job roles and grant the job EXECUTE on the purge function; the backend must create retention policies and legal holds; and role creation/ownership must be verified on the Pilot host. The table owner or a superuser can still disable triggers, so API/worker roles must not own tables or hold DDL/TRIGGER privileges.
- Run the V2 concurrency test (Local only; copies the database to a scratch DB and drops it): `tests/v2_legal_hold_concurrency_test.sh` (`NEGATIVE_CONTROL=1` and `NEGATIVE_CONTROL=isolation` must fail). Needs bash and perl.
- Run the V2 behavior test (Local only, rolled back): `docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -P pager=off' < tests/v2_audit_and_mode_integrity_test.sql`
