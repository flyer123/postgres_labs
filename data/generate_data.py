import random
from datetime import datetime, timedelta
import csv

N_FLIGHTS = 5000
N_PASSENGERS = 20000
N_TICKETS = 100000
N_EVENTS = 50000

AIRPORTS = [
    ("JFK", "New York", "US"),
    ("LHR", "London", "UK"),
    ("CDG", "Paris", "FR"),
    ("FRA", "Frankfurt", "DE"),
    ("DXB", "Dubai", "AE")
]

def rand_time(days=60):
    return datetime.now() - timedelta(days=random.randint(0, days))

# -------------------
# Airports
# -------------------
with open("airports.csv", "w", newline="") as f:
    w = csv.writer(f)
    for code, city, country in AIRPORTS:
        w.writerow([code, city, country])

# -------------------
# Flights
# -------------------
with open("flights.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, N_FLIGHTS + 1):
        dep_airport = random.choice(AIRPORTS)[0]
        arr_airport = random.choice(AIRPORTS)[0]

        dep = rand_time()
        arr = dep + timedelta(hours=random.randint(1, 10))

        # Inject bad data (for validation tasks)
        if random.random() < 0.01:
            arr = dep - timedelta(hours=2)  # invalid

        status = random.choice(["scheduled", "delayed", "cancelled"])

        w.writerow([i, dep_airport, arr_airport, dep, arr, status])

# -------------------
# Passengers
# -------------------
with open("passengers.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, N_PASSENGERS + 1):
        country = random.choice(["US", "UK", "FR", "DE"])
        signup = datetime.now().date() - timedelta(days=random.randint(0, 365))
        w.writerow([i, country, signup])

# -------------------
# Tickets
# -------------------
with open("tickets.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, N_TICKETS + 1):
        flt_id = random.randint(1, N_FLIGHTS)
        passenger_id = random.randint(1, N_PASSENGERS)

        price = random.randint(50, 1000)

        # Inject bad data
        if random.random() < 0.01:
            price = -100

        booking_time = rand_time()

        w.writerow([i, flt_id, passenger_id, price, booking_time])

# -------------------
# Events (for pipeline thinking)
# -------------------
EVENT_TYPES = ["booking", "cancel", "checkin"]

with open("events.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, N_EVENTS + 1):
        event_type = random.choice(EVENT_TYPES)
        entity_id = random.randint(1, N_TICKETS)
        event_time = rand_time()

        w.writerow([i, event_type, entity_id, event_time])