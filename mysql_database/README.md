# MySQL Database: Event Booking System

This folder contains the MySQL schema, seed data, and a startup script for the Event Booking System.

Contents:
- schema.sql — Creates `events` and `bookings` tables with constraints and indexes.
- seed.sql — Inserts 5 sample events and sample bookings, updating available seats accordingly.
- startup.sh — Reads `db_connection.txt` and executes SQL one statement at a time.
- db_connection.txt — Provide the MySQL CLI connection (not committed in production). A placeholder may exist.

Schema highlights:
- events:
  - id (PK, AUTO_INCREMENT)
  - title (VARCHAR, required)
  - description (TEXT)
  - date_time (DATETIME, required)
  - venue (VARCHAR, required)
  - total_seats (INT, >=0)
  - available_seats (INT, >=0 and <= total_seats)
  - created_at, updated_at with CURRENT_TIMESTAMP
- bookings:
  - id (PK, AUTO_INCREMENT)
  - event_id (FK -> events.id, ON DELETE CASCADE)
  - user_name, user_email (VARCHAR, required)
  - seats_booked (INT, >0)
  - status ENUM('CONFIRMED','CANCELLED')
  - created_at with CURRENT_TIMESTAMP

How to run:
1) Set db_connection.txt with your MySQL CLI command:
   mysql -u<user> -p<password> <database>

2) Execute startup.sh:
   chmod +x startup.sh
   ./startup.sh

Notes:
- Each SQL statement is executed individually (`-e` per statement) as required.
- Ensure the target database exists and credentials are valid before running.
- For cancelled bookings, available seats are not restored in this seed (business rule can be adjusted as needed).

Environment variables:
- Do not hardcode credentials in code. Use an orchestrated `.env` or external secrets. `db_connection.txt` is used solely for local CLI execution by this script.
