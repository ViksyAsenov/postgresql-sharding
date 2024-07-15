require("dotenv").config();
const { Client } = require("pg");

const createDbConfig = (port) => ({
  user: "postgres",
  host: "localhost",
  database: "sharding_is_cool",
  password: process.env.POSTGRES_PASSWORD,
  port,
});

const mainClient = new Client(createDbConfig(process.env.MAIN_DB_PORT));
const shardClients = [
  new Client(createDbConfig(process.env.SHARD1_PORT)),
  new Client(createDbConfig(process.env.SHARD2_PORT)),
  new Client(createDbConfig(process.env.SHARD3_PORT)),
];

const insertUser = async (client, name, age) => {
  const insertQuery = "INSERT INTO users (name, age) VALUES ($1, $2)";
  await client.query(insertQuery, [name, age]);
};

const queryUsersFromShard = async (client) => {
  const query = "SELECT name, age FROM users";
  const res = await client.query(query);
  return res.rows;
};

const clearUsersTable = async (client) => {
  const deleteQuery = "DELETE FROM users";
  await client.query(deleteQuery);
};

describe("Database Integration Tests", () => {
  beforeAll(async () => {
    await mainClient.connect();
    await Promise.all(shardClients.map((client) => client.connect()));
    await clearUsersTable(mainClient);
  });

  afterAll(async () => {
    await mainClient.end();
    await Promise.all(shardClients.map((client) => client.end()));
  });

  test("Insert data into main database and verify data in shards", async () => {
    const users = [
      { name: "Alice", age: 25 },
      { name: "Bob", age: 35 },
      { name: "Charlie", age: 65 },
    ];

    // Insert users into the main database
    await Promise.all(
      users.map((user) => insertUser(mainClient, user.name, user.age))
    );

    const expectedShardData = [
      [{ name: "Alice", age: 25 }], // Shard 1 (age 0-30)
      [{ name: "Bob", age: 35 }], // Shard 2 (age 30-60)
      [{ name: "Charlie", age: 65 }], // Shard 3 (age 60-123)
    ];

    // Check that each shard has the correct users
    for (let i = 0; i < shardClients.length; i++) {
      const shardData = await queryUsersFromShard(shardClients[i]);
      expect(shardData).toEqual(expectedShardData[i]);
    }
  });
});
