-- Day 1
 -- Flights delayed (status = 'delayed')

flights_db=# select * from flights where status = 'delayed';
 -- Only last 7 days
 flights_db=# select * from flights where departure_time >= now() - interval '7 days';

-- Day 2
  -- Top 5 airports by number of departurescd docker

select departure_airport, count(departure_airport) from flights
group by 1
order by count(departure_airport) desc limit 5;

-- Day 3
  -- Find tickets where: price > average price of that flight
with etc as (
     select flt_id, avg(price) as average_price 
     from tickets 
     group by  flt_id 
     )
 select * from tickets t inner join etc 
 on t.flt_id=etc.flt_id
 where t.price > etc.average_price;

-- Day 4
  -- Passengers who never booked a ticket
select p.* from passengers as p
left join tickets as t
on p.passenger_id=t.passenger_id
where t.ticket_id is null;

-- Day 5
  -- Flights with no tickets
select * from flights f 
    left join tickets t
    on f.flt_id=t.flt_id 
where t.ticket_id is null;

  -- Flights scheduled in future
select * from flights
    where departure_time > now();

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




