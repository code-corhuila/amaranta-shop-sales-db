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

The database of the sales domain, complete: schema, tables, roles and seed data. The structure of the database lives here and never in the API (rule 7).

## Depends on

`amaranta-shop-infra-postgres`: the single PostgreSQL instance and the `sales_app` login user.

## How to run

Nothing to run yet. Once the migrations land: start PostgreSQL with `amaranta-shop-infra-postgres`, copy `.env.example` to `.env` and run Flyway `migrate`. Running it twice must change nothing.

## Stack

PostgreSQL 16 with Flyway ([ADR-010](https://github.com/code-corhuila/amaranta-shop-docs/blob/main/05-architecture/decisions/records/ADR-010-engine-per-domain-sales-postgres-catalog-mongo.md)); template `db-postgres-flyway`. The structure starts from the monolith's migrations V004 and V006, plus the idempotency table of the checkout.

## Status

**Skeleton.** Only the base of a code repository is here (norm 5.1); nothing in it runs yet, and this README says so
on purpose. Next pull request: `feat/sales-schema`: schema `sales`, its tables, the `sales_reader` and `sales_writer` roles and the grant to `sales_app`.
