CREATE SCHEMA ops;

CREATE TABLE ops.events (
    event_id BIGSERIAL PRIMARY KEY,
    ticket_no CHAR(13) NOT NULL,
    event_type TEXT NOT NULL,
    event_time TIMESTAMP NOT NULL,
    source TEXT DEFAULT 'mobile',
    ingestion_time TIMESTAMP DEFAULT now()
);

CREATE TABLE ops.pipeline_runs (
    run_id UUID PRIMARY KEY,
    pipeline_name TEXT,
    status TEXT,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    rows_processed INTEGER
);