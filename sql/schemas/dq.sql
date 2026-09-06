CREATE SCHEMA dq;

CREATE TABLE dq.validation_results (
    run_id UUID,
    rule_id TEXT,
    severity TEXT,
    ticket_no CHAR(13),
    message TEXT,
    detected_at TIMESTAMP DEFAULT now()
);

CREATE TABLE dq.error_injection (
    error_id SERIAL PRIMARY KEY,
    ticket_no CHAR(13),
    error_type TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now()
);