CREATE DATABASE sharding_is_cool;

\c sharding_is_cool

CREATE TABLE users (
  id SERIAL NOT NULL,
  name VARCHAR(255) NOT NULL,
  age INT
);