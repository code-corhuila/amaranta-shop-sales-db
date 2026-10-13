-- A line belongs to one order and goes with it. The monolith's table already has this key under a name
-- the engine generated, so it is only added when no key from order_items to orders exists.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'sales.order_items'::regclass
                     AND confrelid = 'sales.orders'::regclass
                     AND contype = 'f') THEN
        ALTER TABLE sales.order_items
            ADD CONSTRAINT fk_order_items_order
            FOREIGN KEY (order_id) REFERENCES sales.orders (id) ON DELETE CASCADE;
    END IF;
END
$$;
