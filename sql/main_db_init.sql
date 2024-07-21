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

CREATE SERVER shard1 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard1_db', dbname 'sharding_is_cool', port '5432');
CREATE SERVER shard2 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard2_db', dbname 'sharding_is_cool', port '5432');
CREATE SERVER shard3 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'shard3_db', dbname 'sharding_is_cool', port '5432');

CREATE USER MAPPING FOR postgres SERVER shard1 OPTIONS (user 'postgres', password 'password');
CREATE USER MAPPING FOR postgres SERVER shard2 OPTIONS (user 'postgres', password 'password');
CREATE USER MAPPING FOR postgres SERVER shard3 OPTIONS (user 'postgres', password 'password');

CREATE FOREIGN TABLE users_young PARTITION OF users FOR VALUES FROM (0) to (30) SERVER shard1 OPTIONS (table_name 'users');
CREATE FOREIGN TABLE users_middle PARTITION OF users FOR VALUES FROM (30) to (60) SERVER shard2 OPTIONS (table_name 'users');
CREATE FOREIGN TABLE users_senior PARTITION OF users FOR VALUES FROM (60) to (123) SERVER shard3 OPTIONS (table_name 'users');

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