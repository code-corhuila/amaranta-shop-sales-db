-- Annex J, J.10 and rule RN-13 as a test: sales_app writes ONLY in schema sales, and inside it only what
-- the spec allows. Run by scripts/rebuild-check.sh as the administrator, switching role with SET LOCAL ROLE.
-- It leaves nothing behind (ROLLBACK), and any permission that is wider than intended stops it.
BEGIN;

-- Another domain's schema, standing for catalog or security.
CREATE SCHEMA other_domain;
CREATE TABLE other_domain.thing (id integer);
INSERT INTO other_domain.thing VALUES (1);

SET LOCAL ROLE sales_app;

-- What the service must be able to do.
INSERT INTO sales.orders (id, customer_id, created_by, total_amount)
VALUES ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000f2',
        '00000000-0000-0000-0000-0000000000f2', 2000);
INSERT INTO sales.order_items (order_id, product_id, product_name, unit_price_amount, quantity, subtotal_amount)
VALUES ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000f3', 'Cat toy', 2000, 1, 2000);
INSERT INTO sales.idempotency_key (key, order_id)
VALUES ('privileges-key-1', '00000000-0000-0000-0000-0000000000f1');
UPDATE sales.orders SET status = 'PAID' WHERE id = '00000000-0000-0000-0000-0000000000f1';
SELECT count(*) FROM sales.orders;

-- What it must NOT be able to do.
DO $$
BEGIN
    BEGIN UPDATE sales.order_items SET quantity = 2;
        RAISE EXCEPTION 'an order line can be edited (RN-10)';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN UPDATE sales.idempotency_key SET order_id = order_id;
        RAISE EXCEPTION 'an idempotency key can be rewritten';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN DELETE FROM sales.orders;
        RAISE EXCEPTION 'an order can be deleted';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN CREATE TABLE sales.rogue (id integer);
        RAISE EXCEPTION 'the service can create tables: structure belongs to this repository (rule 7)';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN PERFORM count(*) FROM sales.flyway_schema_history;
        RAISE EXCEPTION 'the service can read the migration history';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN PERFORM count(*) FROM other_domain.thing;
        RAISE EXCEPTION 'sales_app can read another domain (J.3.3 needs the owner grant)';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;

    BEGIN INSERT INTO other_domain.thing VALUES (2);
        RAISE EXCEPTION 'sales_app can write another domain (J.3.2: serious fault)';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$$;

-- sales_reader reads and nothing else.
RESET ROLE;
SET LOCAL ROLE sales_reader;
SELECT count(*) FROM sales.orders;
DO $$
BEGIN
    BEGIN INSERT INTO sales.orders (customer_id, created_by, total_amount)
          VALUES (gen_random_uuid(), gen_random_uuid(), 1);
        RAISE EXCEPTION 'sales_reader can write';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$$;
RESET ROLE;

-- The query of Annex J, J.10, as an assertion: no table outside schema sales is reachable by sales_app.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r' AND n.nspname NOT LIKE 'pg\_%' AND n.nspname NOT IN ('information_schema', 'sales')
          AND (has_table_privilege('sales_app', c.oid, 'SELECT') OR has_table_privilege('sales_app', c.oid, 'INSERT')
            OR has_table_privilege('sales_app', c.oid, 'UPDATE') OR has_table_privilege('sales_app', c.oid, 'DELETE'))
    ) THEN
        RAISE EXCEPTION 'sales_app reaches a table outside schema sales';
    END IF;
END
$$;

ROLLBACK;
