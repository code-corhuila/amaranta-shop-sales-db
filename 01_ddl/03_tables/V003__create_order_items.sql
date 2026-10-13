-- The lines of an order. product_name and unit_price_amount are a SNAPSHOT of the purchase (rule RN-12):
-- they are copied from the catalog when the order is placed and never change, so an order read a year
-- later says what it said that day. product_id is the catalog's identifier, with no foreign key (J.3.4).
CREATE TABLE IF NOT EXISTS sales.order_items (
    id                uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id          uuid    NOT NULL,
    product_id        uuid    NOT NULL,          -- catalog domain: by id only
    product_name      text    NOT NULL
                      CONSTRAINT chk_order_items_product_name_length CHECK (char_length(product_name) <= 120),
    unit_price_amount integer NOT NULL,
    quantity          integer NOT NULL
                      CONSTRAINT chk_order_items_quantity_range CHECK (quantity > 0 AND quantity <= 50),
    subtotal_amount   integer NOT NULL
);
