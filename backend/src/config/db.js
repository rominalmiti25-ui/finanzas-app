require('dotenv').config();
const mysql = require('mysql2/promise');

const baseConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'finanzas_db',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
};

const pool = mysql.createPool({
  ...baseConfig,
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true, // DECIMAL -> number
  dateStrings: true,    // DATE -> 'YYYY-MM-DD'
});

module.exports = { pool, baseConfig };
