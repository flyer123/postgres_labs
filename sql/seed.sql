COPY airports FROM '/docker-entrypoint-initdb.d/airports.csv' CSV;
COPY flights FROM '/docker-entrypoint-initdb.d/flights.csv' CSV;
COPY passengers FROM '/docker-entrypoint-initdb.d/passengers.csv' CSV;
COPY tickets FROM '/docker-entrypoint-initdb.d/tickets.csv' CSV;
COPY events FROM '/docker-entrypoint-initdb.d/events.csv' CSV;