-- The foreign key's index: deleting an order must not scan every key.
CREATE INDEX IF NOT EXISTS idx_idempotency_key_order_id ON sales.idempotency_key (order_id);
