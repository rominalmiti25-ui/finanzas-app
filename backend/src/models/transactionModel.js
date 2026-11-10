const { pool } = require('../config/db');
const { transactionRowSchema, filterValid } = require('./schemas');

const COLS = 'id, user_id, type, amount, category, description, tx_date';

const TransactionModel = {
  async create(userId, t) {
    const [r] = await pool.execute(
      'INSERT INTO transactions (user_id, type, amount, category, description, tx_date) VALUES (?,?,?,?,?,?)',
      [userId, t.type, t.amount, t.category, t.description, t.tx_date]);
    return r.insertId;
  },
  async getRaw(id) {
    const [rows] = await pool.execute(`SELECT ${COLS} FROM transactions WHERE id = ?`, [id]);
    return rows[0] || null;
  },
  async update(id, userId, t) {
    const [r] = await pool.execute(
      'UPDATE transactions SET type=?, amount=?, category=?, description=?, tx_date=? WHERE id=? AND user_id=?',
      [t.type, t.amount, t.category, t.description, t.tx_date, id, userId]);
    return r.affectedRows;
  },
  async remove(id, userId) {
    const [r] = await pool.execute('DELETE FROM transactions WHERE id=? AND user_id=?', [id, userId]);
    return r.affectedRows;
  },
  // Lista del propio usuario (solo registros válidos)
  async listByUser(userId, { limit, offset, type, month }) {
    const where = ['user_id = ?']; const params = [userId];
    if (type) { where.push('type = ?'); params.push(type); }
    if (month) { where.push("DATE_FORMAT(tx_date, '%Y-%m') = ?"); params.push(month); }
    const [rows] = await pool.query(
      `SELECT ${COLS} FROM transactions WHERE ${where.join(' AND ')} ORDER BY tx_date DESC, id DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]);
    return filterValid(rows, transactionRowSchema, 'transacción').valid;
  },
  async allByUserValid(userId) {
    const [rows] = await pool.execute(`SELECT ${COLS} FROM transactions WHERE user_id = ?`, [userId]);
    return filterValid(rows, transactionRowSchema, 'transacción').valid;
  },
  async allValid() {
    const [rows] = await pool.query(`SELECT ${COLS} FROM transactions`);
    return filterValid(rows, transactionRowSchema, 'transacción');
  },
};
module.exports = TransactionModel;
