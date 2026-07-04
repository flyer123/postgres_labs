-- Day 1
  -- Take Day 6 from previous week. Now create: session_id

for each passenger.
with etc as (select passenger_id, booking_time, lag(booking_time) over(partition by passenger_id order by booking_time) as prev_session,
extract(epoch from(booking_time - lag(booking_time) over(partition by passenger_id order by booking_time))) / 3600 as gap,
case when extract(epoch from(booking_time - lag(booking_time) over(partition by passenger_id order by booking_time))) / 3600 > 48 then 1
else 0 end as start_of_new_session 
from tickets
)
select *, sum(start_of_new_session) over(partition by passenger_id order by booking_time) as session_id
from etc;

-- Day 2
  -- For every event: Show: previous event, next event
  -- Find: cancel after checkin
with etc as(
 select passenger_id, event_type, lead(event_type) over (partition by passenger_id order by event_time) as next_event,
 event_time,
 lead(event_time) over(partition by passenger_id order by event_time) as next_event_time
from tickets t inner join events e on t.ticket_id=e.entity_id )
select * from etc
where event_type='checkin' and next_event='cancel';

-- Day 3
  -- Find: Number of consecutive days passenger booked.
with booking_dates as (select passenger_id, booking_time::date as booking_date from tickets group by 1,2),
streaks as (select passenger_id, booking_date,
case when booking_date - lag(booking_date) over(partition by passenger_id order by booking_date) = 1 then 0
else 1 end as new_streak from booking_dates), 
streak_groups as (select passenger_id, booking_date, new_streak, sum(new_streak) over(partition by passenger_id order by booking_date) as streak_id
from streaks) select passenger_id, streak_id, count(*) from finals group by 1,2 order by 1,2;


-- Day 4
  -- For every passenger: Determine: first booking month,
  -- Then: months since first booking
with enriched as (select passenger_id, booking_time, first_value(booking_time)
over(partition by passenger_id order by booking_time) as first_booking from tickets)
select passenger_id, booking_time, first_booking,
(extract(year from booking_time) - extract(year from first_booking)) * 12 +
(extract(month from booking_time) - extract(month from first_booking)) as diff_month from enriched;

-- Day 5
  -- For every booking: 
    -- Calculate:
      -- average price of previous 5 bookings
SELECT
    ticket_id,
    flt_id,
    price,
    AVG(price) OVER (
        ORDER BY booking_time
        ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    ) AS average_price
FROM tickets;

-- Day 6
 -- Problem:
 SELECT
    SUM(t.price) AS revenue
FROM tickets t
JOIN events e
    ON t.ticket_id = e.entity_id;

 -- solution:
 select sum(price) from tickets t
where exists (select 1 from events e where t.ticket_id=e.entity_id);


