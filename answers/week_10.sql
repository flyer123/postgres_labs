-- Day 1
EXPLAIN ANALYZE
SELECT *
FROM tickets
WHERE flt_id = 100;

 -- QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
  -- Seq Scan on tickets  (cost=0.00..1674.40 rows=375 width=52) (actual time=0.012..3.317 rows=24 loops=1)
    -- Filter: (flt_id = 100)
    -- Rows Removed by Filter: 99976
  -- Planning Time: 0.036 ms
  -- Execution Time: 3.327 ms
 -- (5 rows)
  -- sequential Scan
  -- rows planned 375
  -- rows actual 24
  -- execution time 3.327 ms

-- Day 2
CREATE INDEX idx_tickets_flt_id
ON tickets(flt_id);

EXPLAIN ANALYZE
SELECT *
FROM tickets
WHERE flt_id = 100;

-- Analyse the difference:
  -- Did PostgreSQL actually use the index?
  -- Did execution time improve?
  -- What changed in the plan?
  -- Why might PostgreSQL choose not to use the index?

EXPLAIN ANALYZE
SELECT *
FROM tickets
WHERE flt_id = 100;
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 -- Seq Scan on tickets  (cost=0.00..1674.40 rows=375 width=52) (actual time=0.011..4.132 rows=24 loops=1)
   --  Filter: (flt_id = 100)
    -- Rows Removed by Filter: 99976
  -- Planning Time: 0.165 ms
  -- Execution Time: 4.151 ms
 -- (5 rows)

CREATE INDEX idx_tickets_flt_id
ON tickets(flt_id);
CREATE INDEX
flights_db=# EXPLAIN ANALYZE
SELECT *
FROM tickets
WHERE flt_id = 100;
                                                          QUERY PLAN                                                          
------------------------------------------------------------------------------------------------------------------------------
 -- Bitmap Heap Scan on tickets  (cost=8.17..710.60 rows=500 width=52) (actual time=0.018..0.042 rows=24 loops=1)
   -- Recheck Cond: (flt_id = 100)
   -- Heap Blocks: exact=23
   -- ->  Bitmap Index Scan on idx_tickets_flt_id  (cost=0.00..8.04 rows=500 width=0) (actual time=0.013..0.014 rows=24 loops=1)
    --     Index Cond: (flt_id = 100)
 -- Planning Time: 0.148 ms
 -- Execution Time: 0.056 ms
-- (7 rows)

 -- Did PostgreSQL actually use the index? - Yes
 -- Did execution time improve? - Yes
 -- What changed in the plan? - It does index scan and then bitmap index scan
 -- Why might PostgreSQL choose not to use the index? - when sequential scan would be cheaper to execute


-- ==========================================================================
-- DAY 3 — HIGH-SELECTIVITY PASSENGER LOOKUP
-- ==========================================================================

-- 3.1 Baseline: before adding idx_passenger_id, the query used Seq Scan.
-- Observed: 100,000 rows considered; 4 returned; 99,996 filtered out.
-- Estimated matches: 375; actual: 4; execution time: 4.179 ms.
-- If idx_passenger_id already exists, this query will use the current plan,
-- so it is NOT an exact recreation of the original unindexed baseline.
EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE passenger_id = 12345;

-- 3.2 Passengers with the most tickets.
-- Observed top counts were 16, 16, then several 15s and 14s.
-- This does NOT directly establish the count for passenger_id = 12345.
SELECT passenger_id, COUNT(*) AS ticket_count
FROM public.tickets
GROUP BY passenger_id
ORDER BY ticket_count DESC, passenger_id
LIMIT 10;

-- Directly verify the target passenger's count.
SELECT COUNT(*) AS matching_tickets
FROM public.tickets
WHERE passenger_id = 12345;

-- 3.3 Create index and compare. Use IF NOT EXISTS for repeatable lab runs.
CREATE INDEX IF NOT EXISTS idx_passenger_id
ON public.tickets(passenger_id);

EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE passenger_id = 12345;

-- Observed after index creation:
-- Bitmap Heap Scan on tickets
--   Recheck Cond: (passenger_id = 12345)
--   Heap Blocks: exact=4
--   -> Bitmap Index Scan on idx_passenger_id
--      Index Cond: (passenger_id = 12345)
-- Actual matching rows: 4; execution time: 0.030 ms.
-- Bitmap Index Scan identifies matching row locations using the index.
-- Bitmap Heap Scan fetches the complete table rows for those locations.
-- Heap Blocks: exact=4 describes four heap pages with exact bitmap entries,
-- not four table rows or four pages in the entire table.

-- 3.4 Selectivity: 4 / 100,000 = 0.004%.
SELECT
    COUNT(*) FILTER (WHERE passenger_id = 12345) AS matched_rows,
    COUNT(*) AS total_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE passenger_id = 12345)
        / NULLIF(COUNT(*), 0),
        4
    ) AS matching_pct
FROM public.tickets;

-- 3.5 Update statistics and compare estimated rows with actual rows.
ANALYZE public.tickets;
EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE passenger_id = 12345;

-- Conclusion:
-- The passenger predicate is highly selective. Before the index, the
-- database scanned the table to return four rows. With the index, it used
-- a bitmap index + heap scan. Observed time fell from 4.179 to 0.030 ms
-- in individual runs (about 139x), although repeated measurements are
-- needed for a reliable benchmark.


-- ==========================================================================
-- DAY 4 — LOW-SELECTIVITY PRICE RANGE
-- ==========================================================================

-- 4.1 Original plan: Seq Scan, estimated 25,024, actual 52,340 matches;
-- 47,660 rows filtered out; observed execution time 9.927 ms.
EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE price > 500;

-- 4.2 Refresh statistics and repeat.
ANALYZE public.tickets;
EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE price > 500;

-- Observed after ANALYZE:
-- Seq Scan; estimated 52,198 rows, actual 52,340; time 7.148 ms.
-- ANALYZE updates the planner's statistics, not the table's contents.
-- The estimated count became much closer to the actual count, but the
-- sequential scan remained appropriate.

-- Exact fraction of tickets satisfying the price predicate.
SELECT
    COUNT(*) FILTER (WHERE price > 500) AS matched_rows,
    COUNT(*) AS total_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE price > 500)
        / NULLIF(COUNT(*), 0),
        2
    ) AS matching_pct
FROM public.tickets;

-- 4.3 Test whether an index changes the plan.
CREATE INDEX IF NOT EXISTS idx_tickets_price
ON public.tickets(price);

EXPLAIN ANALYZE
SELECT *
FROM public.tickets
WHERE price > 500;

-- Observed outcome: Seq Scan remained in use even with the price index.
-- The query returns 52.34% of all rows and selects every column; an
-- index-assisted plan would still have to fetch many heap rows.
-- CREATE INDEX orders index entries but does NOT physically reorder the heap.

-- 4.5 Remove ONLY the optional experimental price index.
DROP INDEX IF EXISTS public.idx_tickets_price;


-- ==========================================================================
-- DAY 5 — JOIN PLAN AND INDEX SELECTIVITY
-- ==========================================================================

-- 5.1 JFK query, observed before statistics refresh:
-- Hash Join, 1,019 flights and 20,477 matching tickets.
-- Planner estimated 13 JFK flights and 379 joined rows (inaccurate).
EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.departure_airport = 'JFK';

ANALYZE public.flights;
ANALYZE public.tickets;

EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.departure_airport = 'JFK';

-- Observed after refresh: estimated 1,019 JFK flights, actual 1,019;
-- estimated 20,380 joined rows, actual 20,477. Hash Join remained.
-- It builds a small hash table of filtered flights and scans tickets once.

-- 5.2 FRA has roughly the same selectivity as JFK.
EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.departure_airport = 'FRA';

-- Observed: 960 FRA flights out of 5,000; 19,327 matching tickets out of
-- 100,000. Hash Join + Seq Scans. This is still a broad join workload.

-- 5.3 Inspect indexes and check for duplicates.
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('tickets', 'flights')
ORDER BY tablename, indexname;

-- Historical experiment (already completed):
--   CREATE INDEX idx_tickets ON tickets(ticket_id);
--   CREATE INDEX idx_flts ON flights(flt_id);
-- The plan remained a Hash Join with Seq Scans (11.216 vs 11.355 ms).
-- tickets.ticket_id did not help filter or join this query.
-- flights.flt_id is a join key but the hash join does not need indexed
-- flight-by-flight lookups. Both columns were primary keys in this lab,
-- so these extra indexes may duplicate automatically created PK indexes.
-- Do not intentionally recreate duplicate indexes.

-- 5.4 Index the useful ticket-side join key.
CREATE INDEX IF NOT EXISTS idx_tick_flt
ON public.tickets(flt_id);

EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.departure_airport = 'FRA';

-- Observed after creating idx_tick_flt: Hash Join + two Seq Scans.
-- Observed one-run time fell from 11.355 to 9.384 ms, but since the plan
-- did not USE the new index, this is not evidence the index caused a speedup.

-- 5.5 Refresh estimates for both tables.
ANALYZE public.flights;
ANALYZE public.tickets;

EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.departure_airport = 'FRA';

-- Observed: 960 estimated FRA flights vs 960 actual; 19,200 estimated
-- joined rows vs 19,327 actual. Hash Join remained, time 9.464 ms.
-- Hash table: 1,024 buckets, one batch, ~61 kB; no obvious spill issue.

-- 5.6 High-selectivity single-flight lookup.
EXPLAIN ANALYZE
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.flt_id = 100;

-- Observed: Nested Loop; estimated 20 rows, actual 24; time 0.078 ms.
--   Index Scan on flights (idx_flts in the historical run): 1 row.
--   Bitmap Index Scan on tickets (idx_tick_flt): 24 matches.
--   Bitmap Heap Scan: 24 rows across 23 exact heap blocks.
-- The join equality lets PostgreSQL derive t.flt_id = 100 and use the
-- ticket-side index without explicitly writing a second WHERE condition.
-- If idx_flts is removed, the original PK index should serve the same role.

-- 5.7 Caution: 9.464 ms (19,327 rows) vs 0.078 ms (24 rows) is not a
-- like-for-like query optimization benchmark: the result sizes are different.
-- It demonstrates how selectivity affects the preferred join strategy.


-- ==========================================================================
-- DAY 6 — REFERENCE RESOLUTION FOR A CONTROLLED PERFORMANCE INCIDENT
-- ==========================================================================
-- These are reference steps to PERFORM in a disposable lab, not historical
-- observed results. Record your own execution times and plan differences.

-- 6.1 Verify indexes and establish indexed baseline.
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('tickets', 'flights')
ORDER BY tablename, indexname;

CREATE INDEX IF NOT EXISTS idx_tick_flt
ON public.tickets(flt_id);
ANALYZE public.flights;
ANALYZE public.tickets;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.flt_id = 100;

-- 6.2 Simulate missing useful index. Do this ONLY in the learning database.
DROP INDEX IF EXISTS public.idx_tick_flt;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.flt_id = 100;

-- Possible symptom: ticket-side index access is replaced by a scan.
-- Do NOT write 'Seq Scan guaranteed': the optimizer may choose another
-- access path if the database has other suitable indexes or different stats.

-- 6.3 Restore and verify.
CREATE INDEX IF NOT EXISTS idx_tick_flt
ON public.tickets(flt_id);
ANALYZE public.tickets;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    t.ticket_id, t.price, f.flt_id,
    f.departure_airport, f.arrival_airport, f.departure_time
FROM public.tickets AS t
JOIN public.flights AS f ON t.flt_id = f.flt_id
WHERE f.flt_id = 100;

-- 6.4 Incident response template (fill in from YOUR measurements):
-- Symptom:     Single-flight lookup became slower / more I/O-intensive.
-- Evidence:    Before: [indexed plan]; during: [observed alternate plan].
-- Root cause:  The ticket-side flt_id index was removed in the lab.
-- Remediation: Recreated idx_tick_flt on tickets(flt_id).
-- Verification: Compare actual plan, execution time and BUFFERS before,
--               during and after the incident; do not invent measurements.

-- 6.5 CLEANUP CHECK (safe: review before dropping experimental indexes).
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('tickets', 'flights')
ORDER BY tablename, indexname;

-- If primary-key indexes exist, these historical manually created indexes
-- are likely redundant. Uncomment ONLY after checking the index catalogue:
-- DROP INDEX IF EXISTS public.idx_tickets;
-- DROP INDEX IF EXISTS public.idx_flts;
-- Retain public.idx_tick_flt for selective join experiments.

-- END OF WEEK 10 (DAYS 3–6)