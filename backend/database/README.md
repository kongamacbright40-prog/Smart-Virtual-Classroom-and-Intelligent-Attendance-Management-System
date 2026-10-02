# Database backup

`smart_classroom.sql` is a full PostgreSQL backup (tables + data) of the
`smart_classroom` database, made with `pg_dump`. Password-reset codes are not
included. It is already at the latest Alembic migration, so no
`alembic upgrade` is needed after restoring.

## Restore

Create an empty database first (pgAdmin: right-click **Databases → Create →
Database…**, or `CREATE DATABASE smart_classroom;`), then:

```bash
psql -h localhost -U postgres -d smart_classroom -f backend/database/smart_classroom.sql
```

Point the backend's `DATABASE_URL` (in `backend/.env`) at that database.
The file drops and recreates the tables, so restoring over an existing
database replaces its data.

## Make a new backup

```bash
pg_dump -h localhost -U smart_class -d smart_classroom --no-owner --no-privileges \
  --clean --if-exists --exclude-table-data=password_reset_codes \
  -f backend/database/smart_classroom.sql
```
