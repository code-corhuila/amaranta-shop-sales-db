-- The sales tables exactly as the NestJS monolith creates them: db/init/V001 (schema), V004 and V006 of
-- BrandowC/amaranta, commit 20cf133. It stands for "the database that already exists": the rebuild
-- check loads it, adds an order, and runs `migrate` over it. Never edit it to follow this repository.
CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.orders (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID        NOT NULL,
  channel         VARCHAR(20) NOT NULL DEFAULT 'ONLINE' CHECK (channel IN ('ONLINE','IN_STORE')),
  created_by      UUID        NOT NULL,
  total_amount    INTEGER     NOT NULL,
  status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','PAID','CANCELLED','FULFILLED')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE sales.order_items (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id            UUID        NOT NULL REFERENCES sales.orders(id) ON DELETE CASCADE,
  product_id          UUID        NOT NULL,
  product_name        VARCHAR(120) NOT NULL,
  unit_price_amount   INTEGER     NOT NULL,
  quantity            INTEGER     NOT NULL CHECK (quantity > 0 AND quantity <= 50),
  subtotal_amount     INTEGER     NOT NULL
);

CREATE INDEX idx_orders_customer_id ON sales.orders (customer_id);
CREATE INDEX idx_order_items_order_id ON sales.order_items (order_id);

ALTER TABLE sales.orders
  ADD COLUMN fulfillment_method VARCHAR(20) NOT NULL DEFAULT 'PICKUP'
             CHECK (fulfillment_method IN ('PICKUP', 'DELIVERY')),
  ADD COLUMN payment_method VARCHAR(20) NOT NULL DEFAULT 'CASH'
             CHECK (payment_method IN ('CASH', 'CARD', 'TRANSFER')),
  ADD COLUMN contact_name VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN contact_phone VARCHAR(20) NOT NULL DEFAULT '',
  ADD COLUMN delivery_address VARCHAR(255);

-- A real order, to prove that migrating over this database keeps what is in it.
INSERT INTO sales.orders (id, customer_id, created_by, total_amount, contact_name, contact_phone)
VALUES ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-0000000000b1', 45000, 'Existing Customer', '3000000000');
INSERT INTO sales.order_items (order_id, product_id, product_name, unit_price_amount, quantity, subtotal_amount)
VALUES ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000c1', 'Dog food 3 kg', 45000, 1, 45000);
