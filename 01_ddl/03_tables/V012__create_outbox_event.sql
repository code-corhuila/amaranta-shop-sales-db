-- The transactional outbox, using the platform-wide outbox_messages contract. An order and its OrderCreated record are committed in the same local
-- PostgreSQL transaction: a broker outage can delay delivery, but it cannot make an existing order
-- disappear from the integration stream.
CREATE TABLE sales.outbox_messages (
    id             uuid        PRIMARY KEY,
    event_type     text        NOT NULL CHECK (event_type IN ('OrderCreated')),
    aggregate_type text        NOT NULL CHECK (aggregate_type = 'Order'),
    aggregate_id   uuid        NOT NULL REFERENCES sales.orders(id),
    topic          text        NOT NULL CHECK (topic = 'sales.order.created'),
    payload_json   jsonb       NOT NULL,
    metadata_json  jsonb       NOT NULL DEFAULT '{}'::jsonb,
    status         text        NOT NULL DEFAULT 'PENDING'
                               CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
    attempts       integer     NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    last_error     text,
    created_at     timestamptz NOT NULL,
    published_at   timestamptz
);
