/*
Week 9 — Transactions, Locks & Concurrency
Answers
*/


-- ============================================================
-- DAY 1 — TRANSACTIONS
-- ============================================================

/*
BEGIN starts a transaction.

COMMIT makes the transaction's changes permanent.

ROLLBACK discards the transaction's changes.
*/


BEGIN;

UPDATE tickets
SET price = price + 100
WHERE ticket_id = 40;

SELECT ticket_id, price
FROM tickets
WHERE ticket_id = 40;

ROLLBACK;


/*
After ROLLBACK, the price returns to its previous
committed value.
*/


-- ============================================================
-- DAY 2 — READ COMMITTED
-- ============================================================

/*
PostgreSQL's default isolation level is READ COMMITTED.

An uncommitted change made by Session A is not visible
to Session B.

After Session A commits, a new statement in Session B
can see the committed value.

READ COMMITTED provides statement-level visibility.
*/


-- ============================================================
-- DAY 3 — SELECT FOR UPDATE
-- ============================================================

/*
SELECT ... FOR UPDATE obtains a row-level lock.

If another transaction already holds the conflicting lock,
the second transaction waits until the first transaction
commits or rolls back.
*/


-- ============================================================
-- DAY 4 — BLOCKING
-- ============================================================

SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE datname = 'flights_db';


/*
A session with:

    state = active
    wait_event_type = Lock

is typically waiting for a lock.

A session shown as:

    idle in transaction

may still hold locks because its transaction remains open.

The blocking session must eventually COMMIT or ROLLBACK
to release those locks.
*/


-- ============================================================
-- DAY 5 — DEADLOCK
-- ============================================================

/*
Lock sequence:

Session A:
    locks ticket 40
    waits for ticket 41

Session B:
    locks ticket 41
    waits for ticket 40

Therefore:

    A → B
    B → A

This creates a circular wait.

PostgreSQL detects the deadlock and aborts one
of the transactions.
*/


/*
Example PostgreSQL error:

ERROR: deadlock detected

DETAIL:
Process 46 waits for ShareLock on transaction 745;
blocked by process 39.

Process 39 waits for ShareLock on transaction 746;
blocked by process 46.
*/


-- ============================================================
-- DAY 6 — PRODUCTION INCIDENT
-- ============================================================

/*
Scenario:

Worker A:

    ticket 40
        ↓
    ticket 41


Worker B:

    ticket 41
        ↓
    ticket 40


Lock dependency:

Worker A holds 40
Worker B holds 41

Worker A waits for 41
Worker B waits for 40


Circular dependency:

    Worker A → Worker B
          ↑       ↓
          └───────┘
*/


-- ============================================================
-- PREVENTION
-- ============================================================

/*
Strategy 1 — Consistent lock acquisition order

All workers acquire locks in the same deterministic order,
for example:

    40 → 41

and never:

    41 → 40

This prevents the circular wait.

The second worker may still WAIT, but a deadlock cannot
be formed by this ordering.
*/


/*
Strategy 2 — Short transactions + retry

Keep transactions as short as practical:

    BEGIN
        acquire locks
        perform required changes
    COMMIT

Avoid unrelated work while locks are held.

Treat PostgreSQL deadlock errors (SQLSTATE 40P01)
as retryable transient failures:

    ROLLBACK
    wait/backoff
    retry transaction

This does not structurally prevent every deadlock,
but provides resilience when one occurs.
*/


-- ============================================================
-- FINAL MONITORING QUERY
-- ============================================================

SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE datname = 'flights_db';