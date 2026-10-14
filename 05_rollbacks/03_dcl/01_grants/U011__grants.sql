DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sales_app') THEN
        REVOKE sales_writer FROM sales_app;
    END IF;
END
$$;

REVOKE ALL ON sales.orders, sales.order_items, sales.idempotency_key FROM sales_reader, sales_writer;
REVOKE USAGE ON SCHEMA sales FROM sales_reader, sales_writer;
