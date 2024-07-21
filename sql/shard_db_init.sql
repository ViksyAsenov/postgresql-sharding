CREATE DATABASE sharding_is_cool;

\c sharding_is_cool

CREATE TYPE access_level AS ENUM ('normal', 'premium', 'super');

CREATE TABLE users (
  id SERIAL NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  age INT,
  role access_level DEFAULT 'normal'
);