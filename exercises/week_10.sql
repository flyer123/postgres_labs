-- Day 1
-- ==========================================================
-- EXPLAIN ANALYZE
  --  SELECT *
  --  FROM tickets
  --  WHERE flt_id = 100;
      -- Record the execution plan.
      -- Identify:- scan type
 -- estimated rows
 -- actual rows
 -- execution time

-- Determine whether PostgreSQL uses a sequential scan.

-- Day 2
-- =========================================================
 -- CREATE INDEX idx_tickets_flt_id
 -- ON tickets(flt_id);

  --  EXPLAIN ANALYZE
  --  SELECT *
  --  FROM tickets
  --  WHERE flt_id = 100;

-- Analyse the difference:
  -- Did PostgreSQL actually use the index?
  -- Did execution time improve?
  -- What changed in the plan?
  -- Why might PostgreSQL choose not to use the index?

  -- DAY 3 — PASSENGER LOOKUP: HIGH SELECTIVITY AND INDEX ACCESS
-- ==========================================================================
-- Context: 100,000 tickets; passenger_id = 12345 returned 4 tickets in the
-- recorded experiment.
--
-- 3.1  Run EXPLAIN ANALYZE for a lookup of all tickets belonging to
--      passenger_id = 12345. Identify:
--      a) the scan type; b) estimated rows; c) actual rows;
--      d) Rows Removed by Filter; e) execution time.
-- TODO:

-- 3.2  Find the ten passengers with the highest ticket counts.
--      Does this tell you how many tickets passenger 12345 has?
-- TODO:

-- 3.3  Create a B-tree index named idx_passenger_id on tickets(passenger_id)
--      (unless it already exists). Rerun 3.1. Explain the difference between
--      Bitmap Index Scan and Bitmap Heap Scan, and interpret Heap Blocks.
-- TODO:

-- 3.4  Compute the fraction of all tickets belonging to passenger 12345.
--      Explain why this is a selective predicate.
-- TODO:

-- 3.5  Compare planner estimates with actual rows. Refresh statistics with
--      ANALYZE tickets, rerun the lookup, and note whether estimates improve.
--      Do not expect the same plan or timing on every machine.
-- TODO:

-- 3.6  Write a 2–3 sentence conclusion: did the index help, and what evidence
--      in the execution plan supports that statement?
-- TODO (comments):


-- ==========================================================================
-- DAY 4 — PRICE RANGE: WHEN AN INDEX MAY NOT HELP
-- ==========================================================================
-- Context: price > 500 returned 52,340 / 100,000 tickets (52.34%).
--
-- 4.1  Run EXPLAIN ANALYZE for SELECT * FROM tickets WHERE price > 500.
--      Record scan type, estimated rows, actual rows and execution time.
-- TODO:

-- 4.2  Run ANALYZE tickets and repeat 4.1. Compare the estimated count with
--      the actual count. Explain what ANALYZE changed (and did NOT change).
-- TODO:

-- 4.3  Before indexing price, predict whether PostgreSQL will use it.
--      Create idx_tickets_price on tickets(price); rerun EXPLAIN ANALYZE.
--      Record whether the scan strategy changes.
-- TODO:

-- 4.4  Explain why retrieving ~52% of a table with SELECT * may make a
--      sequential scan cheaper than an index-based plan.
--      Clarify: does CREATE INDEX physically reorder heap rows?
-- TODO (comments):

-- 4.5  If this is only an experimental index and you have no workload that
--      needs it, remove idx_tickets_price.
-- TODO:


-- ==========================================================================
-- DAY 5 — JOIN STRATEGIES: HASH JOIN VS NESTED LOOP
-- ==========================================================================
-- Work with this projection throughout the day:
--   t.ticket_id, t.price, f.flt_id, f.departure_airport,
--   f.arrival_airport, f.departure_time
-- Join: tickets t JOIN flights f ON t.flt_id = f.flt_id
--
-- 5.1  Filter flights with departure_airport = 'JFK'. Run EXPLAIN ANALYZE.
--      Identify the join strategy, scan types, hash size, and result count.
--      Refresh statistics and rerun. Compare estimates with actual counts.
-- TODO:

-- 5.2  Change the airport to 'FRA' and predict whether the join algorithm
--      should change. Explain your prediction using these recorded counts:
--      JFK: 1,019 flights / 20,477 tickets.
--      FRA:   960 flights / 19,327 tickets.
--      Test the prediction with EXPLAIN ANALYZE.
-- TODO:

-- 5.3  Inspect current indexes on both tables via pg_indexes.
--      Explain why creating indexes on tickets(ticket_id) and flights(flt_id)
--      did not help the FRA query. Check if they duplicate PK indexes.
--      Do not recreate redundant indexes just to complete the assignment.
-- TODO:

-- 5.4  Create idx_tick_flt on tickets(flt_id) if no equivalent exists.
--      Rerun the FRA query. Did PostgreSQL use this index? Did the join
--      strategy change? Can you attribute a small timing change to the index
--      if the new plan never uses it?
-- TODO:

-- 5.5  Run ANALYZE on both tables and repeat the FRA query. Check the
--      accuracy of estimated flight rows and joined rows.
-- TODO:

-- 5.6  Change the filter to f.flt_id = 100. Predict the plan BEFORE running.
--      Compare the result with FRA: join method, row counts, access paths,
--      and execution time. Explain how the join lets PostgreSQL derive
--      t.flt_id = 100 from the original condition.
-- TODO:

-- 5.7  Explain why a timing comparison between the FRA and single-flight
--      queries is not an apples-to-apples speedup measurement.
-- TODO (comments):


-- ==========================================================================
-- DAY 6 — CONTROLLED INCIDENT: SLOW SINGLE-FLIGHT TICKET LOOKUP
-- ==========================================================================
-- Scenario: a selective flight-ticket query becomes slower after a useful
-- index is accidentally removed. Simulate this ONLY in your disposable lab.
-- No row modifications. Restore the index before finishing.
--
-- 6.1  Verify the available indexes. Ensure idx_tick_flt on tickets(flt_id)
--      exists, then ANALYZE both tables. For f.flt_id = 100, capture a
--      BASELINE using EXPLAIN (ANALYZE, BUFFERS). Note the plan, estimated /
--      actual rows, and execution time.
-- TODO:

-- 6.2  Simulate the incident by dropping ONLY your lab-created idx_tick_flt.
--      Run exactly the same query with EXPLAIN (ANALYZE, BUFFERS).
--      Observe which access paths are now available and whether the tickets
--      side performs a sequential scan. Do not assume a particular plan.
-- TODO:

-- 6.3  Restore idx_tick_flt, rerun ANALYZE as needed, and run the identical
--      query a third time. Did the previous indexed access path return?
-- TODO:

-- 6.4  Write an incident summary as SQL comments:
--      - Symptom: what became slower / more expensive?
--      - Evidence: which plan node(s) changed?
--      - Root cause: which access path disappeared?
--      - Remediation: what was restored?
--      - Verification: what measurable evidence confirms recovery?
--      Avoid inventing timings: record what YOUR system reports.
-- TODO (comments):

-- 6.5  Cleanup: inspect pg_indexes again. Consider dropping redundant
--      laboratory indexes idx_tickets and idx_flts ONLY after verifying that
--      original primary-key indexes exist. Retain idx_tick_flt for future
--      join experiments. Do not modify public source rows.