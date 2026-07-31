-- Day 1
 -- Rank flights by number of tickets per airport

with enriched as (
select departure_airport as airport, f.flt_id, count(t.ticket_id) count_flt from flights f
inner join tickets t on f.flt_id=t.flt_id group by 1,2 )
select airport, flt_id, count_flt, dense_rank() over(partition by airport order by count_flt desc) from enriched;


-- Day 2
 -- Running revenue per airport
 with daily_airport_revenue as (
select departure_airport, booking_time::date as booking_date, sum(price) as daily_total from tickets t
inner join flights f on t.flt_id=f.flt_id group by 1, 2)
select departure_airport, booking_date, daily_total,
sum(daily_total) over(partition by departure_airport order by booking_date) as cum_sum from daily_airport_revenue;

-- Day 3
 -- Dense rank passengers by total spending
WITH total_spent_by_pass AS (
    SELECT
        passenger_id,
        SUM(price) AS total_spent
    FROM tickets
    GROUP BY 1
)
SELECT
    passenger_id,
    total_spent,
    DENSE_RANK() OVER (
        ORDER BY total_spent DESC
    )
FROM total_spent_by_pass;

-- Day 4
-- Find second most expensive ticket per flight

WITH ticket_ranked AS (
    SELECT
        flt_id,
        ticket_id,
        price,
        DENSE_RANK() OVER (
            PARTITION BY flt_id
            ORDER BY price DESC
        ) AS ticket_rank
    FROM tickets
)
SELECT *
FROM ticket_ranked
WHERE ticket_rank = 1;

-- Day 5
  -- Percent contribution of each ticket to flight revenue

WITH flt_revenues AS (
    SELECT
        flt_id,
        SUM(price) AS flt_revenue
    FROM tickets
    GROUP BY 1
)
SELECT
    t.flt_id,
    t.ticket_id,
    f.flt_revenue,
    t.price,
    ROUND(t.price / f.flt_revenue * 100, 2) AS percentage
FROM tickets t
INNER JOIN flt_revenues f
    ON t.flt_id = f.flt_id
ORDER BY t.flt_id;
