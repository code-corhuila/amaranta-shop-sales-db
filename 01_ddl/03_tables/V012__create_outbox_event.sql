-- The transactional outbox. An order and its OrderCreated record are committed in the same local
-- PostgreSQL transaction: a broker outage can delay delivery, but it cannot make an existing order
-- disappear from the integration stream.
CREATE TABLE sales.outbox_event (
    event_id      uuid        PRIMARY KEY,
    aggregate_id  uuid        NOT NULL REFERENCES sales.orders(id),
    event_type    text        NOT NULL CHECK (event_type IN ('OrderCreated')),
    payload       jsonb       NOT NULL,
    occurred_at   timestamptz NOT NULL,
    published_at  timestamptz,
    attempts      integer     NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    last_error    text
);
