#! /bin/bash

DB_ENDPOINT="localhost"
DB_USERNAME="runningdinner_admin"
DB_NAME="runningdinner"

pg_dump --data-only --exclude-table shedlock --exclude-table flyway_schema_history -h $DB_ENDPOINT -p 12345 -U $DB_USERNAME -d $DB_NAME -Fc -f backup.dump

