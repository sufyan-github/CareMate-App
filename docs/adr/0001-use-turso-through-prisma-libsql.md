---
status: accepted
---

# Use Turso through Prisma's libSQL Adapter

CareMate uses the User-provided Turso database instead of the PostgreSQL deployment assumed by the original specification. The backend retains Prisma as the persistence Interface and uses Prisma's official libSQL Adapter, with file-based SQLite for deterministic local tests and Turso for configured staging/production environments; this preserves Module Locality but accepts SQLite concurrency and migration constraints that must be tested explicitly.
