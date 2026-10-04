/*
Week 9 — Transactions, Locks & Concurrency

Goal:
Understand how PostgreSQL behaves when multiple transactions
interact with the same data.

Topics:
1. BEGIN / COMMIT / ROLLBACK
2. READ COMMITTED
3. Row-level locking
4. SELECT ... FOR UPDATE
5. Blocking
6. Deadlocks
7. Deadlock prevention
8. Production-style concurrency investigation

Important:
Several exercises require TWO or THREE separate psql sessions.
Do not execute Session A and Session B statements in the same session.
*/


-- ============================================================
-- DAY 1 — TRANSACTIONS
-- ============================================================

-- Exercise 1.1
-- Start a transaction and change a ticket price.
-- Verify the change inside the transaction.
-- Then ROLLBACK and verify that the original value is restored.


-- Exercise 1.2
-- Start another transaction, change the price,
-- and COMMIT the change.
-- Verify that the committed value is visible.


-- ============================================================
-- DAY 2 — READ COMMITTED
-- ============================================================

-- Requires Session A and Session B.

-- Session A:
-- BEGIN;
-- UPDATE tickets
-- SET price = price + 100
-- WHERE ticket_id = 40;

-- Session B:
-- BEGIN;
-- SELECT ticket_id, price
-- FROM tickets
-- WHERE ticket_id = 40;

-- Question:
-- Does Session B see Session A's uncommitted change?
-- Explain why.


-- Continue the experiment:
-- Session A:
-- COMMIT;

-- Session B:
-- Execute the SELECT again.

-- Question:
-- What changed and why?


-- ============================================================
-- DAY 3 — ROW-LEVEL LOCKING
-- ============================================================

-- Session A:
-- BEGIN;
-- SELECT ticket_id, price
-- FROM tickets
-- WHERE ticket_id = 40
-- FOR UPDATE;

-- Session B:
-- BEGIN;
-- SELECT ticket_id, price
-- FROM tickets
-- WHERE ticket_id = 40
-- FOR UPDATE;

-- Question:
-- What happens to Session B?
-- Why?


-- ============================================================
-- DAY 4 — IDENTIFYING BLOCKING
-- ============================================================

-- Create blocking intentionally using two sessions.

-- Session A:
-- BEGIN;
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 40;

-- Session B:
-- BEGIN;
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 40;


-- Session C:
-- Identify active sessions and determine which session
-- is waiting for a lock.

SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE datname = 'flights_db';


-- Question:
-- Which PID is waiting?
-- Which PID is blocking it?


-- ============================================================
-- DAY 5 — DEADLOCK
-- ============================================================

-- Use TWO separate sessions.

-- Session A:
-- BEGIN;
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 40;


-- Session B:
-- BEGIN;
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 41;


-- Session A:
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 41;


-- Session B:
-- UPDATE tickets
-- SET price = price + 1
-- WHERE ticket_id = 40;


-- Questions:
--
-- 1. Which session becomes blocked first?
-- 2. What happens after the second session attempts its UPDATE?
-- 3. Which transaction does PostgreSQL abort?
-- 4. Explain the circular wait.
-- 5. Why is this different from ordinary blocking?


-- After the deadlock:
-- ROLLBACK in the affected session(s).


-- ============================================================
-- DAY 6 — PRODUCTION INCIDENT
-- ============================================================

/*
Scenario:

Two pipeline workers process overlapping sets of tickets.

Worker A processes:
    40 → 41

Worker B processes:
    41 → 40

Both workers perform updates inside transactions.

Your task:

1. Reproduce the deadlock.
2. Identify the blocking sessions.
3. Draw the lock dependency.
4. Explain why PostgreSQL aborts one transaction.
5. Propose TWO strategies for preventing the deadlock.

Do NOT use "exchange information between workers before
starting the transaction" as a prevention strategy.
*/


-- Monitoring query:

SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE datname = 'flights_db';


-- Optional deeper lock investigation:

SELECT
    a.pid,
    a.state,
    a.wait_event_type,
    a.wait_event,
    l.locktype,
    l.mode,
    l.granted,
    l.relation::regclass,
    l.transactionid,
    a.query
FROM pg_stat_activity a
JOIN pg_locks l
    ON l.pid = a.pid
WHERE a.datname = 'flights_db';


/*
Prevention strategies to investigate:

1. Consistent lock acquisition order.

2. Short transactions + retry with backoff
   for transient deadlock failures.
*/