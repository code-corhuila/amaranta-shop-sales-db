-- The service may append events and record delivery progress. It cannot alter the aggregate, type,
-- payload or occurrence time after the transaction that created them.
GRANT SELECT ON sales.outbox_event TO sales_reader;
GRANT SELECT, INSERT ON sales.outbox_event TO sales_writer;
GRANT UPDATE (published_at, attempts, last_error) ON sales.outbox_event TO sales_writer;
