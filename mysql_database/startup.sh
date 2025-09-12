#!/usr/bin/env bash
set -euo pipefail

# This script initializes the MySQL schema and seeds data for the Event Booking System.
# It reads the CLI connection command from db_connection.txt, and executes each SQL statement one at a time.
# Enhancements:
# - Robust BASE_DIR detection even in non-interactive CI shells
# - Optional MYSQL_HOST and MYSQL_PORT overrides (for TCP connection)
# - Clearer connection diagnostics

# Resolve BASE_DIR robustly without relying on BASH_SOURCE in CI
if [[ -n "${BASH_SOURCE[0]+set}" ]]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
else
  SCRIPT_PATH="$0"
fi
BASE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"

CONN_FILE="$BASE_DIR/db_connection.txt"
SCHEMA_FILE="$BASE_DIR/schema.sql"
SEED_FILE="$BASE_DIR/seed.sql"

if [[ ! -f "$CONN_FILE" ]]; then
  echo "ERROR: db_connection.txt not found at $CONN_FILE"
  echo -e "Please create it with the MySQL CLI command, e.g.:\n  mysql -u<user> -p<password> <database>"
  exit 1
fi

MYSQL_CLI_CMD="$(tr -d '\r' < "$CONN_FILE")"

if [[ -z "$MYSQL_CLI_CMD" ]]; then
  echo "ERROR: db_connection.txt is empty. Please provide a mysql CLI command."
  exit 1
fi

# Allow overriding host/port via environment variables if needed
# Example:
#   MYSQL_HOST=127.0.0.1 MYSQL_PORT=5001 ./startup.sh
if [[ -n "${MYSQL_HOST:-}" ]]; then
  MYSQL_CLI_CMD="$MYSQL_CLI_CMD -h ${MYSQL_HOST}"
fi
if [[ -n "${MYSQL_PORT:-}" ]]; then
  MYSQL_CLI_CMD="$MYSQL_CLI_CMD -P ${MYSQL_PORT}"
fi

echo "Using MySQL CLI: ${MYSQL_CLI_CMD%% *} (host override: ${MYSQL_HOST:-default}, port override: ${MYSQL_PORT:-default})"

# Quick connectivity check (will fail fast if server not reachable)
if ! $MYSQL_CLI_CMD -e "SELECT 1;" >/dev/null 2>&1; then
  echo "ERROR: Unable to connect to MySQL with the provided command."
  echo "Tried: $MYSQL_CLI_CMD"
  echo "Tip: Ensure MySQL server/container is running and accessible."
  echo "     You can set MYSQL_HOST and MYSQL_PORT env vars for TCP connections."
  exit 1
fi

run_sql_file_one_statement_at_a_time() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    echo "WARN: SQL file not found: $file_path - skipping"
    return 0
  fi

  echo "Executing statements from: $file_path"
  # Split on semicolons while preserving statement order. Ignore comments and empty lines.
  awk '
    BEGIN { RS=";" }
    {
      gsub(/\n[ \t]*/, "\n");
      stmt = $0
      # Remove single-line comments starting with -- and # at the beginning of lines
      gsub(/^\s*--.*$/m, "", stmt);
      gsub(/^\s*#.*$/m, "", stmt);
      # Trim spaces and newlines
      sub(/^\s+/, "", stmt); sub(/\s+$/, "", stmt);
      if (length(stmt) > 0) {
        print stmt
        print ";__END__"
      }
    }
  ' "$file_path" | while IFS= read -r line; do
    if [[ "$line" == ";__END__" ]]; then
      # Execute the accumulated statement
      if [[ -n "${_stmt:-}" ]]; then
        echo "-> Running: ${_stmt:0:120}..."
        # shellcheck disable=SC2086
        $MYSQL_CLI_CMD -e "${_stmt}"
        unset _stmt
      fi
    else
      _stmt="${_stmt:-}${line}"
    fi
  done
}

# Execute schema then seed
run_sql_file_one_statement_at_a_time "$SCHEMA_FILE"
run_sql_file_one_statement_at_a_time "$SEED_FILE"

echo "Database initialization complete."
