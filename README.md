# PostgreSQL Sharding and RLS

This project demonstrates PostgreSQL only sharding and RLS. Docker is used for containerization and JavaScript for testing the implementation.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [Environment Configuration](#environment-configuration)
  - [Docker Setup](#docker-setup)
- [Sharding Logic](#sharding-logic)
- [RLS Logic](#rls-logic)
- [Testing](#testing)

## Introduction

Sharding is a database architecture pattern related to horizontal partitioning — the practice of separating one table's rows into multiple tables, known as shards, which can be distributed across multiple databases. RLS (Row-Level Security) allows you to control access to individual rows in a table based on certain criteria. This feature is particularly useful for multi-tenant applications where different users or groups of users should have access to different subsets of the data within the same table.

## Prerequisites

- Docker Compose
- Node.js

## Setup

### Environment Configuration

1 . Create a `.env` file in the root directory of the project with the following content:

    POSTGRES_PASSWORD=password-for-the-postgresql-instances
    MAIN_DB_PORT=port-to-map-the-main-db
    SHARD1_PORT=port-to-map-shard1
    SHARD2_PORT=port-to-map-shard2
    SHARD3_PORT=port-to-map-shard3

### Docker Setup

1 . Clone the repository:

    git clone https://github.com/ViksyAsenov/postgresql-sharding-and-rls
    cd postgresql-sharding-and-rls

2 . Build and start the Docker containers:

    docker compose --env-file .env -f docker-compose.yaml up -d

## Sharding Logic

The sharding logic is to separate the users based on their age:

- Users from 0-30 are put in the first shard
- Users from 30-60 are put in the second shard
- Users from 60-123 are put in the third shard

## RLS Logic

The RLS logic is to separate the visibility of each product based on the user's access:

- Users with 'normal' access only see the normal products
- Users with 'premium' access see both normal and premium products
- Users with 'super' access see all products

## Testing

A simple JavaScript test script is provided to verify the sharding implementation.

1 . Install dependencies:

    npm install

2 . Run the test script:

    npm test
