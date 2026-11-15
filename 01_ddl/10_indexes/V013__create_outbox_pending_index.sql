-- A publisher reads only pending events, oldest first. The partial index keeps that poll bounded as
-- the history grows and does not index already published events.
CREATE INDEX idx_outbox_event_pending
    ON sales.outbox_event (occurred_at, event_id)
    WHERE published_at IS NULL;
