CREATE TABLE flights (
    flt_id SERIAL PRIMARY KEY,
    departure_airport TEXT,
    arrival_airport TEXT,
    departure_time TIMESTAMP,
    arrival_time TIMESTAMP,
    status TEXT
);

CREATE TABLE passengers (
    passenger_id SERIAL PRIMARY KEY,
    country TEXT,
    signup_date DATE
);

CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    flt_id INT REFERENCES flights(flt_id),
    passenger_id INT REFERENCES passengers(passenger_id),
    price NUMERIC,
    booking_time TIMESTAMP
);


CREATE TABLE airports (
    airport_code TEXT PRIMARY KEY,
    city TEXT,
    country TEXT
);

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    event_type TEXT,
    entity_id INT,
    event_time TIMESTAMP
);