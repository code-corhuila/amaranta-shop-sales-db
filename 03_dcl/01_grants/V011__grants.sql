-- Least privilege, table by table: the grants encode the rules of the spec, not only "read" and "write".
--   orders           read, insert, and update (an order is marked as paid)
--   order_items      read and insert only: a line never changes after the order is placed (RN-10, RN-12)
--   idempotency_key  read and insert only: a key is never rewritten (RN-15)
-- No DELETE anywhere, and nothing on flyway_schema_history: the service cannot rewrite the migration history.
-- Grants are NOT inherited by future tables on purpose: a new table brings its own GRANT in its own migration,
-- so what the service may do with it is a decision somebody reviewed.
GRANT USAGE ON SCHEMA sales TO sales_reader, sales_writer;

GRANT SELECT ON sales.orders, sales.order_items, sales.idempotency_key TO sales_reader;

GRANT SELECT, INSERT, UPDATE ON sales.orders TO sales_writer;
GRANT SELECT, INSERT ON sales.order_items, sales.idempotency_key TO sales_writer;

-- The domain grants its writing role to its own user (Annex J, J.7). It fails if sales_app does not exist:
-- the instance creates it before anything is migrated (J.5.2), and a silent skip would leave the service
-- with no access and no error.
GRANT sales_writer TO sales_app;
