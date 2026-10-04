-- Day 1 — Count events per type
  --  Your exercise is simply:
  --  Count the number of events for each event_type.

  SELECT
    event_type,
    COUNT(*) AS event_count
FROM events
GROUP BY event_type
ORDER BY event_type;

-- Day 2 — Join events to tickets
  -- Return the event ID, event type, event time, ticket ID, 
  -- ticket price, and passenger ID for events that have a matching ticket.

SELECT
    e.event_id,
    e.event_type,
    e.event_time,
    t.ticket_id,
    t.price AS ticket_price,
    t.passenger_id
FROM tickets t
INNER JOIN events e
    ON t.ticket_id = e.entity_id
ORDER BY e.event_id;

-- Day 3 -- not used tickets
  -- Find tickets that have a booking event but no checkin event

SELECT t.*
FROM tickets t
WHERE EXISTS (
    SELECT 1
    FROM events e
    WHERE e.entity_id = t.ticket_id
      AND e.event_type = 'booking'
)
AND NOT EXISTS (
    SELECT 1
    FROM events e1
    WHERE e1.entity_id = t.ticket_id
      AND e1.event_type = 'checkin'
);

-- Day 4 - wrong tickets
  -- Find tickets where cancel happened after checkin

  WITH enriched_tickets AS (
    SELECT
        t.ticket_id,
        e.event_type,
        LAG(e.event_type) OVER (
            PARTITION BY t.ticket_id
            ORDER BY e.event_time
        ) AS prev_event
    FROM tickets t
    INNER JOIN events e
        ON t.ticket_id = e.entity_id
)
SELECT *
FROM enriched_tickets et
WHERE et.event_type = 'cancel'
  AND et.prev_event = 'checkin';

-- Day 5 - Build an event timeline for every ticket.
  -- For each event, return: ticket_id, event_type,
     -- event_time, previous event type, previous event timestamp,
     -- time elapsed since the previous event

WITH full_events AS (
    SELECT
        t.ticket_id,
        e.event_type,
        e.event_time,
        LAG(e.event_type) OVER (
            PARTITION BY t.ticket_id
            ORDER BY e.event_time
        ) AS prev_event_type,
        LAG(e.event_time) OVER (
            PARTITION BY t.ticket_id
            ORDER BY e.event_time
        ) AS prev_event_time
    FROM tickets t
    INNER JOIN events e
        ON t.ticket_id = e.entity_id
)
SELECT
    ticket_id,
    event_type,
    event_time,
    prev_event_type,
    prev_event_time,
    event_time - prev_event_time AS time_elapsed
FROM full_events;


-- Day 6 - A customer reports that some ticket event streams are inconsistent.
  -- Rule 1: checkin cannot occur before booking
  -- Rule 2: cancel cannot occur before booking
  -- Rule 3: cancel cannot occur before checkin
  -- Duplicated events

WITH checkin_booking AS (
    SELECT DISTINCT e1.entity_id AS ticket_id
    FROM events e1
    WHERE EXISTS (
        SELECT 1
        FROM events e2
        WHERE e1.entity_id = e2.entity_id
          AND e1.event_type = 'booking'
          AND e2.event_type = 'checkin'
          AND e2.event_time < e1.event_time
    )
),
checkin_booking_report AS (
    SELECT
        'DQ-001' AS rule_id,
        cb.ticket_id,
        e.event_type,
        e.event_time
    FROM checkin_booking cb
    JOIN events e
        ON cb.ticket_id = e.entity_id
),

cancel_booking AS (
    SELECT DISTINCT e1.entity_id AS ticket_id
    FROM events e1
    WHERE EXISTS (
        SELECT 1
        FROM events e2
        WHERE e1.entity_id = e2.entity_id
          AND e1.event_type = 'booking'
          AND e2.event_type = 'cancel'
          AND e2.event_time < e1.event_time
    )
),
cancel_booking_report AS (
    SELECT
        'DQ-002' AS rule_id,
        cb.ticket_id,
        e.event_type,
        e.event_time
    FROM cancel_booking cb
    JOIN events e
        ON cb.ticket_id = e.entity_id
),

cancel_checkin AS (
    SELECT DISTINCT e1.entity_id AS ticket_id
    FROM events e1
    WHERE EXISTS (
        SELECT 1
        FROM events e2
        WHERE e1.entity_id = e2.entity_id
          AND e1.event_type = 'checkin'
          AND e2.event_type = 'cancel'
          AND e2.event_time < e1.event_time
    )
),
cancel_checkin_report AS (
    SELECT
        'DQ-003' AS rule_id,
        cc.ticket_id,
        e.event_type,
        e.event_time
    FROM cancel_checkin cc
    JOIN events e
        ON cc.ticket_id = e.entity_id
),

duplicated_events AS (
    SELECT
        entity_id AS ticket_id,
        event_type,
        COUNT(*) AS dupl_events
    FROM events
    GROUP BY entity_id, event_type
    HAVING COUNT(*) > 1
),
duplicated_events_report AS (
    SELECT
        'DQ-004' AS rule_id,
        de.ticket_id,
        e.event_type,
        e.event_time
    FROM duplicated_events de
    JOIN events e
        ON de.ticket_id = e.entity_id
       AND de.event_type = e.event_type
)

SELECT * FROM checkin_booking_report
UNION ALL
SELECT * FROM cancel_booking_report
UNION ALL
SELECT * FROM cancel_checkin_report
UNION ALL
SELECT * FROM duplicated_events_report
ORDER BY ticket_id, event_time, rule_id;