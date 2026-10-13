-- The idempotency table must refuse what the checkout relies on it to refuse. Run by
-- scripts/rebuild-check.sh; it leaves no data behind (ROLLBACK), and any broken guard stops it.
BEGIN;

INSERT INTO sales.orders (id, customer_id, created_by, total_amount)
VALUES ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000e1',
        '00000000-0000-0000-0000-0000000000e1', 1000);
INSERT INTO sales.idempotency_key (key, order_id)
VALUES ('retry-key-0001', '00000000-0000-0000-0000-0000000000d1');

DO $$
BEGIN
    BEGIN   -- the same key twice: the retry must find the first order, not create a second one
        INSERT INTO sales.idempotency_key (key, order_id)
        VALUES ('retry-key-0001', '00000000-0000-0000-0000-0000000000d1');
        RAISE EXCEPTION 'a second row was accepted for the same key';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;

    BEGIN   -- shorter than 8 characters (CA-C1.5)
        INSERT INTO sales.idempotency_key (key, order_id)
        VALUES ('short', '00000000-0000-0000-0000-0000000000d1');
        RAISE EXCEPTION 'a key shorter than 8 characters was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN   -- longer than 128 characters (CA-C1.5)
        INSERT INTO sales.idempotency_key (key, order_id)
        VALUES (repeat('k', 129), '00000000-0000-0000-0000-0000000000d1');
        RAISE EXCEPTION 'a key longer than 128 characters was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN   -- a key for an order that does not exist
        INSERT INTO sales.idempotency_key (key, order_id)
        VALUES ('orphan-key-0001', '00000000-0000-0000-0000-0000000000ff');
        RAISE EXCEPTION 'a key for a missing order was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
END
$$;

-- Deleting the order takes its key with it.
DELETE FROM sales.orders WHERE id = '00000000-0000-0000-0000-0000000000d1';
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM sales.idempotency_key WHERE key = 'retry-key-0001') THEN
        RAISE EXCEPTION 'the key survived the deletion of its order';
    END IF;
END
$$;

ROLLBACK;
