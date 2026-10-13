-- "my orders, newest first, one page at a time" (HU-C6): WHERE customer_id = ? ORDER BY created_at DESC.
-- orders already holds data, so the index is built CONCURRENTLY and alone in its migration: inside a
-- transaction it would block every checkout while it builds. flyway.toml turns Flyway's transactional lock
-- off so that this statement does not wait for Flyway's own transaction. The older idx_orders_customer_id
-- is now redundant; it goes in a later release (expand, then contract).
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_id_created_at
    ON sales.orders (customer_id, created_at DESC);
