// Inicialización documentada del PRIMER administrador (mismas reglas de hash que el resto: Argon2id).
// Uso: configurar ADMIN_NAME / ADMIN_EMAIL / ADMIN_PASSWORD en .env y ejecutar `npm run init-admin`.
require('dotenv').config();
const argon2 = require('argon2');
const { pool } = require('../config/db');
const { registerSchema } = require('../models/schemas');

(async () => {
  const data = registerSchema.parse({
    name: process.env.ADMIN_NAME || 'Administrador Principal', email: process.env.ADMIN_EMAIL, password: process.env.ADMIN_PASSWORD,
    age: 30, monthly_income: 0, monthly_budget: 0,
  });
  const [ex] = await pool.execute('SELECT id FROM users WHERE email = ?', [data.email]);
  if (ex.length) { console.log('El administrador ya existe:', data.email); return pool.end(); }
  const hash = await argon2.hash(data.password, { type: argon2.argon2id });
  await pool.execute("INSERT INTO users (name,email,password_hash,role,age,monthly_income,monthly_budget) VALUES (?,?,?,'admin',?,0,0)", [data.name, data.email, hash, data.age]);
  console.log('Administrador creado:', data.email);
  await pool.end();
})().catch((e) => { console.error(e.issues ? JSON.stringify(e.issues, null, 2) : e); process.exit(1); });
