-- The two indexes the monolith already has, under the same names, so that on its database this does nothing.
-- Foreign key columns are always indexed: order_items.order_id is one.
-- "my orders":            WHERE customer_id = ?
CREATE INDEX IF NOT EXISTS idx_orders_customer_id    ON sales.orders (customer_id);
-- "the lines of an order": WHERE order_id = ?   (and the foreign key's index)
CREATE INDEX IF NOT EXISTS idx_order_items_order_id  ON sales.order_items (order_id);
