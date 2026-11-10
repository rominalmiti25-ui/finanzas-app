const { pool } = require('../config/db');
const TransactionModel = require('../models/transactionModel');
const UserModel = require('../models/userModel');
const { Ridge } = require('../ml/ridge');
const { NaiveBayes, trainClassifier } = require('../ml/naiveBayes');
const { trainSpending, aggregateMonthly, buildSeries, featuresFor, FEATURE_NAMES } = require('../ml/spendingModel');
const { currentYm, todayStr, daysInMonth } = require('../utils/dates');
const { mean, std, round2 } = require('../utils/math');

const SPEND = 'spending_ridge', CLS = 'category_nb';
const cache = {};

async function save(name, model, metrics) {
  await pool.execute(
    'INSERT INTO ml_models (name, payload, metrics) VALUES (?,?,?) ON DUPLICATE KEY UPDATE payload = VALUES(payload), metrics = VALUES(metrics)',
    [name, JSON.stringify(model), JSON.stringify(metrics)]);
  cache[name] = { model, metrics, trainedAt: new Date().toISOString() };
}
const parse = (v) => (typeof v === 'string' ? JSON.parse(v) : v);

async function load(name) {
  if (cache[name]) return cache[name];
  const [rows] = await pool.execute('SELECT payload, metrics, trained_at FROM ml_models WHERE name = ?', [name]);
  if (!rows.length) return null;
  cache[name] = { model: parse(rows[0].payload), metrics: parse(rows[0].metrics), trainedAt: rows[0].trained_at };
  return cache[name];
}

// Entrena con los datos capturados por los clientes y guardados en MySQL (solo registros válidos)
async function trainAll() {
  const { valid: users } = await UserModel.listValid();
  const { valid: txs } = await TransactionModel.allValid();
  const usersById = new Map(users.map((u) => [u.id, u]));
  const validTx = txs.filter((t) => usersById.has(t.user_id));
  const out = {};
  try {
    const r = trainSpending(validTx, usersById, currentYm());
    await save(SPEND, r.model, r.metrics); out.spending = r.metrics;
  } catch (e) { out.spendingError = e.message; }
  try {
    const samples = validTx.filter((t) => t.type === 'gasto' && t.description).map((t) => ({ text: t.description, label: t.category }));
    const r = trainClassifier(samples);
    await save(CLS, r.model, r.metrics); out.classifier = r.metrics;
  } catch (e) { out.classifierError = e.message; }
  return out;
}

async function getMetrics() {
  const s = await load(SPEND), c = await load(CLS);
  return { spending: s ? { ...s.metrics, trainedAt: s.trainedAt } : null, classifier: c ? { ...c.metrics, trainedAt: c.trainedAt } : null };
}

async function categorize(description) {
  const m = await load(CLS);
  if (!m) { const e = new Error('El modelo de clasificación aún no está entrenado'); e.status = 503; throw e; }
  const ranked = NaiveBayes.fromJSON(m.model).predict(description);
  return { suggested: ranked[0].category, confidence: round2(ranked[0].confidence), alternatives: ranked.slice(0, 3).map((r) => ({ category: r.category, confidence: round2(r.confidence) })) };
}

// Predicción del gasto del mes en curso a partir de los meses completos anteriores
async function predictForUser(user) {
  const m = await load(SPEND);
  if (!m) return { ready: false, message: 'El modelo aún no está entrenado. Un administrador debe entrenarlo.' };
  const cur = currentYm();
  const txs = await TransactionModel.allByUserValid(user.id);
  const months = aggregateMonthly(txs).get(user.id) || new Map();
  const series = buildSeries(months, cur);
  if (series.length < 1) return { ready: false, message: 'Registra gastos de al menos un mes completo para generar predicciones.' };

  const x = featuresFor(series, series.length, user.monthly_income);
  const predictedSpend = Math.max(0, Ridge.fromJSON(m.model).predict(x));

  // desglose por categoría: reparte la predicción según la proporción de los últimos 3 meses
  const last3 = series.slice(-3);
  const catTot = {};
  last3.forEach((s) => Object.entries(s.byCat).forEach(([c, v]) => { catTot[c] = (catTot[c] || 0) + v; }));
  const sumCat = Object.values(catTot).reduce((a, b) => a + b, 0) || 1;
  const categories = Object.entries(catTot).map(([category, v]) => ({ category, amount: round2((v / sumCat) * predictedSpend) })).sort((a, b) => b.amount - a.amount);

  const incomes = last3.map((s) => s.income).filter((v) => v > 0);
  const predictedIncome = incomes.length ? mean(incomes) : user.monthly_income;

  // gasto en lo que va del mes y proyección
  const curMonth = months.get(cur) || { spend: 0 };
  const day = Number(todayStr().slice(8, 10));
  const projected = day >= 5 ? (curMonth.spend / day) * daysInMonth(cur) : null;

  // detección de gasto desmedido
  const hist = series.map((s) => s.spend);
  const mu = mean(hist), sd = std(hist);
  const alerts = []; let level = 'ok';
  if (curMonth.spend > predictedSpend) { alerts.push('Ya superaste el gasto esperado para este mes.'); level = 'danger'; }
  else if (projected && projected > predictedSpend * 1.2) { alerts.push('Al ritmo actual terminarás el mes por encima de lo esperado.'); level = 'warning'; }
  if (user.monthly_budget > 0 && projected && projected > user.monthly_budget) {
    alerts.push('Tu ritmo de gasto proyectado supera tu presupuesto mensual.'); if (level === 'ok') level = 'warning';
  }
  if (projected && series.length >= 3 && sd > 0 && projected > mu + 1.5 * sd) {
    alerts.push('Patrón inusual: tu gasto proyectado es mucho mayor que tu historial.'); level = 'danger';
  }
  if (!alerts.length) alerts.push('Tu gasto va dentro de lo esperado. ¡Sigue así!');

  return {
    ready: true, month: cur,
    predictedSpend: round2(predictedSpend), predictedIncome: round2(predictedIncome),
    predictedSavings: round2(predictedIncome - predictedSpend),
    spentSoFar: round2(curMonth.spend), projectedSpend: projected === null ? null : round2(projected),
    monthlyBudget: user.monthly_budget, alertLevel: level, alerts, categories,
    history: series.slice(-6).map((s) => ({ month: s.month, spend: round2(s.spend) })),
    modelInfo: { trainedAt: m.trainedAt, mae: round2(m.metrics.mae), r2: round2(m.metrics.r2), features: FEATURE_NAMES },
  };
}

module.exports = { trainAll, getMetrics, categorize, predictForUser };
