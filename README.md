# amaranta-shop-sales-db

> sales bounded context: database (schema, seeds, migrations)

Part of the **Amaranta Shop** distributed system — team `amaranta-shop`, Grupo 2.
Governance and documentation live in [`amaranta-shop-docs`](https://github.com/code-corhuila/amaranta-shop-docs).

## Branching

Three permanent branches. **None of them accepts a direct commit** — you enter through a child
branch and leave through a Pull Request.

```
develop  <--PR--  feat/... fix/... chore/...
qa       <--PR--  qa/...
main     <--PR--  release/...  hotfix/...
```

Promotion happens **by re-application** (`git cherry-pick -x`), never by merging one permanent
branch into another: `merge develop -> qa` and `merge qa -> main` do not exist in this model.

`main` requires **1 approval from `ariel5253`**. On `develop` and `qa` the team sets its own review
rule.

Full policy: `00-governance/branching-policy.md` in `amaranta-shop-docs`.

## Role in the system

The database of the **sales** domain: schema, tables, roles and grants. It owns the *structure* of what the
checkout stores; `amaranta-shop-sales-api` owns the *data* and never versions a table (Annex J, J.3.2).
No database server is defined here: the single PostgreSQL instance lives in `amaranta-shop-infra-postgres`,
and this repository only brings the runner that migrates it.

## Depends on

`amaranta-shop-infra-postgres`: the instance, the `pgcrypto` extension and the `sales_app` login user.
Sales refers to customers and products **by id only**, with no foreign key to another domain (J.3.4).

## Stack

PostgreSQL 16 and **Flyway** Community, which does not undo: every migration has its rollback script
([ADR-010](https://github.com/code-corhuila/amaranta-shop-docs/blob/main/05-architecture/decisions/records/ADR-010-engine-per-domain-sales-postgres-catalog-mongo.md)).

## Layout

```
flyway.toml                  the four families, naming validation, baseline, the control table's schema
01_ddl/  02_dml/  03_dcl/  04_tcl/   structure, data, access control, recorded exceptional operations
05_rollbacks/                U<version>__<name>.sql: the rollback of every V<version>
deploy/compose.yml           the migration runner only: no database service, no volume
scripts/rebuild-check.sh     the rebuild check; test/fixtures/ holds the monolith's tables
```

**The version number is the order**, one sequence for the whole repository whatever the folder: the next
migration takes the next number, be it DDL, DML or DCL. An applied migration is never edited (its checksum
would break every environment); a correction is a new migration.

## Where the tables come from

The monolith already created them and nothing moves
([spec](https://github.com/code-corhuila/amaranta-shop-docs/blob/main/specs/checkout.md), DP-7), so this
chain works on an **empty** database and on **the monolith's**:

| Monolith | Here |
|---|---|
| `V001` schema `sales` | `V001` |
| `V004` `orders` + `V006` its checkout columns | `V002`, in one table |
| `V004` `order_items` and the two indexes | `V003`, its key in `V004`, the indexes in `V005` |

Baseline files use `IF NOT EXISTS` and Flyway baselines at version `0`, so `migrate` over the monolith's
tables skips what exists and keeps every order. Only names differ there (generated constraint names,
`varchar(n)` instead of `text` with a `CHECK`), so **a migration never references a baseline constraint by
name**. Two declared deviations, both from the spec: money stays in **whole pesos** (OD-1) and the tables keep
their **plural names** (OD-4); a rename is expand-then-contract, later, with its own ADR.

## The idempotency key

`sales.idempotency_key` is the database half of a retry-safe checkout (RN-15, CA-C1.6). `sales-api` writes
the order and its key in one transaction; a second request with the same key hits the primary key, and the
service answers with the order that already exists. The table also refuses keys outside 8-128 characters
and keys of an order that does not exist. `test/idempotency.sql` proves it, inside the rebuild check.

## Roles and grants

`sales_reader` and `sales_writer` are `NOLOGIN` roles that carry permissions; `sales_app`, the login user the
service connects with, is created by the infra repository from a secret, and `V011` grants it `sales_writer`.
The grants are table by table and encode the spec: `orders` can be read, inserted and updated (it is marked
as paid); `order_items` and `idempotency_key` can only be read and inserted, because a line and a key never
change (RN-10, RN-12, RN-15); nothing can be deleted; the service cannot create tables or read the migration
history. A new table brings its own `GRANT` in its own migration. Migrating before `sales_app` exists fails on
purpose. `test/privileges.sql` proves all of it, and that `sales_app` reaches no table outside `sales`
(Annex J, J.10), inside the rebuild check.

## How to run

```bash
docker network create platform                              # once per machine
cd ../amaranta-shop-infra-postgres && cp env/dev.env.example env/dev.env   # then set the passwords
docker compose --env-file env/dev.env up -d --wait postgres
docker compose --env-file env/dev.env run --rm sales-db-migrate            # also: info, validate
```

It works once the infra repository `include`s `deploy/compose.yml` (a commented line there). `clean` is
disabled. In `qa` and `main` never `docker compose down -v`, and back up before migrating (J.5.4).

## The rebuild check

`bash scripts/rebuild-check.sh` needs only Docker and is what the pull request runs. On a throwaway
PostgreSQL it proves that `migrate` builds the schema from empty, that a second `migrate` applies nothing,
that the rollbacks leave no schema behind, that the chain applies again, and that it adopts a copy of the
monolith's tables without losing their data.

## Status

Complete for the checkout: schema, `orders`, `order_items`, `idempotency_key`, roles and grants. A change to
any of them is a new migration with its rollback. Next in the system: `amaranta-shop-sales-api` connects as
`sales_app` and its integration tests run against this schema.
