# PostgreSQL Data Platform Engineering Routine

A structured PostgreSQL learning routine combining:

- Advanced SQL
- Data Quality Engineering
- Data QA
- Query performance tuning
- PostgreSQL internals
- Transaction and concurrency management
- Incremental data processing
- Data platform engineering

The project started as an analytical SQL practice routine and is gradually evolving toward a **Data Platform Engineering laboratory**.

The original FlightDB remains the core relational dataset. Additional schemas and tables are added around it to simulate ingestion pipelines, event streams, data-quality failures, incremental processing, and production incidents.

---

# Goals

The primary goal is not simply to learn more SQL syntax.

The goal is to become comfortable using PostgreSQL for both:

### Analytical work

- joins
- aggregations
- window functions
- CTEs
- subqueries
- CASE expressions
- NULL handling
- analytical timelines
- business metrics

### Data QA

- data-quality rules
- referential-integrity validation
- business-rule validation
- anomaly detection
- validation summaries
- severity levels
- alert thresholds
- persisted validation results

### Data Platform Engineering

- staging tables
- incremental loading
- idempotent processing
- deduplication
- transactions
- isolation levels
- locking
- deadlocks
- indexes
- EXPLAIN ANALYZE
- query optimization
- partitioning
- materialized views
- PostgreSQL statistics
- VACUUM / ANALYZE
- pipeline metadata

---

# Core Principle

## Do not corrupt the original FlightDB

The original FlightDB is treated as an **immutable source system**.

Existing tables are used as the source of truth for the exercises.

We do **not** intentionally modify valid source records to create failures.

Instead, failures are introduced through separate staging, event, and data-quality tables.

This allows incidents to be:

- reproducible
- resettable
- isolated
- repeatable
- safely investigated

The same incident can therefore be executed multiple times without destroying the original dataset.

---

# Architecture

The project gradually evolves into the following logical architecture:

```text
                         ┌─────────────────────────┐
                         │       FlightDB           │
                         │                         │
                         │   Original source data  │
                         │                         │
                         │ flights                 │
                         │ tickets                 │
                         │ passengers              │
                         │ airports                │
                         │ boarding_passes         │
                         │ etc.                    │
                         └────────────┬────────────┘
                                      │
                                      │ read
                                      ▼
                         ┌─────────────────────────┐
                         │        staging          │
                         │                         │
                         │ tickets_raw             │
                         │ flights_raw             │
                         │ batch metadata          │
                         └────────────┬────────────┘
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                         ▼                         ▼
                ┌──────────────────┐      ┌──────────────────┐
                │       ops        │      │        dq        │
                │                  │      │                  │
                │ events           │      │ rule_catalog     │
                │ pipeline_runs    │      │ error_injection  │
                │ job metadata     │      │ validation_results│
                └────────┬─────────┘      └────────┬─────────┘
                         │                         │
                         └────────────┬────────────┘
                                      ▼
                         ┌─────────────────────────┐
                         │         mart            │
                         │                         │
                         │ daily_revenue           │
                         │ reporting tables        │
                         │ materialized views      │
                         └─────────────────────────┘
```

The important distinction is:

```text
SOURCE DATA
    ↓
staging
    ↓
processing / validation
    ↓
mart
```

---

# Repository Structure

```text
postgres-routine/
│
├── docker/
│   └── docker-compose.yml
│
├── data/
│   ├── generate_data.py
│   ├── generate_events.py
│   ├── generate_errors.py
│   └── csv/
│       ├── events.csv
│       └── bad_batches.csv
│
├── sql/
│   ├── schema.sql
│   ├── seed.sql
│   │
│   ├── schemas/
│   │   ├── staging.sql
│   │   ├── ops.sql
│   │   ├── dq.sql
│   │   └── mart.sql
│   │
│   └── views/
│       └── reporting_views.sql
│
├── exercises/
│   ├── week1.sql
│   ├── week2.sql
│   ├── ...
│   ├── week8.sql
│   ├── week9.sql
│   ├── week10.sql
│   ├── week11.sql
│   ├── week12.sql
│   ├── week13.sql
│   ├── week14.sql
│   ├── week15.sql
│   └── week16.sql
│
├── answers/
│   ├── week1.sql
│   ├── week2.sql
│   ├── ...
│   ├── week8.sql
│   ├── week9.sql
│   ├── week10.sql
│   ├── week11.sql
│   ├── week12.sql
│   ├── week13.sql
│   ├── week14.sql
│   ├── week15.sql
│   └── week16.sql
│
├── incidents/
│   ├── incident01_replay.sql
│   ├── incident02_deadlock.sql
│   ├── incident03_slow_query.sql
│   ├── incident04_bad_data.sql
│   └── incident05_duplicate_pipeline.sql
│
├── docs/
│   ├── reading.md
│   ├── architecture.md
│   └── explain_cheatsheet.md
│
└── README.md
```

Existing weeks and exercises are preserved.

The repository is extended rather than replaced.

---

# Database Layers

## 1. Existing FlightDB

The original FlightDB contains the business entities used throughout the routine.

Examples include:

```text
flights
tickets
ticket_flights
boarding_passes
airports
aircrafts
bookings
passengers
```

These tables are treated as **source data**.

### Rule

Do not intentionally introduce invalid data directly into these tables.

---

# 2. `staging`

The staging layer represents incoming data from an external source.

Examples:

```text
staging.tickets_raw
staging.flights_raw
```

Staging data may contain:

- duplicates
- missing references
- invalid values
- late-arriving records
- repeated batches
- malformed timestamps

Unlike the source tables, staging data is deliberately disposable.

---

# 3. `ops`

Operational metadata and event data.

Examples:

```text
ops.events
ops.pipeline_runs
```

`ops.events` simulates an event stream such as:

```text
booking
checkin
boarding
cancel
```

The table is used for event-ordering and event-quality exercises.

`ops.pipeline_runs` records information about simulated pipeline executions.

Example:

```text
run_id
pipeline_name
status
started_at
finished_at
rows_processed
```

---

# 4. `dq`

Data-quality infrastructure.

Examples:

```text
dq.rule_catalog
dq.error_injection
dq.validation_results
```

## `dq.rule_catalog`

Defines validation rules.

Example:

```text
DQ-001  Missing flight reference       HIGH
DQ-002  Negative ticket price          HIGH
DQ-003  Duplicate booking event       MEDIUM
DQ-004  Invalid event sequence         HIGH
DQ-005  Future passenger date          LOW
DQ-006  Arrival before departure       HIGH
```

## `dq.error_injection`

Defines controlled failures.

Example:

```text
ticket_no    error_type
----------   ----------------
T001         DUPLICATE_EVENT
T017         NEGATIVE_PRICE
T103         MISSING_FLIGHT
```

The table controls which synthetic failures are active.

## `dq.validation_results`

Stores the results of validation.

Example:

```text
run_id
rule_id
severity
record_id
message
detected_at
```

This changes the exercise from:

```text
SELECT invalid records;
```

to:

```text
run validation
    ↓
detect failures
    ↓
persist failures
    ↓
summarize failures
    ↓
evaluate thresholds
    ↓
trigger alert
```

This is much closer to a real Data QA pipeline.

---

# 5. `mart`

The mart layer contains derived reporting and analytical data.

Examples:

```text
mart.daily_revenue
mart.passenger_activity
```

These tables are used to practice:

- incremental processing
- aggregation
- materialized views
- refresh strategies
- idempotency
- performance optimization

---

# Learning Progression

The first part of the routine develops SQL fundamentals and analytical SQL.

The later part gradually moves toward database and data-platform engineering.

```text
SQL Fundamentals
       ↓
Analytical SQL
       ↓
Advanced SQL
       ↓
Data QA
       ↓
Query Performance
       ↓
Transactions & Concurrency
       ↓
Incremental Processing
       ↓
Partitioning
       ↓
Materialized Views
       ↓
PostgreSQL Internals
```

---

# Weeks 1–7

Weeks 1–7 remain unchanged.

They establish the SQL foundation required for the later platform-oriented work.

Topics include:

- SELECT
- WHERE
- ORDER BY
- aggregation
- GROUP BY
- HAVING
- JOINs
- CASE
- subqueries
- NULL handling
- CTEs
- window functions
- analytical SQL

The objective is to become comfortable reasoning about relational data before moving into database engineering.

---

# Week 8 — Event Processing & Analytical Windows

### Goal

Combine analytical SQL with event-stream reasoning.

### Day 1

Count events per type.

Additional task:

- analyze event distribution
- identify unusually frequent event types

### Day 2

Join events with tickets.

```text
events → tickets
```

Then extend the analysis:

```text
events → tickets → flights
```

### Day 3

Find tickets with a booking event but no check-in event.

### Day 4

Find invalid sequences such as:

```text
booking
checkin
cancel
```

or:

```text
booking
cancel
boarding
```

Use `LAG()` / `LEAD()` where appropriate.

### Day 5

Build an ordered event timeline per ticket.

### Day 6 — Production Scenario

## Event stream is inconsistent

Tasks:

1. Detect invalid sequences.
2. Detect duplicate events.
3. Determine the expected lifecycle.
4. Write reusable validation SQL.
5. Explain the likely source of the problem.

### Platform extension

Create and query:

```text
ops.events
```

---

# Week 9 — Transactions & Concurrency

### Goal

Understand how PostgreSQL behaves when multiple processes interact with the same data.

### Day 1

Practice:

```sql
BEGIN;
COMMIT;
ROLLBACK;
```

### Day 2

Investigate transaction isolation.

Focus on:

- READ COMMITTED
- REPEATABLE READ
- SERIALIZABLE

### Day 3

Row-level locking.

Practice:

```sql
SELECT ...
FOR UPDATE;
```

### Day 4

Create a controlled deadlock using two database sessions.

Investigate:

- what happened
- which transaction was aborted
- how PostgreSQL detected the deadlock

### Day 5

Design a safe retry strategy.

### Day 6 — Production Scenario

Two pipeline workers attempt to update related records simultaneously.

Tasks:

1. Reproduce the blocking.
2. Inspect the transactions.
3. Identify the lock.
4. Explain the failure.
5. Propose a safer transaction strategy.

---

# Week 10 — Query Performance Engineering

### Goal

Move from writing queries to understanding how PostgreSQL executes them.

### Day 1

Run:

```sql
EXPLAIN ANALYZE
```

on ticket lookup queries.

Understand:

- estimated rows
- actual rows
- cost
- execution time
- sequential scans

### Day 2

Create an index and compare:

```text
before index
vs
after index
```

### Day 3

Investigate indexes involving:

```text
passenger_id
flight_id
ticket_id
```

### Day 4

Identify and explain a sequential scan.

### Day 5

Optimize a join between tickets and flights.

Investigate:

- Nested Loop
- Hash Join
- Merge Join

### Day 6 — Production Scenario

A production query became significantly slower.

Tasks:

1. Run `EXPLAIN ANALYZE`.
2. Identify the bottleneck.
3. Determine whether the problem is:
   - scan
   - join
   - filtering
   - sorting
   - missing index
4. Propose an optimization.
5. Measure the result.

---

# Week 11 — Data Quality Engineering

### Goal

Move from one-off validation queries to a reusable DQ framework.

### Day 1

Validate impossible flight timestamps.

Example:

```text
arrival_time < departure_time
```

### Day 2

Validate invalid ticket prices.

Examples:

```text
price < 0
price IS NULL
```

### Day 3

Validate referential integrity.

Examples:

```text
ticket references missing flight
ticket references missing passenger
```

### Day 4

Validate unrealistic dates.

Example:

```text
signup_date > current_date
```

### Day 5

Build a validation summary.

Example:

```text
rule_id     invalid_records
--------    ---------------
DQ-001      12
DQ-002       3
DQ-003      27
DQ-004       8
```

Persist detailed failures into:

```text
dq.validation_results
```

### Day 6 — Production Scenario

A pipeline begins producing bad data.

Tasks:

1. Execute the DQ rules.
2. Store failures.
3. Group failures by rule.
4. Calculate failure percentages.
5. Define alert thresholds.
6. Decide which rules should block the pipeline.

---

# Week 12 — Incremental Processing & Idempotency

### Goal

Understand how production pipelines safely load data repeatedly.

### Day 1

Create a staging table.

```text
staging.tickets_raw
```

Load a batch of data.

### Day 2

Insert only new records into the target table.

### Day 3

Deduplicate staging data.

Use:

```sql
ROW_NUMBER()
```

to identify duplicate records.

### Day 4

Build:

```text
mart.daily_revenue
```

### Day 5

Make the pipeline idempotent.

The following should produce the same final state:

```text
run batch A
run batch A again
run batch A again
```

### Day 6 — Final Scenario

## Pipeline rerun creates duplicates

Tasks:

1. Reproduce the problem.
2. Identify the flaw.
3. Fix the incremental logic.
4. Make the operation idempotent.
5. Rerun the batch.
6. Prove that no duplicates were introduced.

---

# Week 13 — Recursive SQL

### Goal

Learn recursive queries and hierarchical traversal.

Topics:

- recursive CTEs
- dependency chains
- route traversal
- graph-like relationships
- recursive aggregation

### Scenario

Find possible airport connection paths.

### Theory

PostgreSQL documentation on:

```text
WITH RECURSIVE
```

No additional book is required.

---

# Week 14 — Partitioning

### Goal

Understand how PostgreSQL handles large tables.

Create a partitioned event table.

Possible strategy:

```text
ops.events
    ├── events_2026_01
    ├── events_2026_02
    ├── events_2026_03
    └── ...
```

Tasks:

- range partitioning
- partition pruning
- partition maintenance
- adding partitions
- retention
- comparing partitioned and non-partitioned queries

### Production Scenario

The events table has grown substantially and queries scanning recent events have become expensive.

Determine whether partitioning helps.

---

# Week 15 — Materialized Views & Refresh Strategies

### Goal

Understand how PostgreSQL can provide precomputed analytical data.

Build:

```text
mart.daily_revenue
```

and one or more materialized views.

Compare:

```text
ordinary view
vs
materialized view
vs
precomputed table
```

Topics:

- refresh
- `REFRESH MATERIALIZED VIEW`
- concurrent refresh
- indexes on materialized views
- refresh strategy

### Production Scenario

A dashboard repeatedly executes an expensive aggregation.

Design a more efficient reporting layer.

---

# Week 16 — PostgreSQL Internals & Maintenance

### Goal

Begin understanding PostgreSQL as a database system rather than only a SQL engine.

Topics:

- VACUUM
- ANALYZE
- autovacuum
- table statistics
- query planner statistics
- `pg_stat_statements`
- table bloat
- stale statistics
- planner decisions

### Production Scenario

A query that normally runs quickly becomes dramatically slower.

Investigate:

1. execution plan
2. statistics
3. table state
4. indexes
5. planner decisions

Do not assume that every performance problem is caused by a missing index.

---

# Production Incident Framework

Starting with Week 8, every week contains a production-style scenario.

The incidents are deliberately different from ordinary exercises.

An exercise asks:

> Can you write this SQL?

An incident asks:

> Something is wrong. Can you determine what happened?

The incident workflow is:

```text
Observe
   ↓
Reproduce
   ↓
Measure
   ↓
Investigate
   ↓
Identify root cause
   ↓
Fix
   ↓
Validate
   ↓
Prevent recurrence
```

---

# Planned Incidents

## Incident 001 — Event Replay

A producer retries a message and the same event appears twice.

Skills:

- duplicate detection
- window functions
- event sequencing
- DQ rules

---

## Incident 002 — Deadlock

Two workers acquire locks in an unsafe order.

Skills:

- transactions
- row locks
- isolation
- deadlock analysis

---

## Incident 003 — Slow Query

A query becomes significantly slower.

Skills:

- EXPLAIN ANALYZE
- indexes
- query plans
- join strategies

---

## Incident 004 — Bad Data

A pipeline introduces invalid records.

Skills:

- DQ rules
- validation results
- thresholds
- severity
- pipeline blocking

---

## Incident 005 — Duplicate Pipeline Run

A batch is processed twice.

Skills:

- staging
- deduplication
- UPSERT / MERGE
- idempotency
- pipeline metadata

---

# Data Quality Philosophy

Data-quality failures should be **controlled and reproducible**.

Do not modify source records such as:

```text
tickets
flights
passengers
```

to create a failure.

Instead use:

```text
dq.error_injection
```

or deliberately malformed staging/event records.

For example:

```text
Original:

ticket T001
price = 250

Injected scenario:

ticket T001
error_type = NEGATIVE_PRICE
```

The validation layer then interprets the active error and produces the corresponding failure.

This provides a clean separation:

```text
SOURCE
  │
  │ immutable
  ▼
STAGING / EVENTS
  │
  │ controlled failures
  ▼
DQ
  │
  ▼
VALIDATION RESULTS
```

---

# Theory & Reading

Theory is introduced **only when it becomes necessary for the practical work**.

The goal is not to read several PostgreSQL books from cover to cover.

---

## Primary Book

### SQL Performance Explained — Markus Winand

Used primarily during Weeks 8–10.

Focus on:

- indexes
- execution plans
- filtering
- joins
- sorting
- query performance

Do not read the entire book unless a topic becomes relevant.

---

## PostgreSQL Reference

### PostgreSQL Documentation

Used for topics where official documentation is more useful than a textbook:

- recursive CTEs
- partitioning
- materialized views
- VACUUM
- ANALYZE
- statistics
- PostgreSQL configuration

---

## PostgreSQL: Up & Running

Use selected sections when Week 9 introduces:

- transactions
- MVCC
- isolation
- locks
- concurrency

No need to read the whole book.

---

## Designing Data-Intensive Applications

Use selected sections when the PostgreSQL exercises introduce broader data-platform concepts such as:

- storage
- batch processing
- idempotency
- consistency
- data systems architecture

DDIA is supplementary theory, not a PostgreSQL manual.

---

# Reading Rule

The order is:

```text
Practical problem
      ↓
Attempt solution
      ↓
Identify knowledge gap
      ↓
Read relevant theory
      ↓
Return to the exercise
      ↓
Apply the concept
```

Not:

```text
Read 500 pages
      ↓
Hope it becomes useful
```

---

# Weekly Structure

Each week follows approximately:

```text
Day 1
Analytical / SQL concept

Day 2
SQL + relational reasoning

Day 3
Platform concept

Day 4
Implementation

Day 5
Integration / optimization

Day 6
Production incident
```

Some weeks will deviate when the topic requires it.

---

# Exercise Philosophy

Solutions should not be copied immediately.

For each task:

1. Understand the problem.
2. Write the query independently.
3. Execute it.
4. Inspect the result.
5. Check edge cases.
6. Optimize where appropriate.
7. Compare with the answer only afterward.

For performance exercises:

```text
baseline
   ↓
EXPLAIN ANALYZE
   ↓
change
   ↓
EXPLAIN ANALYZE
   ↓
compare
```

For DQ exercises:

```text
rule
   ↓
detect
   ↓
count
   ↓
classify
   ↓
persist
   ↓
evaluate threshold
```

For pipeline exercises:

```text
load
   ↓
validate
   ↓
deduplicate
   ↓
transform
   ↓
write
   ↓
rerun
   ↓
verify idempotency
```

---

# Skills Covered

| Skill | Covered |
|---|---:|
| SELECT / filtering | ✓ |
| Aggregations | ✓ |
| GROUP BY / HAVING | ✓ |
| JOINs | ✓ |
| CASE | ✓ |
| Subqueries | ✓ |
| CTEs | ✓ |
| Window functions | ✓ |
| Recursive CTEs | ✓ |
| NULL handling | ✓ |
| Data validation | ✓ |
| Data QA | ✓ |
| Event sequencing | ✓ |
| Transactions | ✓ |
| MVCC | ✓ |
| Isolation levels | ✓ |
| Row locking | ✓ |
| Deadlocks | ✓ |
| Indexes | ✓ |
| EXPLAIN ANALYZE | ✓ |
| Query optimization | ✓ |
| Join strategies | ✓ |
| Staging | ✓ |
| Deduplication | ✓ |
| Incremental processing | ✓ |
| Idempotency | ✓ |
| Partitioning | ✓ |
| Materialized views | ✓ |
| VACUUM / ANALYZE | ✓ |
| PostgreSQL statistics | ✓ |
| Production debugging | ✓ |

---

# Target Outcome

By the end of the routine, the objective is to be able to look at a PostgreSQL-based data pipeline and reason about more than just the SQL query.

For example:

```text
The query is slow.
        ↓
Is the query itself wrong?
        ↓
What does EXPLAIN ANALYZE show?
        ↓
Is an index appropriate?
        ↓
Is the planner estimating correctly?
        ↓
Is the table partitioned appropriately?
        ↓
Is the data being duplicated upstream?
        ↓
Is the pipeline idempotent?
        ↓
Are DQ failures being recorded?
        ↓
Can the problem be reproduced?
        ↓
Can the fix be validated?
```

The ultimate goal is to develop the mindset required for:

- Data QA Engineer
- Analytics Engineer
- Data Engineer
- Data Platform Engineer
- Data Infrastructure Engineer

while retaining strong analytical SQL skills.

---

# Progress

Current starting point:

**Week 8**

Completed:

- Weeks 1–7

Current focus:

- Event processing
- Window functions
- Data-quality validation
- Production-style SQL incidents

Next:

- Week 9 — Transactions & Concurrency
- Week 10 — Query Performance
- Week 11 — Data Quality Engineering
- Week 12 — Incremental Processing
- Week 13 — Recursive SQL
- Week 14 — Partitioning
- Week 15 — Materialized Views
- Week 16 — PostgreSQL Internals

---

# Project Principle

This repository is not intended to become a collection of isolated SQL puzzles.

It is a progressively evolving **PostgreSQL laboratory**.

The progression is:

```text
Write SQL
    ↓
Understand relational data
    ↓
Validate data
    ↓
Diagnose failures
    ↓
Understand query execution
    ↓
Control transactions
    ↓
Build incremental processing
    ↓
Optimize storage
    ↓
Understand PostgreSQL internals
```

The original analytical SQL work remains important.

The difference is that from Week 8 onward, SQL is increasingly used as a tool for **building, validating, operating, and troubleshooting data systems**.