--Day 1
  -- Flights with ticket count above average
  WITH
counts AS (
    SELECT
        flt_id,
        COUNT(ticket_id) AS cnt
    FROM
        tickets
    GROUP BY
        flt_id
),
avg_count AS (
    SELECT
        AVG(cnt) AS avg_cnt
    FROM
        counts
)
SELECT
    counts.flt_id,
    counts.cnt AS ticket_count,
    avg_count.avg_cnt AS average_ticket_count
FROM
    counts, avg_count
WHERE
    counts.cnt > avg_count.avg_cnt;

--Day 2
 -- Passengers who spent more than average passenger
 with pass_total as (
    select passenger_id, sum(t.price) as pass_spent 
    from passengers p 
    inner join tickets t 
    using (passenger_id) 
    group by 1)
, 
pass_avg as (
    select avg(ps.pass_spent) as avg_spent 
    from pass_total ps)
select pass_total.passenger_id, pass_total.pass_spent, pass_avg.avg_spent 
from pass_total, pass_avg
where pass_spent > pass_avg.avg_spent;

--Day 3
  -- Find most recent ticket per flight
select flt_id, max(booking_time) from tickets
flights_db-# group by 1;

--Day 4
 -- Flights where max ticket price > global avg price
with ticket_max_price as (
select flt_id, max(price) as max_price from tickets group by flt_id ),
avg_price as (select avg(price) as avg_price from tickets)
select ticket_max_price.flt_id, ticket_max_price.max_price, avg_price.avg_price
from ticket_max_price, avg_price where ticket_max_price.max_price > avg_price.avg_price;

--Day 5
  -- Find tickets priced above the average price of their flight
  -- Correlated aggregation (classic slowdown)
    -- Identify why the subquery is inefficient
    -- Rewrite logic so aggregation happens once per flight
    --  Ensure result stays identical

    -- current
select t1.ticket_id, t1.flt_id, t1.price from tickets t1
    where t1.price > (select avg(t2.price) 
    from tickets t2 where t2.flt_id=t1.flt_id )

    -- Find tickets that have at least one event
select * from tickets t where exists (select event_id from events ev where ev.entity_id=t.ticket_id);
explain select * from tickets t where exists (select event_id from events ev where ev.entity_id=t.ticket_id);
select t.* from tickets t inner join events ev on t.ticket_id=ev.entity_id;
explain select t.* from tickets t inner join events ev on t.ticket_id=ev.entity_id;

-- For each flight, show:

  --total revenue
  --verage ticket price
select t1.flt_id, ( select sum(t2.price) from tickets t2 where t2.flt_id=t1.flt_id),
 (select avg(price) from tickets t2 where t2.flt_id=t1.flt_id) from tickets t1 limit 10;

 select flt_id, sum(price), avg(price) from tickets group by 1;


-- Find flights that have tickets

 select flt_id, departure_airport, arrival_airport from flights where flt_id in (select flt_id from tickets);

 select f.flt_id, departure_airport, arrival_airport from flights f
 inner join tickets t on f.flt_id=t.flt_id;


 -- Find top 5 flights by revenue
 select t1.flt_id, (select sum(t2.price) from tickets t2 where t1.flt_id=t2.flt_id) as revenue
from tickets t1 order by revenue desc limit 5;

select flt_id, sum(price) from tickets
 group by 1
 order by sum(price) desc
limit 5;




 -- Find revenue per flight, only for flights with events

select r.flt_id, r.revenue from (select t.flt_id, sum(t.price) as revenue from tickets t group by t.flt_id) r
inner join tickets t1 on t1.flt_id=r.flt_id inner join events e on t1.ticket_id=e.entity_id;

select t.flt_id, sum(t.price) from tickets t where exists (select 1 from events e where e.entity_id=t.ticket_id) group by t.flt_id;