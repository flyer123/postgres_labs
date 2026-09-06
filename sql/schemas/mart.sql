CREATE SCHEMA mart;

- ============================================================
-- Daily revenue aggregate
-- ============================================================

CREATE TABLE IF NOT EXISTS mart.daily_revenue (
    revenue_date       DATE PRIMARY KEY,
    ticket_count       INTEGER NOT NULL DEFAULT 0,
    total_revenue      NUMERIC(14, 2) NOT NULL DEFAULT 0,
    average_ticket     NUMERIC(14, 2),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- Passenger activity aggregate
-- ============================================================

CREATE TABLE IF NOT EXISTS mart.passenger_activity (
    passenger_id       INTEGER PRIMARY KEY,
    ticket_count       INTEGER NOT NULL DEFAULT 0,
    total_spent        NUMERIC(14, 2) NOT NULL DEFAULT 0,
    first_booking      TIMESTAMPTZ,
    last_booking       TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);