#! /bin/bash

DB_ENDPOINT="localhost"
DB_USERNAME="runningdinner_admin"
DB_NAME="runningdinner"

pg_restore -h $DB_ENDPOINT -p 54321 -U $DB_USERNAME -d $DB_NAME backup.dump