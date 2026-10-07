# Local database

This folder contains the versioned PostgreSQL/PostGIS migrations and a disposable Local database runner. The initial migration is a draft until it has been executed and reviewed against PostgreSQL/PostGIS.

## Start Local PostgreSQL/PostGIS

```sh
cd database
cp .env.example .env
# Replace POSTGRES_PASSWORD with a password used only for this local database.
docker compose up -d postgres
docker compose run --rm migrate
```

The database is exposed only on `127.0.0.1` at port `55432` by default. Change `POSTGRES_PORT` in `.env` if that port is already in use. Persistent data is stored in the Docker volume `psa-postgres-data`.

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
- This migration has not yet been executed against a PostgreSQL/PostGIS server in the current development environment.
