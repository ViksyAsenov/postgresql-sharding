CREATE DATABASE sharding_is_cool;

\c sharding_is_cool

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard1_db', dbname 'sharding_is_cool', port '5432');
CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard2_db', dbname 'sharding_is_cool', port '5432');
CREATE SERVER shard3 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard3_db', dbname 'sharding_is_cool', port '5432');

CREATE USER MAPPING FOR postgres SERVER shard1 OPTIONS (user 'postgres', password 'password');
CREATE USER MAPPING FOR postgres SERVER shard2 OPTIONS (user 'postgres', password 'password');
CREATE USER MAPPING FOR postgres SERVER shard3 OPTIONS (user 'postgres', password 'password');

CREATE TABLE users (
  id SERIAL NOT NULL,
  name VARCHAR(255) NOT NULL,
  age INT
) PARTITION BY RANGE (age);

CREATE FOREIGN TABLE users_young PARTITION OF users FOR VALUES FROM (0) to (30) SERVER shard1 OPTIONS (table_name 'users');
CREATE FOREIGN TABLE users_middle PARTITION OF users FOR VALUES FROM (30) to (60) SERVER shard2 OPTIONS (table_name 'users');
CREATE FOREIGN TABLE users_senior PARTITION OF users FOR VALUES FROM (60) to (123) SERVER shard3 OPTIONS (table_name 'users');

