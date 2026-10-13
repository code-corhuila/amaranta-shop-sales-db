#!/usr/bin/env bash
# The rebuild check (Annex A, "La verificacion de reconstruccion"; Annex J, J.6). Needs only Docker, and it
# is the same script the pull request runs, so a failure in CI can be reproduced on your machine:
#
#   bash scripts/rebuild-check.sh
#
# It starts a throwaway PostgreSQL 16 and proves, in order:
#   1. migrate builds the whole schema from an EMPTY database;
#   2. a second migrate applies nothing, and validate finds no edited migration;
#   3. every rollback script (05_rollbacks/) undoes the chain and leaves no schema behind;
#   4. the chain applies again after being rolled back;
#   5. the idempotency key refuses a repeated, malformed or orphan key;
#   6. sales_app can write in its own schema only, and sales_reader can only read;
#   7. migrate also works over a copy of the monolith's existing sales tables, and keeps their data.
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1   # Git Bash on Windows must not rewrite the container paths below

NAME="sales-db-check-$$"
ADMIN=amaranta_admin
PW="$(openssl rand -hex 16)"   # a throwaway instance with a throwaway password: nothing to version

docker run -d --rm --name "$NAME" -e POSTGRES_DB=amaranta -e POSTGRES_USER="$ADMIN" \
  -e POSTGRES_PASSWORD="$PW" postgres:16-alpine > /dev/null
trap 'docker rm -f "$NAME" > /dev/null 2>&1 || true' EXIT
# -h 127.0.0.1: during its first start the image runs a temporary server that only listens on the socket.
until docker exec "$NAME" pg_isready -h 127.0.0.1 -U "$ADMIN" -d amaranta > /dev/null 2>&1; do sleep 1; done

# Flyway runs in the database container's network namespace, so `localhost` is the database.
fw() {
  local db="$1"; shift
  docker run --rm --network "container:$NAME" -v "$PWD:/workspace:ro" \
    -e FLYWAY_URL="jdbc:postgresql://localhost:5432/$db" -e FLYWAY_USER="$ADMIN" -e FLYWAY_PASSWORD="$PW" \
    flyway/flyway:11.20 -workingDirectory=/workspace -configFiles=flyway.toml "$@"
}
sql() { local db="$1"; shift; docker exec -i "$NAME" psql -v ON_ERROR_STOP=1 -U "$ADMIN" -d "$db" "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

# The instance creates sales_app before anything is migrated (Annex J, J.5.2); here a bare stand-in does.
sql amaranta -c "create role sales_app login"

echo "== 1. migrate from an empty database"
fw amaranta migrate

echo "== 2. a second migrate applies nothing"
second="$(fw amaranta migrate)"
echo "$second"
echo "$second" | grep -q "No migration necessary" || fail "second migrate applied changes: the chain is not incremental"
fw amaranta validate

echo "== 3. every rollback, from the highest version down"
# Flyway Community does not undo: the rollback of V<n> is U<n> in 05_rollbacks/. The control table lives in
# the schema (J.6), so it goes first; the script that drops the schema would take it anyway.
sql amaranta -c "drop table sales.flyway_schema_history"
for f in $(find 05_rollbacks -name 'U*.sql' | awk -F/ '{print $NF" "$0}' | sort -r | cut -d' ' -f2); do
  echo "rollback $f"
  sql amaranta < "$f"
done
[ "$(sql amaranta -tAc "select count(*) from pg_namespace where nspname = 'sales'")" = 0 ] \
  || fail "the rollbacks left the schema behind"

echo "== 4. the chain applies again"
fw amaranta migrate

echo "== 5. the idempotency key refuses what the checkout relies on it to refuse"
sql amaranta < test/idempotency.sql

echo "== 6. sales_app writes only in schema sales, and only what the spec allows"
sql amaranta < test/privileges.sql

echo "== 7. migrate over the monolith's existing sales tables"
sql postgres -c "create database adopted"
sql adopted < test/fixtures/monolith-sales.sql
fw adopted migrate
[ "$(sql adopted -tAc "select count(*) from sales.orders")" = 1 ] || fail "the existing order was lost"
[ "$(sql adopted -tAc "select count(*) from sales.order_items")" = 1 ] || fail "the existing line was lost"
[ "$(sql adopted -tAc "select count(*) from pg_constraint where conrelid = 'sales.order_items'::regclass and contype = 'f'")" = 1 ] \
  || fail "order_items must keep exactly one foreign key"

echo "OK: the sales schema builds, rolls back and adopts the monolith's tables"
