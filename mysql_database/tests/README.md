# MySQL Schema + Seed + Startup Validation Tests

This folder contains a CLI‑driven SQL test suite to validate the Event Booking System database setup. It verifies:
- Required tables (`events`, `bookings`) exist
- Essential columns and integrity constraints (FK, CHECKs) are present
- Capacity enforcement triggers exist and prevent overbooking
- Seed data has been applied (6 events and example bookings)
- The database is initialized and accessible as configured by `startup.sh`

## Prerequisites

- You must run `startup.sh` first to initialize MySQL, apply schema, and seed data when needed.
- After a successful run, a connection helper is written to `../db_connection.txt`.

Example connection (default from startup.sh):
```
mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp
```

## How to Run

From the `mysql_database` directory:

1) Ensure the database is running and initialized:
```
bash startup.sh
```

2) Execute the test suite:
```
mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp < tests/schema_validation.sql
```

Alternatively:
```
$(cat db_connection.txt) < tests/schema_validation.sql
```

## What to Expect

- The script prints PASS/FAIL markers as SQL result sets and includes details.
- Some statements intentionally attempt invalid inserts to verify constraints and triggers. You should see MySQL errors indicating enforcement (expected and desired):

Examples you may see:
- Check constraint violation (negative capacity or zero seats)
- Custom trigger error:
  - ERROR 1644 (45000): Booking exceeds event capacity.
  - ERROR 1644 (45000): Updated booking exceeds event capacity.
  - ERROR 1644 (45000): Invalid event_id for booking.

These errors do not stop the entire script; the mysql CLI continues with subsequent statements.

## Tests Overview

- TEST 1: Tables existence (`events`, `bookings`)
- TEST 2: Events table essential columns present
- TEST 3: Bookings table essential columns present
- TEST 4: Foreign key `bookings(event_id)` → `events(id)`
- TEST 5: Capacity enforcement triggers present
- TEST 6: CHECK constraints presence (capacity ≥ 0, seats_booked > 0, end_time > start_time)
- TEST 7: Constraint enforcement trials (negative capacity event, zero seats booking, overbooking)
- TEST 8: Seed data checks (6 known events; at least one confirmed and one pending booking)
- TEST 9: Connectivity check via SHOW TABLES (proves appuser access and schema applied)
- TEST 10: Presence of view `v_event_capacity` (optional)

## Interpreting Results

- For existence/metadata checks you will see a row with RESULT = PASS or FAIL.
- For enforcement checks:
  - Insert attempts that should fail will produce error messages (this is the “PASS” condition for enforcement).
  - The script also verifies state afterward (e.g., confirmed seats for tiny capacity event remains within capacity).

If you observe FAIL markers:
- Re-run `startup.sh`
- Confirm schema applied:
  ```
  mysql -u root -pdbuser123 -h localhost -P 5001 < schema.sql
  ```
- Confirm seed applied (only when events is empty):
  ```
  mysql -u appuser -pdbuser123 -h localhost -P 5001 -D myapp < seed.sql
  ```

## CI Integration

In CI, run:
```
bash event-booking-system-37142-37151/mysql_database/startup.sh
mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp < event-booking-system-37142-37151/mysql_database/tests/schema_validation.sql
```

Then parse the outputs for PASS/FAIL and examine any ERROR lines that correspond to expected enforcement.
