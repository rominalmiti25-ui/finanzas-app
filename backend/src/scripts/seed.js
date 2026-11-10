// Datos de prueba: 1 admin, 1 cliente "demo" y 40 clientes con ~7 meses de movimientos.
// Uso: npm run seed            (falla si ya hay usuarios)
//      npm run seed -- --reset (borra todo y vuelve a crear)
const argon2 = require('argon2');
const { pool } = require('../config/db');
const { generateDemo } = require('./demoData');
const MlService = require('../services/mlService');

(async () => {
  const reset = process.argv.includes('--reset');
  const [[{ n }]] = await pool.query('SELECT COUNT(*) AS n FROM users');
  if (n > 0 && !reset) { console.log('Ya hay usuarios. Usa --reset para recrear los datos.'); return pool.end(); }
  if (reset) { await pool.query('DELETE FROM transactions'); await pool.query('DELETE FROM users'); await pool.query('DELETE FROM ml_models'); }

  const H = (p) => argon2.hash(p, { type: argon2.argon2id });
  const adminHash = await H('Admin1234'), clientHash = await H('Cliente1234'), demoHash = await H('Demo12345');

  await pool.execute("INSERT INTO users (name,email,password_hash,role,age,monthly_income,monthly_budget) VALUES ('Administrador Demo','admin@demo.com',?,'admin',35,0,0)", [adminHash]);

  const { users, transactions } = generateDemo({ nUsers: 41 });
  // el primer usuario generado es el cliente de prueba "cliente@demo.com"
  users[0].email = 'cliente@demo.com'; users[0].name = 'Cliente Demo';
  const ids = [];
  for (let i = 0; i < users.length; i++) {
    const u = users[i];
    const [r] = await pool.execute("INSERT INTO users (name,email,password_hash,role,age,monthly_income,monthly_budget) VALUES (?,?,?,'cliente',?,?,?)",
      [u.name, u.email, i === 0 ? clientHash : demoHash, u.age, u.monthly_income, u.monthly_budget]);
    ids.push(r.insertId);
  }
  const rows = transactions.map((t) => [ids[t.userIdx], t.type, t.amount, t.category, t.description, t.tx_date]);
  for (let i = 0; i < rows.length; i += 500) {
    await pool.query('INSERT INTO transactions (user_id,type,amount,category,description,tx_date) VALUES ?', [rows.slice(i, i + 500)]);
  }
  console.log(`Creados ${users.length + 1} usuarios y ${rows.length} transacciones.`);
  console.log('Entrenando modelos de ML...');
  console.log(JSON.stringify(await MlService.trainAll(), null, 2));
  console.log('\nCuentas de prueba:\n  admin@demo.com   / Admin1234\n  cliente@demo.com / Cliente1234\n  usuario02@demo.com ... usuario41@demo.com / Demo12345');
  await pool.end();
})().catch((e) => { console.error(e); process.exit(1); });
