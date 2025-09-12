-- Seed data for Event Booking System

-- Insert 5 sample events
INSERT INTO events (title, description, date_time, venue, total_seats, available_seats)
VALUES
('Tech Conference 2025', 'A full-day conference on emerging technologies.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 10 DAY), 'Convention Center Hall A', 200, 200);

INSERT INTO events (title, description, date_time, venue, total_seats, available_seats)
VALUES
('Music Festival Night', 'An evening of live performances by top artists.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 15 DAY), 'Open Air Arena', 500, 500);

INSERT INTO events (title, description, date_time, venue, total_seats, available_seats)
VALUES
('Art & Wine Exhibition', 'Explore fine arts with exquisite wine tasting.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 20 DAY), 'Gallery 21', 100, 100);

INSERT INTO events (title, description, date_time, venue, total_seats, available_seats)
VALUES
('Startup Pitch Day', 'Startups pitch to investors and mentors.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 7 DAY), 'Innovation Hub', 150, 150);

INSERT INTO events (title, description, date_time, venue, total_seats, available_seats)
VALUES
('Yoga Wellness Retreat', 'Mindfulness and yoga sessions for all levels.', DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 DAY), 'Seaside Resort', 80, 80);

-- Example bookings and seat updates
-- Book 3 seats for event 1
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (1, 'Alice Johnson', 'alice@example.com', 3, 'CONFIRMED');

-- Decrease available seats for event 1 by 3
UPDATE events SET available_seats = available_seats - 3 WHERE id = 1;

-- Book 2 seats for event 2 and cancel 1
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (2, 'Bob Smith', 'bob@example.com', 2, 'CONFIRMED');

UPDATE events SET available_seats = available_seats - 2 WHERE id = 2;

INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES (2, 'Charlie Doe', 'charlie@example.com', 1, 'CANCELLED');

-- For cancelled bookings, do not alter seat counts here (business rule: only confirmed bookings reduce availability)
