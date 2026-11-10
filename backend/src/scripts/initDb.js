const fs = require('fs'); const path = require('path'); const mysql = require('mysql2/promise');
const { baseConfig } = require('../config/db');

(async () => {
  const sql = fs.readFileSync(path.join(__dirname, '../../sql/schema.sql'), 'utf8');
  let conn;
  try { conn = await mysql.createConnection({ ...baseConfig, multipleStatements: true }); }
  catch (e) {
    if (e.code !== 'ER_BAD_DB_ERROR') throw e;
    const { database, ...noDb } = baseConfig;
    const tmp = await mysql.createConnection(noDb);
    await tmp.query(`CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4`); await tmp.end();
    conn = await mysql.createConnection({ ...baseConfig, multipleStatements: true });
  }
  await conn.query(sql); await conn.end();
  console.log('Tablas creadas correctamente.');
})().catch((e) => { console.error(e); process.exit(1); });
