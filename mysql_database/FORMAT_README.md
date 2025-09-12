# SQL Formatting Conventions

Until automated SQL formatting is added, please follow these conventions:

- Uppercase SQL keywords (SELECT, FROM, WHERE, JOIN, INSERT, UPDATE, DELETE, CREATE, ALTER).
- Use snake_case for table and column names.
- One column per line in CREATE TABLE statements.
- Align commas at the end of lines; avoid leading commas.
- Indent by 2 spaces for nested expressions and subqueries.
- Keep line length under 100 characters when possible.
- Add trailing commas for long column lists to ease future diffs.
- Always end statements with a semicolon.
