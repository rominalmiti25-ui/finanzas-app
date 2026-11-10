// Modelo de regresión: predice el gasto total de un mes a partir del historial del cliente.
//
// Variables (features) del modelo, calculadas con los meses PREVIOS al mes a predecir:
//   1. Gasto del mes anterior
//   2. Frecuencia de transacciones del mes anterior
//   3. Ingresos registrados el mes anterior
//   4. Promedio de gasto de los últimos 3 meses
//   5. Ingreso mensual declarado en el perfil
// Objetivo: gasto total del mes siguiente.
const { Ridge } = require('./ridge');
const { mean, std } = require('../utils/math');
const { ymIndex, ymFromIndex } = require('../utils/dates');

const FEATURE_NAMES = [
  'Gasto del mes anterior', 'Número de transacciones del mes anterior', 'Ingresos del mes anterior',
  'Promedio de gasto (3 meses)', 'Ingreso mensual del perfil',
];

const emptyMonth = () => ({ spend: 0, income: 0, count: 0, byCat: {} });

// transacciones válidas -> Map<userId, Map<'YYYY-MM', {spend,income,count,byCat}>>
function aggregateMonthly(transactions) {
  const users = new Map();
  for (const t of transactions) {
    const ym = t.tx_date.slice(0, 7);
    if (!users.has(t.user_id)) users.set(t.user_id, new Map());
    const um = users.get(t.user_id);
    if (!um.has(ym)) um.set(ym, emptyMonth());
    const m = um.get(ym);
    m.count++;
    if (t.type === 'gasto') { m.spend += t.amount; m.byCat[t.category] = (m.byCat[t.category] || 0) + t.amount; }
    else m.income += t.amount;
  }
  return users;
}

// Serie consecutiva de meses COMPLETOS (desde el primero con datos hasta el mes anterior al actual)
function buildSeries(userMonths, currentYm) {
  const keys = [...userMonths.keys()].filter((k) => k < currentYm).sort();
  if (!keys.length) return [];
  const out = [];
  for (let i = ymIndex(keys[0]); i <= ymIndex(currentYm) - 1; i++) {
    const k = ymFromIndex(i);
    out.push({ month: k, ...(userMonths.get(k) || emptyMonth()) });
  }
  return out;
}

// Features para predecir series[i] usando únicamente series[0..i-1]
function featuresFor(series, i, profileIncome) {
  const prev = series[i - 1];
  const prior = series.slice(Math.max(0, i - 3), i).map((m) => m.spend);
  return [prev.spend, prev.count, prev.income, mean(prior), profileIncome];
}

function trainSpending(transactions, usersById, currentYm) {
  const agg = aggregateMonthly(transactions);
  const train = [], test = [];
  for (const [uid, um] of agg) {
    const u = usersById.get(uid);
    if (!u) continue;
    const series = buildSeries(um, currentYm);
    for (let i = 1; i < series.length; i++) {
      const row = { x: featuresFor(series, i, u.monthly_income), y: series[i].spend };
      // validación temporal: el ÚLTIMO mes completo de cada cliente se reserva para probar
      (i === series.length - 1 ? test : train).push(row);
    }
  }
  if (train.length < 15 || test.length < 5) {
    throw new Error('Datos insuficientes para entrenar (se requieren varios clientes con al menos 3 meses de historial).');
  }
  const eval_ = new Ridge(1).fit(train.map((r) => r.x), train.map((r) => r.y));
  const preds = test.map((r) => Math.max(0, eval_.predict(r.x)));
  const ys = test.map((r) => r.y);
  const mae = mean(preds.map((p, i) => Math.abs(p - ys[i])));
  const rmse = Math.sqrt(mean(preds.map((p, i) => (p - ys[i]) ** 2)));
  const ssRes = preds.reduce((s, p, i) => s + (ys[i] - p) ** 2, 0);
  const yM = mean(ys);
  const ssTot = ys.reduce((s, y) => s + (y - yM) ** 2, 0);
  const r2 = ssTot ? 1 - ssRes / ssTot : 0;
  const baselineMae = mean(test.map((r) => Math.abs(r.x[0] - r.y))); // "el mes pasado se repite"
  const all = [...train, ...test];
  const finalModel = new Ridge(1).fit(all.map((r) => r.x), all.map((r) => r.y));
  return {
    model: finalModel.toJSON(),
    metrics: {
      mae, rmse, r2, baselineMae,
      improvementVsBaseline: baselineMae ? 1 - mae / baselineMae : 0,
      nTrain: train.length, nTest: test.length, features: FEATURE_NAMES,
      method: 'Regresión Ridge, validación temporal (último mes de cada cliente)',
    },
  };
}

module.exports = { aggregateMonthly, buildSeries, featuresFor, trainSpending, FEATURE_NAMES, Ridge };
