#! /bin/bash

DB_ENDPOINT="localhost"
DB_USERNAME="runningdinner_admin"
DB_NAME="runningdinner"

# TIMESTAMP=$(date +%s)

pg_dump --data-only --exclude-table runningdinner.shedlock --exclude-table runningdinner.flyway_schema_history --exclude-table public.schema_version \
        -h $DB_ENDPOINT -p 54321 -U $DB_USERNAME -d $DB_NAME -Fc -f dump.dump

