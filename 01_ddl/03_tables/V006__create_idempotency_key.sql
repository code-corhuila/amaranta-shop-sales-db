-- One row per client request that created an order (rule RN-15). A retried request carries the same
-- Idempotency-Key, finds its row and gets back the order it already created instead of a second one.
-- The primary key is what makes this safe under concurrency: two identical requests cannot both insert it.
-- The service writes the order and its key in ONE transaction. No foreign key here: it goes in 04_alter.
CREATE TABLE sales.idempotency_key (
    key        text        PRIMARY KEY
               CONSTRAINT chk_idempotency_key_length CHECK (char_length(key) BETWEEN 8 AND 128),
    order_id   uuid        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
