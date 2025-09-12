-- Schema for Event Booking System

-- Use strict SQL mode to enforce checks
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  date_time DATETIME NOT NULL,
  venue VARCHAR(255) NOT NULL,
  total_seats INT NOT NULL,
  available_seats INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_events_total_seats CHECK (total_seats >= 0),
  CONSTRAINT chk_events_available_seats CHECK (available_seats >= 0),
  CONSTRAINT chk_events_avail_le_total CHECK (available_seats <= total_seats)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  event_id INT NOT NULL,
  user_name VARCHAR(255) NOT NULL,
  user_email VARCHAR(255) NOT NULL,
  seats_booked INT NOT NULL,
  status ENUM('CONFIRMED', 'CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bookings_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT chk_bookings_seats CHECK (seats_booked > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Helpful index for lookups
CREATE INDEX idx_bookings_event_id ON bookings(event_id);
