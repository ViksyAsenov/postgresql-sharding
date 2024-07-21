#!/bin/bash

# This file is the bash version of ./main_db_init.sql .
# It executes the exact same SQL code. The only difference is that we can use environment variables, such as the database's password.

declare -A SHARDS
SHARDS=([1]="young-0-30" [2]="middle-30-60" [3]="senior-60-123")

psql -U postgres <<-END
  CREATE DATABASE sharding_is_cool;

  \c sharding_is_cool

  CREATE TYPE access_level AS ENUM ('normal', 'premium', 'super');

  CREATE TABLE users (
    id SERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    age INT,
    role access_level DEFAULT 'normal'
  ) PARTITION BY RANGE (age);

  CREATE TABLE products (
    id SERIAL NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    type access_level DEFAULT 'normal'
  );

  CREATE EXTENSION IF NOT EXISTS postgres_fdw;

  $(for (( CURRENT_SHARD=1; CURRENT_SHARD<=3; CURRENT_SHARD++ ))
  do
    # Create a connection to the server
    echo "CREATE SERVER shard${CURRENT_SHARD} FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard${CURRENT_SHARD}_db', dbname 'sharding_is_cool', port '5432');"

    # Map a user so we can access the table
    echo "CREATE USER MAPPING FOR postgres SERVER shard${CURRENT_SHARD} OPTIONS (user 'postgres', password '${POSTGRES_PASSWORD}');"

    # Map the tables for to their respective shards based on the partition
    CATEGORY_MAP="${SHARDS[$CURRENT_SHARD]}"
    IFS='-' read -r USER_CATEGORY START END <<< ${CATEGORY_MAP}
    echo "CREATE FOREIGN TABLE users_${USER_CATEGORY} PARTITION OF users FOR VALUES FROM (${START}) to (${END}) SERVER shard${CURRENT_SHARD} OPTIONS (table_name 'users');"
  done)

  ALTER TABLE products ENABLE ROW LEVEL SECURITY;

  CREATE ROLE normal;
  CREATE ROLE premium;
  CREATE ROLE super;

  GRANT SELECT ON products TO normal;
  GRANT SELECT ON products TO premium;
  GRANT SELECT ON products TO super;

  CREATE POLICY normal_policy ON products
    FOR SELECT
    USING (type = 'normal' AND current_user = 'normal');

  CREATE POLICY premium_policy ON products
    FOR SELECT
    USING ((type = 'normal' OR type = 'premium') AND current_user = 'premium');

  CREATE POLICY super_policy ON products
    FOR SELECT
    USING ((type = 'normal' OR type = 'premium' OR type = 'super') AND current_user = 'super');
END
