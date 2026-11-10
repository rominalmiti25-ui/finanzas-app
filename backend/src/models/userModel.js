const { pool } = require('../config/db');
const { userRowSchema, userRowWithHashSchema, filterValid } = require('./schemas');

const COLS = 'id, name, email, role, age, monthly_income, monthly_budget, created_at';

const UserModel = {
  // Incluye hash (solo para login). Devuelve null si no existe o el registro es inválido.
  async findByEmailWithHash(email) {
    const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (!rows.length) return null;
    const p = userRowWithHashSchema.safeParse(rows[0]);
    return p.success ? p.data : null;
  },
  async emailExists(email) {
    const [rows] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    return rows.length > 0;
  },
  // Consulta individual: registro inválido => { invalid: true } (error controlado en el controlador)
  async findById(id) {
    const [rows] = await pool.execute(`SELECT ${COLS} FROM users WHERE id = ?`, [id]);
    if (!rows.length) return null;
    const p = userRowSchema.safeParse(rows[0]);
    return p.success ? p.data : { invalid: true };
  },
  async create({ name, email, passwordHash, age, monthly_income, monthly_budget }) {
    // el rol NUNCA viene del cliente: siempre 'cliente'
    const [r] = await pool.execute(
      "INSERT INTO users (name, email, password_hash, role, age, monthly_income, monthly_budget) VALUES (?,?,?,'cliente',?,?,?)",
      [name, email, passwordHash, age, monthly_income, monthly_budget]);
    return r.insertId;
  },
  async listValid() {
    const [rows] = await pool.query(`SELECT ${COLS} FROM users ORDER BY id`);
    return filterValid(rows, userRowSchema, 'usuario');
  },
  async promote(id) {
    const [r] = await pool.execute("UPDATE users SET role = 'admin' WHERE id = ?", [id]);
    return r.affectedRows;
  },
};
module.exports = UserModel;
