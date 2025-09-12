# MySQL Database Container

## Introduction

This container provides a MySQL database for the Event Booking System. It hosts the `events` and `bookings` tables and includes triggers to enforce capacity constraints. The setup script initializes the server, creates users, applies the schema, and optionally seeds example data. The database listens on port 5001.

## Prerequisites

- MySQL server binaries installed and accessible (mysqld, mysql, mysqladmin)
- Bash shell
- sudo privileges (startup.sh uses sudo to manage the local MySQL daemon)
- Ports: 5001 must be available locally

## Quick Start

1. Start the database and apply schema/seed:
   - From the container root:
     - event-booking-system-37142-37151/mysql_database
   - Run:
     - bash startup.sh

2. Verify connectivity:
   - The script writes a helper command to db_connection.txt.
   - Example:
     - mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp

3. Optional: seed data is applied automatically if tables are empty.

## Ports and Connection

- Port: 5001
- Database: myapp
- Users:
  - root / dbuser123 (localhost via socket and TCP)
  - appuser / dbuser123 (remote/TCP)
- Example:
  - mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp

## Environment Variables

The startup script exports values to a helper file for tools:

- Generated at: db_visualizer/mysql.env
- Contains:
  - MYSQL_URL="mysql://localhost:5001/myapp"
  - MYSQL_USER="appuser"
  - MYSQL_PASSWORD="dbuser123"
  - MYSQL_DB="myapp"
  - MYSQL_PORT="5001"

You can source this file for tools that read env vars:
- source db_visualizer/mysql.env

## Schema and Seed

- Schema file: schema.sql
  - Creates tables: events, bookings
  - Adds checks and two triggers to prevent overbooking on insert and update
- Seed file: seed.sql
  - Clears tables then inserts 5+ events and two example bookings (one confirmed, one pending)

The startup script applies schema and then conditionally seeds (only if events table exists and is empty).

## Scripts

- startup.sh
  - Initializes and launches mysqld on port 5001
  - Sets root password and creates appuser
  - Creates database myapp
  - Applies schema.sql and conditionally seed.sql
  - Writes db_connection.txt and db_visualizer/mysql.env
- backup_db.sh
  - Attempts to detect running DB and dump to database_backup.sql (for MySQL/Postgres) or other formats
- restore_db.sh
  - Detects a compatible backup file and restores into the currently running DB

## Step-by-Step Setup

1. Ensure no conflicting MySQL instance is running on port 5001.
2. From mysql_database directory, run:
   - bash startup.sh
3. Wait until "MySQL is ready!" and "MySQL setup complete!" messages appear.
4. Confirm schema:
   - mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp -e "SHOW TABLES;"
5. Optionally view seed data:
   - mysql -u appuser -pdbuser123 -h localhost -P 5001 myapp -e "SELECT COUNT(*) FROM events;"

## .env Usage

This container does not require a .env file. Configuration is set in startup.sh and exported to db_visualizer/mysql.env for convenience. Downstream services (backend) should configure DB connection via environment variables (see backend README).

## Troubleshooting

- Port already in use:
  - Another MySQL instance might be running. Stop it or change the configured port in startup.sh (DB_PORT).
- Auth failures:
  - Ensure you use the generated credentials: appuser/dbuser123, database myapp, port 5001.
  - Try connecting with root: mysql -u root -pdbuser123 -h localhost -P 5001 myapp
- Schema not applied:
  - Re-run: mysql -h localhost -P 5001 -u root -pdbuser123 < schema.sql
- Seed not applied:
  - Ensure events table exists and is empty, then run:
    - mysql -h localhost -P 5001 -u appuser -pdbuser123 -D myapp < seed.sql
- mysqld startup issues:
  - The script initializes MySQL data dir if missing. If init fails, confirm permissions for /var/lib/mysql and the mysql user.
- Changing port or database name:
  - Edit DB_PORT/DB_NAME in startup.sh and re-run. Update any dependent services’ environment variables accordingly.

## Development Tips

- A lightweight DB viewer is included in db_visualizer/ (Node-based). Use the generated mysql.env with it.
- When altering schema, update schema.sql and re-apply. For destructive changes, consider backup_db.sh first.

## References

- startup.sh
- schema.sql
- seed.sql
- db_connection.txt
- db_visualizer/mysql.env
