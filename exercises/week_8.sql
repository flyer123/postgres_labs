-- Day 1 — Count events per type
  --  Your exercise is simply:
  --  Count the number of events for each event_type.


-- Day 2 — Join events to tickets
  -- Return the event ID, event type, event time, ticket ID, 
  -- ticket price, and passenger ID for events that have a matching ticket.

-- Day 3 -- not used tickets
  -- Find tickets that have a booking event but no checkin event

-- Day 4 - wrong tickets
  -- Find tickets where cancel happened after checkin

-- Day 5 - Build an event timeline for every ticket.
  -- For each event, return: ticket_id, event_type,
     -- event_time, previous event type, previous event timestamp,
     -- time elapsed since the previous event

-- Day 6 - A customer reports that some ticket event streams are inconsistent.
  -- Rule 1: checkin cannot occur before booking
  -- Rule 2: cancel cannot occur before booking
  -- Rule 3: cancel cannot occur before checkin
  -- Duplicated events