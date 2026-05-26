--Day 1
  -- latest ticket per passenger

WITH etc
     AS (SELECT passenger_id,
                ticket_id,
                Dense_rank()
                  OVER (
                    partition BY passenger_id
                    ORDER BY booking_time DESC) AS ticket_rank
         FROM   tickets)
SELECT t1.passenger_id,
       t1.booking_time,
       t1.flt_id
FROM   etc
       INNER JOIN tickets t1
               ON etc.ticket_id = t1.ticket_id
WHERE  etc.ticket_rank = 1
ORDER  BY t1.passenger_id;  


--Day 2
  -- Rank tickets by price: inside each flight
select 
    flt_id, 
    ticket_id, 
    price, 
    dense_rank() over(partition by flt_id order by price desc) as ticket_rank 
from tickets;

--Day 3
  -- cumulative revenue by booking date

select 
    booking_time, 
    price, 
    sum(price) over (order by booking_time) as cumulative_revenue 
from tickets order by booking_time;

--Day 4
  -- Calculate:
     -- rolling average ticket price
     -- over last 5 bookings

select booking_time, 
    price, 
    avg(price) over(
      order by booking_time 
      rows between 4 preceding and current row
      ) as roll_avg
from tickets;

--Day 5
  -- Detect:duplicate tickets based on: passenger_id, flt_id
WITH dups AS (
    SELECT
        t1.ticket_id,
        t1.flt_id,
        t1.passenger_id,
        t1.booking_time,
        ROW_NUMBER() OVER (
            PARTITION BY t1.flt_id, t1.passenger_id
            ORDER BY t1.booking_time DESC
        ) AS rn
    FROM tickets t1
)
SELECT *
FROM dups
WHERE rn > 1
ORDER BY flt_id;
