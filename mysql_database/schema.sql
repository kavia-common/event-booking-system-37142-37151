-- Schema for Event Booking System (MySQL)
-- Database assumed to be created as ${DB_NAME} by startup.sh (default: myapp)
-- This script will: create tables, constraints, indexes, and triggers to enforce capacity

-- Use the target database (created in startup.sh)
USE myapp;

-- Safety: drop existing triggers to avoid duplicates
DROP TRIGGER IF EXISTS trg_bookings_before_insert_capacity_check;
DROP TRIGGER IF EXISTS trg_bookings_before_update_capacity_check;

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  venue VARCHAR(255) NOT NULL,
  capacity INT UNSIGNED NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CHECK (capacity >= 0),
  CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id BIGINT UNSIGNED NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  user_email VARCHAR(320) NOT NULL,
  seats_booked INT UNSIGNED NOT NULL,
  status ENUM('pending','confirmed','cancelled') NOT NULL DEFAULT 'confirmed',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_bookings_event_id (event_id),
  CONSTRAINT fk_bookings_event
    FOREIGN KEY (event_id) REFERENCES events(id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT,
  CHECK (seats_booked > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Helpful view for remaining seats (optional; if VIEW creation fails in some environments, it can be ignored)
DROP VIEW IF EXISTS v_event_capacity;
CREATE VIEW v_event_capacity AS
SELECT
  e.id AS event_id,
  e.title,
  e.capacity,
  COALESCE((
    SELECT SUM(b.seats_booked)
    FROM bookings b
    WHERE b.event_id = e.id AND b.status = 'confirmed'
  ), 0) AS seats_confirmed,
  GREATEST(e.capacity - COALESCE((
    SELECT SUM(b.seats_booked)
    FROM bookings b
    WHERE b.event_id = e.id AND b.status = 'confirmed'
  ), 0), 0) AS seats_remaining
FROM events e;

-- Trigger to enforce no overbooking on INSERT of bookings
DELIMITER $$
CREATE TRIGGER trg_bookings_before_insert_capacity_check
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
  DECLARE confirmed_sum INT UNSIGNED DEFAULT 0;
  DECLARE event_capacity INT UNSIGNED DEFAULT 0;

  -- Only enforce for confirmed bookings (pending can be allowed if business rules want; here we enforce for confirmed)
  IF NEW.status = 'confirmed' THEN
    SELECT capacity INTO event_capacity FROM events WHERE id = NEW.event_id FOR UPDATE;

    IF event_capacity IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid event_id for booking.';
    END IF;

    SELECT COALESCE(SUM(seats_booked), 0)
      INTO confirmed_sum
      FROM bookings
     WHERE event_id = NEW.event_id
       AND status = 'confirmed';

    IF confirmed_sum + NEW.seats_booked > event_capacity THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking exceeds event capacity.';
    END IF;
  END IF;
END$$
DELIMITER ;

-- Trigger to enforce no overbooking on UPDATE of bookings
DELIMITER $$
CREATE TRIGGER trg_bookings_before_update_capacity_check
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
  DECLARE confirmed_sum INT UNSIGNED DEFAULT 0;
  DECLARE event_capacity INT UNSIGNED DEFAULT 0;
  DECLARE eff_event_id BIGINT UNSIGNED;
  DECLARE delta INT;

  -- Determine event id after update
  SET eff_event_id = COALESCE(NEW.event_id, OLD.event_id);

  -- Only enforce when final status is confirmed
  IF NEW.status = 'confirmed' THEN
    SELECT capacity INTO event_capacity FROM events WHERE id = eff_event_id FOR UPDATE;

    IF event_capacity IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid event_id for booking update.';
    END IF;

    -- Sum of other confirmed bookings for the event (exclude current row)
    SELECT COALESCE(SUM(seats_booked), 0)
      INTO confirmed_sum
      FROM bookings
     WHERE event_id = eff_event_id
       AND status = 'confirmed'
       AND id <> OLD.id;

    SET delta = NEW.seats_booked;

    IF confirmed_sum + delta > event_capacity THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Updated booking exceeds event capacity.';
    END IF;
  END IF;
END$$
DELIMITER ;
