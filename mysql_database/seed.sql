-- Seed data for Event Booking System
USE myapp;

-- Clear existing data (respecting FK constraints)
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE bookings;
TRUNCATE TABLE events;
SET FOREIGN_KEY_CHECKS=1;

-- Insert events (5+)
INSERT INTO events (title, description, start_time, end_time, venue, capacity, price)
VALUES
('Tech Conference 2025', 'A full-day conference on emerging technologies.', '2025-10-10 09:00:00', '2025-10-10 18:00:00', 'Convention Center Hall A', 250, 199.00),
('Music Fest Night', 'Live performances by top artists.', '2025-09-25 18:00:00', '2025-09-25 23:30:00', 'Open Air Arena', 500, 79.99),
('Startup Pitch Day', 'Pitch sessions and networking for startups and investors.', '2025-11-05 10:00:00', '2025-11-05 16:00:00', 'Innovation Hub', 120, 49.00),
('Art Workshop: Watercolors', 'Hands-on watercolor techniques with a pro artist.', '2025-09-20 13:00:00', '2025-09-20 16:00:00', 'Studio 12', 30, 25.00),
('Culinary Masterclass', 'Learn gourmet cooking with a celebrity chef.', '2025-10-02 11:00:00', '2025-10-02 14:00:00', 'Culinary School Kitchen', 20, 99.50),
('Community Charity Run', '5K charity run for local causes.', '2025-09-28 07:00:00', '2025-09-28 10:00:00', 'City Park', 800, 0.00);

-- Example confirmed booking
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES
((SELECT id FROM events WHERE title = 'Tech Conference 2025' LIMIT 1), 'Alice Johnson', 'alice@example.com', 2, 'confirmed');

-- Example pending booking (should not affect capacity trigger)
INSERT INTO bookings (event_id, user_name, user_email, seats_booked, status)
VALUES
((SELECT id FROM events WHERE title = 'Music Fest Night' LIMIT 1), 'Bob Smith', 'bob@example.com', 4, 'pending');
