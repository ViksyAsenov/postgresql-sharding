#!/bin/bash

# This file is the bash version of ./main_db_init.sql .
# It executes the exact same SQL code. The only difference is that we can use environment variables, such as the database's password.

declare -A SHARDS
SHARDS=([1]="young-0-30" [2]="middle-30-60" [3]="senior-60-123")

psql -U postgres <<-END
  CREATE DATABASE sharding_is_cool;

  \c sharding_is_cool

  CREATE EXTENSION IF NOT EXISTS postgres_fdw;

  CREATE TABLE users (
    id SERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    age INT
  ) PARTITION BY RANGE (age);

  $(for (( CURRENT_SHARD=1; CURRENT_SHARD<=3; CURRENT_SHARD++ ))
  do
    # Connect to the server
    echo "CREATE SERVER shard${CURRENT_SHARD} FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard${CURRENT_SHARD}_db', dbname 'sharding_is_cool', port '5432');"

    # Map a user so we can access the table
    echo "CREATE USER MAPPING FOR postgres SERVER shard${CURRENT_SHARD} OPTIONS (user 'postgres', password '${POSTGRES_PASSWORD}');"

    # Map the table for the given range to the respective category
    CATEGORY_MAP="${SHARDS[$CURRENT_SHARD]}"
    IFS='-' read -r CATEGORY START END <<< ${CATEGORY_MAP}
    echo "CREATE FOREIGN TABLE users_${CATEGORY} PARTITION OF users FOR VALUES FROM (${START}) to (${END}) SERVER shard${CURRENT_SHARD} OPTIONS (table_name 'users');"
  done)
END
