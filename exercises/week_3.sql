--Day 1
 -- Join tickets + flights:
 -- show ticket_id, departure_airport, price
select 
    ticket_id, 
    departure_airport, 
    price 
from tickets t
inner join flights f
using(flt_id);

--Day 2
  -- Find tickets where flight does NOT exist (data corruption)
select * from tickets t
  left join flights f
  on f.flt_id=t.flt_id
where f.departure_airport is null;

-- Day 3
  -- Find flights with passengers from more than 3 countries
SELECT
    t.flt_id,
    COUNT(DISTINCT p.country) AS country_count
FROM
    tickets t
JOIN
    passengers p ON t.passenger_id = p.passenger_id
GROUP BY
    t.flt_id
HAVING
    COUNT(DISTINCT p.country) > 3
ORDER BY
    t.flt_id;

-- Day 4
  -- Airports with no outgoing flights
select a.airport_code, a.city from airports a
  left join flights f
  on a.airport_code=f.departure_airport
where f.departure_airport is null;

-- Day 5
  -- Find most popular route (departure → arrival)
select concat(departure_airport, '-', arrival_airport), count(*)
from flights
group by 1
order by count(*) desc
limit 10;



