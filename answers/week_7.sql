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
WITH tickets_enriched AS (
    SELECT
        passenger_id,
        booking_time,
        price,
        LAG(price) OVER (
            PARTITION BY passenger_id
            ORDER BY booking_time
        ) AS previous_price
    FROM tickets
),
price_info AS (
    SELECT *,
           CASE
               WHEN previous_price IS NULL THEN NULL
               WHEN previous_price = price THEN 0
               WHEN previous_price < price THEN 1
               ELSE -1
           END AS price_change
    FROM tickets_enriched
), passenger_info as (
SELECT
    passenger_id,
    COUNT(*) FILTER (
        WHERE price_change IS NOT NULL
    ) AS total_transitions,
    COUNT(*) FILTER (
        WHERE price_change = 1
    ) AS increasing_transitions
FROM price_info
GROUP BY 1 )
select *, case when total_transitions=0 then round(0, 2)
else round((increasing_transitions::numeric * 100) / total_transitions, 2 )
end as increase_rate from passenger_info;

-- Day 4 
 -- Moving average ticket price (last 5 bookings)
SELECT
    ticket_id,
    flt_id,
    price,
    booking_time,
    ROUND(
        AVG(price) OVER (
            ORDER BY booking_time, ticket_id
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_price
FROM tickets;


-- Day 5
-- Detect gaps in booking timeline per passenger
with enriched_bookings as ( select passenger_id, booking_time, lag(booking_time) over(partition by passenger_id order by booking_time) as previous_booking_time 
from tickets ),
bookings_with_gaps as (select *, booking_time::date - previous_booking_time::date as gap_days from enriched_bookings),
gaps_enriched as (select passenger_id, booking_time, previous_booking_time, 
case when gap_days > 30 then 1
when gap_days <= 30 then 0
when gap_days is NULL then NULL end as is_significant_gap
from bookings_with_gaps) select passenger_id, count(booking_time) as total_bookings,
count(is_significant_gap) filter(where is_significant_gap=1) as significant_gaps from gaps_enriched
group by 1
order by passenger_id;

-- Day 6

WITH duplicate_tickets AS
  (SELECT ticket_id,
          COUNT(ticket_id) AS record_count
   FROM tickets
   GROUP BY 1
   HAVING COUNT(ticket_id) > 1),
     tickets_extended AS
  (SELECT t.ticket_id,
          t.passenger_id,
          t.flt_id,
          t.booking_time,
          t.price
   FROM tickets t
   INNER JOIN duplicate_tickets dt ON t.ticket_id=dt.ticket_id
   ORDER BY ticket_id),
     full_duplicate_records AS
  (SELECT te.ticket_id,
          count(*) AS record_count,
          count(DISTINCT te.passenger_id) AS passengers,
          count(DISTINCT te.flt_id) AS flights,
          count(DISTINCT te.booking_time) AS times,
          count(DISTINCT te.price) AS prices
   FROM tickets_extended te
   GROUP BY te.ticket_id
   ORDER BY te.ticket_id),
     duplicate_class AS
  (SELECT *,
          CASE
              WHEN df.record_count > 1
                   AND df.passengers = 1
                   AND df.flights = 1
                   AND df.times = 1
                   AND df.prices = 1 THEN 'exact_duplicate'
              ELSE 'conflicting_duplicate'
          END AS duplicate_type
   FROM full_duplicate_records AS df), 
grouped_tickets as (select t.ticket_id, t.passenger_id, t.flt_id, t.booking_time, t.price, 
row_number() over(partition by t.ticket_id) as cnt from tickets t
inner join duplicate_class dc on t.ticket_id=dc.ticket_id
where dc.duplicate_type='exact_duplicate'),
filtered_duplicates as (select * from grouped_tickets where cnt=1)
select t.ticket_id, t.passenger_id, t.flt_id, t.booking_time, t.price from tickets t
where t.ticket_id not in (select ticket_id from filtered_duplicates)
union all select gp.ticket_id, gp.passenger_id, gp.flt_id, gp.booking_time, gp.price from grouped_tickets gp where gp.cnt=1;


-- Validate
WITH duplicate_tickets AS
  (SELECT ticket_id,
          COUNT(ticket_id) AS record_count
   FROM tickets
   GROUP BY 1
   HAVING COUNT(ticket_id) > 1),
     tickets_extended AS
  (SELECT t.ticket_id,
          t.passenger_id,
          t.flt_id,
          t.booking_time,
          t.price
   FROM tickets t
   INNER JOIN duplicate_tickets dt ON t.ticket_id=dt.ticket_id
   ORDER BY ticket_id),
     full_duplicate_records AS
  (SELECT te.ticket_id,
          count(*) AS record_count,
          count(DISTINCT te.passenger_id) AS passengers,
          count(DISTINCT te.flt_id) AS flights,
          count(DISTINCT te.booking_time) AS times,
          count(DISTINCT te.price) AS prices
   FROM tickets_extended te
   GROUP BY te.ticket_id
   ORDER BY te.ticket_id),
     duplicate_class AS
  (SELECT *,
          CASE
              WHEN df.record_count > 1
                   AND df.passengers = 1
                   AND df.flights = 1
                   AND df.times = 1
                   AND df.prices = 1 THEN 'exact_duplicate'
              ELSE 'conflicting_duplicate'
          END AS duplicate_type
   FROM full_duplicate_records AS df), 
grouped_tickets as (select t.ticket_id, t.passenger_id, t.flt_id, t.booking_time, t.price, 
row_number() over(partition by t.ticket_id) as cnt from tickets t
inner join duplicate_class dc on t.ticket_id=dc.ticket_id
where dc.duplicate_type='exact_duplicate'),
filtered_duplicates as (select * from grouped_tickets where cnt=1),
clean_tickets as (select t.ticket_id, t.passenger_id, t.flt_id, t.booking_time, t.price from tickets t
where t.ticket_id not in (select ticket_id from filtered_duplicates)
union all select gp.ticket_id, gp.passenger_id, gp.flt_id, gp.booking_time, gp.price from grouped_tickets gp where gp.cnt=1)
select ticket_id, passenger_id, flt_id, booking_time, price, count(*) as cnt from clean_tickets
group by 1,2,3,4,5
having count(*) > 1;
