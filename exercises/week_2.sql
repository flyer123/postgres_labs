--Week 2
--Day 1
  -- Average ticket price per airport (departure side)
select f.departure_airport, avg(t.price) as average_price
     from flights f inner join tickets t 
     on f.flt_id=t.flt_id
group by 1;

--Day 2
  -- Total revenue per day (use booking_time)
select booking_time::DATE as booking_date, sum(price) as total_per_day
from tickets
group by 1
order by booking_time::DATE;

--Day 3
  -- Find flights where total revenue > avg revenue of all flights
with flights_total as (
  select t.flt_id, sum(t.price) as total from tickets t 
  group by 1),
avg_total as (
 select avg(
 flights_total.total) as avg_all from flights_total 
 )
select flights_total.flt_id, flights_total.total, avg_total.avg_all
from flights_total, avg_total
where flights_total.total > avg_total.avg_all;

--Day 4
  -- Count passengers per country who booked at least 1 ticket
select country, count(country) from passengers p
    inner join tickets t
    on p.passenger_id=t.passenger_id
group by country;

--Day 5
 -- Find days where revenue dropped compared to previous day
 with etc as (select booking_time::date as sold_date, sum(price) as revenue
from tickets
group by 1),
revenues as (
select etc.sold_date, etc.revenue,
lag(etc.revenue, 1, 0) over(order by etc.sold_date) as prev_day_revenue from etc)
select revenues.sold_date, revenues.revenue, revenues.prev_day_revenue
from revenues
where revenues.revenue < revenues.prev_day_revenue;




