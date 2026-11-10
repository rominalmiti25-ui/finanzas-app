const UserModel = require('../models/userModel');
const TransactionModel = require('../models/transactionModel');
const MlService = require('./mlService');
const { CATEGORIAS_GASTO } = require('../models/schemas');
const { round2 } = require('../utils/math');

const RANGES = [
  { label: '$0 – $5,000', min: 0, max: 5000 }, { label: '$5,000 – $10,000', min: 5000, max: 10000 },
  { label: '$10,000 – $20,000', min: 10000, max: 20000 }, { label: '$20,000+', min: 20000, max: Infinity },
];

// Todo se calcula únicamente con datos VÁLIDOS (usuarios y transacciones inválidos se excluyen)
async function getAdminStats() {
  const { valid: users, skipped: skippedUsers } = await UserModel.listValid();
  const { valid: txsAll, skipped: skippedTx } = await TransactionModel.allValid();
  const ids = new Set(users.map((u) => u.id));
  const txs = txsAll.filter((t) => ids.has(t.user_id));

  const spends = txs.filter((t) => t.type === 'gasto');
  const totalSpend = spends.reduce((s, t) => s + t.amount, 0);
  const totalIncome = txs.filter((t) => t.type === 'ingreso').reduce((s, t) => s + t.amount, 0);

  // gasto promedio mensual por usuario y categoría = total / (usuario-mes con gastos)
  const userMonths = new Set(spends.map((t) => `${t.user_id}|${t.tx_date.slice(0, 7)}`)).size || 1;
  const categoryDistribution = CATEGORIAS_GASTO.map((category) => {
    const list = spends.filter((t) => t.category === category);
    const total = list.reduce((s, t) => s + t.amount, 0);
    return { category, total: round2(total), share: totalSpend ? round2((total / totalSpend) * 100) : 0, avgMonthlyPerUser: round2(total / userMonths), transactions: list.length };
  });

  const budgetRanges = RANGES.map((r) => ({ range: r.label, users: users.filter((u) => u.monthly_budget >= r.min && u.monthly_budget < r.max).length }));

  const monthMap = {};
  txs.forEach((t) => {
    const k = t.tx_date.slice(0, 7);
    monthMap[k] = monthMap[k] || { month: k, spend: 0, income: 0, transactions: 0 };
    monthMap[k][t.type === 'gasto' ? 'spend' : 'income'] += t.amount; monthMap[k].transactions++;
  });
  const monthlyActivity = Object.values(monthMap).sort((a, b) => a.month.localeCompare(b.month))
    .map((m) => ({ ...m, spend: round2(m.spend), income: round2(m.income) }));

  const clientsTable = users.map((u) => {
    const mine = txs.filter((t) => t.user_id === u.id);
    return {
      id: u.id, name: u.name, email: u.email, role: u.role, monthlyBudget: u.monthly_budget, transactions: mine.length,
      totalSpend: round2(mine.filter((t) => t.type === 'gasto').reduce((s, t) => s + t.amount, 0)),
      totalIncome: round2(mine.filter((t) => t.type === 'ingreso').reduce((s, t) => s + t.amount, 0)),
      lastActivity: mine.reduce((m, t) => (t.tx_date > m ? t.tx_date : m), '') || null,
    };
  }).sort((a, b) => b.transactions - a.transactions);

  return {
    summary: {
      totalUsers: users.length, clients: users.filter((u) => u.role === 'cliente').length, admins: users.filter((u) => u.role === 'admin').length,
      totalTransactions: txs.length, totalSpend: round2(totalSpend), totalIncome: round2(totalIncome),
    },
    categoryDistribution, budgetRanges, monthlyActivity, clientsTable,
    ml: await MlService.getMetrics(),
    excludedInvalid: { users: skippedUsers, transactions: skippedTx },
  };
}
module.exports = { getAdminStats };
