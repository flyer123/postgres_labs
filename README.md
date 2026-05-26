# Flight Analytics SQL Lab

Production-style PostgreSQL training environment focused on:

- analytical SQL
- window functions
- query debugging
- KPI correctness
- anti-pattern detection
- data engineering thinking

The project simulates realistic airline/business datasets and trains SQL skills through short daily exercises and debugging scenarios.

---

# 🚀 Goals

This lab is designed to develop:

- production-grade SQL reasoning
- analytical debugging skills
- understanding of aggregation grain
- window function mastery
- join cardinality awareness
- incremental pipeline thinking
- KPI validation techniques

The exercises intentionally include:
- duplicated rows
- incorrect joins
- NULL traps
- event-stream problems
- broken analytical queries

---

# 🧱 Tech Stack

- PostgreSQL
- Docker
- Docker Compose
- Python (data generation)

---

# 📂 Project Structure

```text
flight-analytics-sql-lab/
│
├── docker-compose.yml
├── init.sql
├── seed.sql
├── generate_data.py
│
├── datasets/
│   ├── flights.csv
│   ├── tickets.csv
│   ├── passengers.csv
│   ├── airports.csv
│   └── events.csv
│
├── exercises/
│   ├── week1.md
│   ├── week2.md
│   ├── week3.md
│   ├── week4.md
│   ├── week5.md
│   ├── week5_5_1.md
│   ├── week5_5_2.md
│   ├── week6.md
│   ├── week7.md
│   ├── week8.md
│   ├── week10.md
│   ├── week11.md
│   └── week12.md
│
└── solutions/
    ├── week5_5_1_solutions.md
    └── week5_5_2_solutions.md
```

---

# 🗄️ Dataset Overview

The lab models a simplified airline analytics platform.

---

## flights

Represents scheduled flights.

| Column | Description |
|---|---|
| flt_id | flight id |
| departure_airport | departure airport |
| arrival_airport | destination airport |
| departure_time | departure timestamp |
| arrival_time | arrival timestamp |
| status | flight status |

---

## tickets

Represents ticket purchases.

| Column | Description |
|---|---|
| ticket_id | ticket id |
| flt_id | related flight |
| passenger_id | passenger |
| price | ticket price |
| booking_time | booking timestamp |

---

## passengers

Passenger dimension table.

| Column | Description |
|---|---|
| passenger_id | passenger id |
| country | passenger country |
| signup_date | signup date |

---

## airports

Airport reference table.

| Column | Description |
|---|---|
| airport_code | airport code |
| city | city |
| country | country |

---

## events

Append-only activity/event stream.

Examples:
- booking
- checkin
- cancel

| Column | Description |
|---|---|
| event_id | event id |
| event_type | type of event |
| entity_id | references ticket_id |
| event_time | event timestamp |

---

# 🔥 Important Modeling Concept

Relationship:

```text
tickets.ticket_id → events.entity_id
```

This is:

```text
1 ticket → many events
```

This relationship intentionally trains:
- join explosion detection
- duplicated KPI debugging
- event-stream analytics

---

# ⚙️ Setup

## 1. Generate datasets

```bash
python generate_data.py
```

## 2. Start PostgreSQL

```bash
docker-compose up -d
```

## 3. Connect to database

```bash
docker exec -it postgres-lab psql -U postgres -d flights_db
```

---

# 📘 Training Format

Each week contains:
- 10–15 minute exercises
- one business scenario/debugging incident
- analytical SQL focus

---

# 🧠 Topics Covered

## Week 1
Basic querying & filtering

## Week 2
Aggregations & KPI validation

## Week 3
Joins & row multiplication

## Week 4
Subqueries vs joins

## Week 5
Window function foundations

## Week 5.5.1
Business analytics with windows

## Week 5.5.2
Advanced analytical debugging

## Week 6
Advanced windows & ranking

## Week 7
Deduplication & analytical correctness

## Week 8
Event-stream analytics

## Week 10
Execution plans & indexing

## Week 11
Data quality validation

## Week 12
Incremental pipelines & idempotency

---

# 🔥 Core Concepts Trained

## Aggregation Grain

Understanding:

```text
what one row represents
```

Critical for:
- KPI correctness
- dashboard reliability
- pipeline safety

---

## Join Cardinality

Recognizing:
- 1:1
- 1:N
- N:N

Preventing:
- metric inflation
- duplicated revenue
- incorrect counts

---

## Window Functions

Learning:
- ROW_NUMBER
- RANK
- DENSE_RANK
- LAG
- cumulative metrics
- moving averages
- sessionization

---

## Event Analytics

Modeling:
- event streams
- timelines
- sequence validation
- analytical state transitions

---

# 🚨 Common Failure Scenarios

This lab intentionally reproduces:

- join explosions
- duplicated KPIs
- incorrect ranking
- broken cumulative sums
- NULL anti-join bugs
- bad deduplication
- slow correlated subqueries
- incorrect partitioning
- incremental load duplication

---

# 📈 Recommended Workflow

For every exercise:

1. Identify row grain
2. Check join cardinality
3. Validate counts before/after joins
4. Compare:
   - COUNT(*)
   - COUNT(DISTINCT ...)
   - SUM(...)
5. Use EXPLAIN ANALYZE for performance exercises

---

# 🧪 Example Validation Pattern

```sql
SELECT COUNT(*) FROM tickets;

SELECT COUNT(*)
FROM tickets t
JOIN events e
  ON e.entity_id = t.ticket_id;
```

If second count is much larger:
- row multiplication exists

---

# 🎯 Learning Outcome

After completing this lab you should be able to:

- write analytical SQL confidently
- debug broken KPIs
- reason about data grain
- use window functions correctly
- detect join explosions
- design safer transformations
- think like a data engineer, not only a SQL user

---

# 🚀 Suggested Extensions

Possible future upgrades:

- dbt models
- Airflow orchestration
- Spark SQL version
- incremental ETL pipelines
- KPI monitoring tests
- Great Expectations validation
- Superset dashboards
- medallion architecture