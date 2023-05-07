#! /bin/bash

DB_ENDPOINT="localhost"
DB_USERNAME="postgres"
DB_NAME="runningdinner"

pg_restore -h $DB_ENDPOINT -p 5432 -U $DB_USERNAME -d $DB_NAME dump.dump