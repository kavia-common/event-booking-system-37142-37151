#!/usr/bin/env bash
set -euo pipefail

# This script initializes the MySQL schema and seeds data for the Event Booking System.
# It reads the CLI connection command from db_connection.txt, and executes each SQL statement one at a time.

BASE_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"
CONN_FILE=\"$BASE_DIR/db_connection.txt\"
SCHEMA_FILE=\"$BASE_DIR/schema.sql\"
SEED_FILE=\"$BASE_DIR/seed.sql\"

if [[ ! -f \"$CONN_FILE\" ]]; then
  echo \"ERROR: db_connection.txt not found at $CONN_FILE\"
  echo \"Please create it with the MySQL CLI command, e.g.:\\n  mysql -u<user> -p<password> <database>\"
  exit 1
fi

MYSQL_CLI_CMD=\"$(cat \"$CONN_FILE\" | tr -d '\\r')\"

if [[ -z \"$MYSQL_CLI_CMD\" ]]; then
  echo \"ERROR: db_connection.txt is empty. Please provide a mysql CLI command.\"
  exit 1
fi

run_sql_file_one_statement_at_a_time() {
  local file_path=\"$1\"
  if [[ ! -f \"$file_path\" ]]; then
    echo \"WARN: SQL file not found: $file_path - skipping\"
    return 0
  fi

  echo \"Executing statements from: $file_path\"
  # Split on semicolons while preserving statement order. Ignore comments and empty lines.
  awk '
    BEGIN { RS=\";\" }
    { 
      gsub(/\\n[ \\t]*/, \"\\n\"); 
      stmt = $0
      # Remove single-line comments starting with -- and # at the beginning of lines
      gsub(/^\\s*--.*$/m, \"\", stmt);
      gsub(/^\\s*#.*$/m, \"\", stmt);
      # Trim spaces and newlines
      sub(/^\\s+/, \"\", stmt); sub(/\\s+$/, \"\", stmt);
      if (length(stmt) > 0) {
        print stmt
        print \";__END__\"
      }
    }
  ' \"$file_path\" | while IFS= read -r line; do
    if [[ \"$line\" == \";__END__\" ]]; then
      # Execute the accumulated statement
      if [[ -n \"${_stmt:-}\" ]]; then
        echo \"-> Running: ${_stmt:0:80}...\"
        # shellcheck disable=SC2086
        $MYSQL_CLI_CMD -e \"${_stmt}\"
        unset _stmt
      fi
    else
      _stmt=\"${_stmt:-}${line}\"
    fi
  done
}

# Execute schema then seed
run_sql_file_one_statement_at_a_time \"$SCHEMA_FILE\"
run_sql_file_one_statement_at_a_time \"$SEED_FILE\"

echo \"Database initialization complete.\"
