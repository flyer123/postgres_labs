--day 1
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
