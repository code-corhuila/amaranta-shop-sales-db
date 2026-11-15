-- A publisher reads pending or retryable events, oldest first. The partial index keeps that poll bounded as
-- the history grows and does not index terminal published events.
CREATE INDEX idx_outbox_pending
    ON sales.outbox_messages (created_at, id)
    WHERE status IN ('PENDING', 'FAILED');
