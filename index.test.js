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

const insertUser = async (client, name, email, age, role) => {
  const insertQuery =
    "INSERT INTO users (name, email, age, role) VALUES ($1, $2, $3, $4)";

  await client.query(insertQuery, [name, email, age, role]);
};

const insertProduct = async (client, name, price, type) => {
  const insertQuery =
    "INSERT INTO products (name, price, type) VALUES ($1, $2, $3)";

  await client.query(insertQuery, [name, price, type]);
};

const queryUsersFromShard = async (client) => {
  const query = "SELECT name, email, age, role FROM users";
  const res = await client.query(query);

  return res.rows;
};

const queryProductsWithRole = async (client, role) => {
  await client.query(`SET ROLE ${role}`);

  const query = "SELECT name, price, type FROM products";
  const res = await client.query(query);

  await client.query("RESET ROLE");

  return res.rows;
};

const clearTable = async (client, tableName) => {
  const deleteQuery = `DELETE FROM ${tableName}`;

  await client.query(deleteQuery);
};

describe("Database Integration Tests", () => {
  beforeAll(async () => {
    await mainClient.connect();
    await Promise.all(shardClients.map((client) => client.connect()));

    await clearTable(mainClient, "users");
    await clearTable(mainClient, "products");
  });

  afterAll(async () => {
    await mainClient.end();
    await Promise.all(shardClients.map((client) => client.end()));
  });

  test("Insert users into main database and verify data in shards", async () => {
    const users = [
      { name: "Alice", email: "alice123@gmail.com", age: 25, role: "normal" },
      { name: "Bob", email: "bobster@gmail.com", age: 35, role: "premium" },
      {
        name: "Charlie",
        email: "unclecharlie@gmail.com",
        age: 65,
        role: "super",
      },
    ];

    await Promise.all(
      users.map((user) =>
        insertUser(mainClient, user.name, user.email, user.age, user.role)
      )
    );

    const expectedUsersShardData = [
      [{ ...users[0] }], // Shard 1 (age 0-30)
      [{ ...users[1] }], // Shard 2 (age 30-60)
      [{ ...users[2] }], // Shard 3 (age 60-123)
    ];

    // Check that each shard has the correct users and products
    for (let i = 0; i < shardClients.length; i++) {
      const userShardData = await queryUsersFromShard(shardClients[i]);
      expect(userShardData).toEqual(expectedUsersShardData[i]);
    }
  });

  test("Insert products into main database and verify visibility based on role", async () => {
    const products = [
      { name: "Towel", price: 5.55, type: "normal" },
      { name: "PC", price: 2436.98, type: "premium" },
      { name: "Porsche 911 Turbo S", price: 267034.99, type: "super" },
    ];

    await Promise.all(
      products.map((product) =>
        insertProduct(mainClient, product.name, product.price, product.type)
      )
    );

    const expectedRoleAccessData = {
      normal: products.slice(0, 1), // Only 'normal' products
      premium: products.slice(0, 2), // 'normal' and 'premium' products
      super: products, // All products
    };

    // Check that each access role only shows the correct products
    for (const role of Object.keys(expectedRoleAccessData)) {
      const productsForRole = await queryProductsWithRole(mainClient, role);
      expect(productsForRole).toEqual(expectedRoleAccessData[role]);
    }
  });
});
