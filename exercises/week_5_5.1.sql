--Day 1
  -- show: flt_id ticket_id ticket price total flight revenue revenue rank
  -- Learn: SUM() OVER ranking after aggregation preserving row grain
  with enriched as (
      select 
        ticket_id, 
        flt_id, 
        price, 
        sum(price) over(partition by flt_id)as revenue 
      from tickets
    )
select 
  ticket_id, 
  flt_id, 
  price, 
  revenue, 
  dense_rank() over(order by revenue desc) 
from enriched;

--Day 2
  -- For each passenger: show every ticket
  -- plus:
  -- total spent by passenger
  -- average ticket price
  -- passenger spending rank

 with stat_pass as (
    select
        passenger_id, 
        ticket_id, 
        price, 
        sum(price) over(partition by passenger_id) as total_spent,
        avg(price) over(partition by passenger_id) as average_ticket_price 
        from tickets 
        )
select passenger_id,
    ticket_id, 
    price, 
    total_spent, 
    average_ticket_price,
dense_rank() over(order by total_spent desc) as passenger_rank from stat_pass
order by passenger_rank;

--Day 3
  -- cumulative booking revenue over time, show booking_time, price, running_total

select booking_time, price, sum(price) over(order by booking_time) as run_total from tickets;

--Day 4
  -- Compute: rolling average ticket price, over last 5 bookings
select booking_time, 
  price,
  sum(price) 
    over(
      order by booking_time 
        rows between 4 preceding and current row
        ) as running_total
  from tickets;

--Day 5
  -- Detect:

  --suspicious repeated bookings Definition: same passenger, same flight, multiple tickets, 

  --Keep: latest booking only
  
with ranked_tickets as (
  select *, 
  row_number() over(partition by flt_id, 
  passenger_id) as rnk
  from tickets 
)
select * from ranked_tickets 
  where ranked_tickets.rnk>1
order by passenger_id;

--Day 6
  -- wrong query
select flt_id, event_time, sum(price) over(partition by flt_id) as flt_revenue from flights as f
inner join events e on f^C
select flt_id, event_time, sum(price) over(partition by flt_id) as flt_revenue from tickets t
inner join events e on t.ticket_id=e.entity_id
order by flt_id, event_time;

 -- right
select flt_id, price from tickets t where exists (select 1 from events e where e.entity_id=t.ticket_id);
with filtered as (select flt_id, price from tickets t where exists (select 1 from events e where e.entity_id=t.ticket_id))
select flt_id, sum(price) from filtered group by 1 order by flt_id;




