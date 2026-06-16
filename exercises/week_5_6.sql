--Day 1
-- For every ticket:

 -- Show: passenger_id, booking_time, previous booking time
 select passenger_id, booking_time, lag(booking_time) over(partition by passenger_id order by booking_time) as prev_booking_time
 from tickets;
  
 -- Show: previous ticket price
select passenger_id, booking_time, price, lag(price) over(partition by passenger_id order by booking_time) as prev_ticket_price
from tickets;

 -- Show: difference from previous ticket price
select passenger_id, booking_time, price, lag(price) over(partition by passenger_id order by booking_time) as prev_ticket_price,
abs(price - lag(price) over(partition by passenger_id order by booking_time)) as price_delta from tickets;
