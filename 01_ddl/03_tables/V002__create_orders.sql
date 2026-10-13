-- The order aggregate. Money is in whole pesos, not minor units (spec checkout.md, OD-1), and the
-- table keeps the name `orders` (OD-4): both are the monolith's, and no data moves in this cut.
--
-- IF NOT EXISTS: the monolith's database already has this table, filled with real orders. The same
-- `migrate` must work on an empty database and on that one, so the baseline never recreates it.
-- No foreign key here: they go in 04_alter.
CREATE TABLE IF NOT EXISTS sales.orders (
    id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id        uuid        NOT NULL,   -- identity domain: referenced by id, no foreign key (J.3.4)
    channel            text        NOT NULL DEFAULT 'ONLINE'
                       CONSTRAINT chk_orders_channel CHECK (channel IN ('ONLINE', 'IN_STORE')),
    created_by         uuid        NOT NULL,   -- identity domain, same reason
    total_amount       integer     NOT NULL,
    status             text        NOT NULL DEFAULT 'PENDING'
                       CONSTRAINT chk_orders_status CHECK (status IN ('PENDING', 'PAID', 'CANCELLED', 'FULFILLED')),
    fulfillment_method text        NOT NULL DEFAULT 'PICKUP'
                       CONSTRAINT chk_orders_fulfillment_method CHECK (fulfillment_method IN ('PICKUP', 'DELIVERY')),
    payment_method     text        NOT NULL DEFAULT 'CASH'
                       CONSTRAINT chk_orders_payment_method CHECK (payment_method IN ('CASH', 'CARD', 'TRANSFER')),
    contact_name       text        NOT NULL DEFAULT ''
                       CONSTRAINT chk_orders_contact_name_length CHECK (char_length(contact_name) <= 100),
    contact_phone      text        NOT NULL DEFAULT ''
                       CONSTRAINT chk_orders_contact_phone_length CHECK (char_length(contact_phone) <= 20),
    delivery_address   text
                       CONSTRAINT chk_orders_delivery_address_length CHECK (char_length(delivery_address) <= 255),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);
