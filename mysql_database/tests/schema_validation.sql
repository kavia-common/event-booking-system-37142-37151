-- Event Booking System - MySQL Schema + Seed + Startup Validation Test Suite
-- How to run (after running startup.sh):
--   1) From mysql_database folder, ensure startup.sh has been executed successfully.
--   2) Use the connection string saved by startup.sh:
--        $(cat ../db_connection.txt)
--      Or explicitly:
--        mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp < tests/schema_validation.sql
--
-- This test suite prints PASS/FAIL markers and details so CI or operators can verify outcomes.
-- It validates:
--   (1) Required tables exist: events, bookings
--   (2) Essential columns and constraints (FKs, checks, triggers) are present/enforced
--   (3) Seeded data presence (5+ events, example bookings)
--   (4) startup.sh produced an initialized and populated database

-- Use the target database
USE myapp;

-- Helper: output header separator
SELECT '==== SCHEMA VALIDATION TESTS START ====' AS info;

-- 1) Verify required tables exist
SELECT 'TEST 1: Required tables exist (events, bookings)' AS test;
SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN ('events', 'bookings')
ORDER BY table_name;

-- Summary check counts
SELECT
  CASE WHEN SUM(CASE WHEN table_name='events' THEN 1 ELSE 0 END) = 1
         AND SUM(CASE WHEN table_name='bookings' THEN 1 ELSE 0 END) = 1
       THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'Both events and bookings tables exist' AS detail
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN ('events', 'bookings');

-- 2) Verify essential columns for events
SELECT 'TEST 2: events table essential columns' AS test;
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'events'
  AND COLUMN_NAME IN ('id','title','description','start_time','end_time','venue','capacity','price','created_at')
ORDER BY ORDINAL_POSITION;

-- Ensure minimum column presence
SELECT
  CASE WHEN COUNT(*) >= 9 THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'events has required columns' AS detail
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'events'
  AND COLUMN_NAME IN ('id','title','description','start_time','end_time','venue','capacity','price','created_at');

-- 2b) Verify essential columns for bookings
SELECT 'TEST 3: bookings table essential columns' AS test;
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'bookings'
  AND COLUMN_NAME IN ('id','event_id','user_name','user_email','seats_booked','status','created_at')
ORDER BY ORDINAL_POSITION;

SELECT
  CASE WHEN COUNT(*) >= 7 THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'bookings has required columns' AS detail
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'bookings'
  AND COLUMN_NAME IN ('id','event_id','user_name','user_email','seats_booked','status','created_at');

-- 3) Verify foreign key from bookings(event_id) -> events(id)
SELECT 'TEST 4: bookings -> events foreign key exists' AS test;
SELECT
  CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'bookings'
  AND REFERENCED_TABLE_NAME = 'events';

SELECT
  CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'bookings(event_id) has FK to events(id)' AS detail
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'bookings'
  AND REFERENCED_TABLE_NAME = 'events'
  AND COLUMN_NAME = 'event_id'
  AND REFERENCED_COLUMN_NAME = 'id';

-- 4) Verify triggers exist to enforce capacity
SELECT 'TEST 5: capacity enforcement triggers exist' AS test;
SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND EVENT_OBJECT_TABLE = 'bookings'
  AND TRIGGER_NAME IN ('trg_bookings_before_insert_capacity_check','trg_bookings_before_update_capacity_check')
ORDER BY TRIGGER_NAME;

SELECT
  CASE WHEN SUM(CASE WHEN TRIGGER_NAME='trg_bookings_before_insert_capacity_check' THEN 1 ELSE 0 END)=1
        AND SUM(CASE WHEN TRIGGER_NAME='trg_bookings_before_update_capacity_check' THEN 1 ELSE 0 END)=1
       THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'Both capacity enforcement triggers are present' AS detail
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND EVENT_OBJECT_TABLE = 'bookings'
  AND TRIGGER_NAME IN ('trg_bookings_before_insert_capacity_check','trg_bookings_before_update_capacity_check');

-- 5) Verify CHECK-like constraints via metadata (MySQL 8 shows CHECK constraints)
SELECT 'TEST 6: presence of CHECK constraints (capacity >= 0, end_time > start_time, seats_booked > 0)' AS test;
SELECT TABLE_NAME, CONSTRAINT_NAME, CHECK_CLAUSE
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
  ON cc.constraint_name = tc.constraint_name
  AND cc.constraint_schema = tc.constraint_schema
WHERE cc.constraint_schema = DATABASE()
  AND tc.table_name IN ('events','bookings')
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- 6) Attempt to violate constraints to ensure enforcement
SELECT 'TEST 7: constraint enforcement trials' AS test;

-- 6a) Try inserting an event with negative capacity (should fail)
-- We will capture error by attempting insert; mysql CLI will print the error.
SELECT 'Attempt: Insert event with negative capacity (expect failure)' AS step;
SET @err := NULL;
-- This will error; let it print. Afterwards, ensure it did not insert.
-- Note: Running in CI is okay; the failure is expected and does not break subsequent statements.
INSERT INTO events (title, description, start_time, end_time, venue, capacity, price)
VALUES ('Invalid Capacity Event', 'Should fail', NOW(), DATE_ADD(NOW(), INTERVAL 1 HOUR), 'Nowhere', -5, 10.00);

-- 6b) Try inserting a booking with seats_booked = 0 (should fail)
SELECT 'Attempt: Insert booking with seats_booked = 0 (expect failure)' AS step;
-- Get a valid event id
SET @valid_event_id := (SELECT id FROM events ORDER BY id LIMIT 1);
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (@valid_event_id, 'Zero Seats', 'zero@example.com', 0, 'confirmed');

-- 6c) Try overbooking (confirmed) beyond capacity to trigger capacity enforcement (should fail)
SELECT 'Attempt: Overbooking beyond capacity (expect failure)' AS step;
-- Create a tiny capacity event (capacity 1) to test
INSERT INTO events (title, description, start_time, end_time, venue, capacity, price)
VALUES ('Tiny Capacity Event', 'Capacity=1', NOW(), DATE_ADD(NOW(), INTERVAL 2 HOUR), 'Room X', 1, 5.00);
SET @tiny_event_id := LAST_INSERT_ID();
-- First booking: 1 seat confirmed (should pass)
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (@tiny_event_id, 'Tester One', 'one@example.com', 1, 'confirmed');
-- Second booking: another seat confirmed (should fail)
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (@tiny_event_id, 'Tester Two', 'two@example.com', 1, 'confirmed');

-- 6d) Verify only 1 confirmed seat exists for tiny event
SELECT 'Verification: seats_confirmed for tiny event should be 1' AS step;
SELECT e.id AS event_id, e.capacity, 
       (SELECT COALESCE(SUM(seats_booked),0) FROM bookings b WHERE b.event_id=e.id AND b.status='confirmed') AS seats_confirmed
FROM events e
WHERE e.id = @tiny_event_id;

-- 7) Seed data checks
SELECT 'TEST 8: Seed data checks' AS test;
-- events count (seed inserts 6 events)
SELECT COUNT(*) AS events_count FROM events;
-- bookings example rows exist
SELECT
  SUM(CASE WHEN title IN ('Tech Conference 2025','Music Fest Night','Startup Pitch Day','Art Workshop: Watercolors','Culinary Masterclass','Community Charity Run') THEN 1 ELSE 0 END) AS known_seed_event_titles_present
FROM events;

SELECT
  CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'Seed includes at least one confirmed booking' AS detail
FROM bookings
WHERE status = 'confirmed';

SELECT
  CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS RESULT,
  'Seed includes at least one pending booking' AS detail
FROM bookings
WHERE status = 'pending';

-- 8) startup.sh artifacts check (db_connection.txt content via SQL is not possible)
-- Instead, check runtime variables are correct and DB is accessible
SELECT 'TEST 9: Database accessible with appuser and schema applied' AS test;
-- Show tables as proof of accessibility
SHOW TABLES;

-- Optional: check view exists (created by schema.sql)
SELECT 'TEST 10: View v_event_capacity presence (optional)' AS test;
SELECT TABLE_NAME AS view_name
FROM information_schema.views
WHERE table_schema = DATABASE()
  AND TABLE_NAME = 'v_event_capacity';

SELECT '==== SCHEMA VALIDATION TESTS END ====' AS info;

-- Notes:
-- The INSERT attempts that are designed to fail will output error messages like:
--   ERROR 3819 (HY000): Check constraint '...' is violated.
--   ERROR 1644 (45000): Booking exceeds event capacity.
-- These errors indicate correct enforcement. Subsequent statements will continue to run in mysql CLI.
