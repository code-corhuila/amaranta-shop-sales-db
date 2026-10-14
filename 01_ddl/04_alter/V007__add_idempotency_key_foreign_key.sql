-- The key points to the order it created and goes with it.
ALTER TABLE sales.idempotency_key
    ADD CONSTRAINT fk_idempotency_key_order
    FOREIGN KEY (order_id) REFERENCES sales.orders (id) ON DELETE CASCADE;
