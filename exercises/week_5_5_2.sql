-- Day 1
  -- runk passengers by spending in each country
with psg_totals as (select passenger_id, sum(price) as psg_total from tickets group by 1)
select p.passenger_id, country, psg_total, dense_rank() over(partition by country order by psg_total desc) as psg_rank from psg_totals
inner join passengers p on psg_totals.passenger_id=p.passenger_id;

-- Day 2
  --Event sequence analysis, show current event previous event time difference between events
with etc as (select t.ticket_id, event_id, event_time, lag(event_time) over(partition by t.ticket_id order by event_time) as prev_event_time, event_type, lag(event_type) over(partition by t.ticket_id order by event_time) as prev_event from tickets t
inner join events e on t.ticket_id=e.entity_id order by t.ticket_id, e.event_time )
select * from etc where event_type='cancel' and prev_event='checkin';

-- Day 3
  -- Detect: flights where revenue suddenly jumps

with etc as (select flt_id, price as revenue, lag(price) over(partition by flt_id order by booking_time) as prev_revenue
from tickets) 
select *, revenue - prev_revenue as delta from etc
where revenue - prev_revenue > revenue * 0.3
order by flt_id;


--Day 4
  -- cumulative revenue per flight
select ticket_id, flt_id, passenger_id, price, booking_time, sum(price) over(partition by flt_id order by booking_time) as flt_total
from tickets;




