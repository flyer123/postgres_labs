-- Day 1
  -- Detect duplicate tickets (same passenger_id + flt_id)
select passenger_id, flt_id as flt_pass_key, count(*) as count_same_flights from tickets t
where not exists(select 1 from events e where t.ticket_id=e.entity_id and e.event_type='cancel')
group by 1, 2
having count(*) > 1;

-- Day 2
  -- Keep latest ticket per passenger per flight
with ticket_ranks as (
select flt_id, passenger_id, booking_time, ticket_id, row_number() over(partition by flt_id, passenger_id order by booking_time desc, ticket_id asc) as flt_rank
from tickets ) select * from ticket_ranks where flt_rank=1;

-- Day 3
with enriched_pass as (select passenger_id, booking_time, price, lag(price) over(
partition by passenger_id order by booking_time) as prev_spend,
case when lag(price) over(partition by passenger_id order by booking_time) > price then -1
when lag(price) over(partition by passenger_id order by booking_time) < price then 1
when lag(price) over(partition by passenger_id order by booking_time) = price then 0
else null end as spend_increase from tickets t ),
grouped_flt as (select passenger_id, count(*)  as total_flights, count(*) filter(where spend_increase = 1) as increased_flights from enriched_pass
group by 1)
select *, round(grouped_flt.increased_flights*1.0 / grouped_flt.total_flights*1.0 * 100, 2) as perc_increased_flt from grouped_flt;
