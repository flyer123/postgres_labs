CREATE SCHEMA staging;

CREATE TABLE staging.tickets_raw (
    ticket_no CHAR(13),
    passenger_id TEXT,
    flight_id INTEGER,
    price NUMERIC,
    load_batch UUID,
    loaded_at TIMESTAMP DEFAULT now()
);
