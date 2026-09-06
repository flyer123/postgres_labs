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

--Day 2
  -- Show: next booking time
  select passenger_id, booking_time, lead(booking_time) over(partition by passenger_id order by booking_time) as next_book_time
  from tickets;


  -- Show: hours until next booking
  select passenger_id, booking_time, lead(booking_time) over(partition by passenger_id order by booking_time) as next_book_time,
  extract(epoch from (lead(booking_time) over(partition by passenger_id order by booking_time)) - booking_time) /3600 as hours_till_next
from tickets;


  -- Find passengers who booked again within 24 hours.
with etc as (select passenger_id, booking_time, lead(booking_time) over(partition by passenger_id order by booking_time) as next_book_time,
extract(epoch from (lead(booking_time) over(partition by passenger_id order by booking_time)) - booking_time) /3600 as hours_till_next
from tickets) select * from etc where hours_till_next <= 24;

--Day 3
--Running Calculations: 
--Assignment 1 Show: booking price cumulative spend per passenger 
--Assignment 2 Show: booking number within passenger history 
--Assignment 3 Show: cumulative ticket count
select passenger_id,
price,
sum(price) over(partition by passenger_id order by booking_time) as cum_spent,
row_number() over(partition by passenger_id order by booking_time) as booking_number,
count(*) over(partition by passenger_id order by booking_time) as cum_count
from tickets;

-- Day 4
  -- first booking, repeat booking
  -- booking gap > 7 days
  -- price increased by > 50%

select passenger_id, price, lag(price) over(partition by passenger_id order by booking_time) as prev_price,  booking_time, lag(booking_time) over(partition by passenger_id) as next_booking, case
when lag(booking_time) over(partition by passenger_id) is not null then TRUE
else FALSE END as repeat_booking,
abs(price - lag(price) over(partition by passenger_id order by booking_time)) as price_increase,
case 
when price / lag(price) over(partition by passenger_id order by booking_time) > 2 then TRUE
else FALSE END as high_increase,
case
when booking_time::date - (lag(booking_time) over(partition by passenger_id order by booking_time))::date > 7 then TRUE
when lag(booking_time) over(partition by passenger_id order by booking_time) is NULL then FALSE
ELSE FALSE END as big_date_diff
from tickets;

-- Day 5
  -- new trip when flight changes
  select t.passenger_id,
 t.flt_id, lead(t.flt_id) over(partition by passenger_id order by booking_time) as next_flt,
 case
 when lead(t.flt_id) over(partition by passenger_id order by booking_time) is null then False
 when t.flt_id = lead(t.flt_id) over(partition by passenger_id order by booking_time) then False
 else True END as new_trip
from tickets t inner join flights f
on t.flt_id=f.flt_id;


 -- new trip when airport changes
select t.passenger_id,
 t.flt_id, lead(t.flt_id) over(partition by passenger_id order by booking_time) as next_flt,
departure_airport, lead(departure_airport) over(partition by passenger_id order by booking_time) as next_airport,
case when lead(departure_airport) over(partition by passenger_id order by booking_time) is null then False
 when departure_airport = lead(departure_airport) over(partition by passenger_id order by booking_time) then False
 else True END as new_trip
from tickets t inner join flights f
on t.flt_id=f.flt_id;


 -- new trip when when booking gap > 3 days.
select t.passenger_id,
 t.flt_id, lead(t.flt_id) over(partition by passenger_id order by booking_time) as next_flt,
booking_time, lead(booking_time) over(partition by passenger_id order by booking_time) as next_booking,
case
when lead(booking_time) over(partition by passenger_id order by booking_time) is null then False
when lead(booking_time) over(partition by passenger_id order by booking_time)::date - booking_time::date > 3 then True
else False end as new_trip
from tickets t inner join flights f
on t.flt_id=f.flt_id;

-- Day 6
  --For each passenger: Bookings within 48 hours belong to same session.
select passenger_id, booking_time, lag(booking_time) over(partition by passenger_id order by booking_time) as prev_session,
extract(epoch from(booking_time - lag(booking_time) over(partition by passenger_id order by booking_time))) / 3600 as gap,
case when extract(epoch from(booking_time - lag(booking_time) over(partition by passenger_id order by booking_time))) / 3600 > 48 then 1
else 0 end as start_of_new_session from tickets;