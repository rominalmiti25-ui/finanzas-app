const test = require('node:test');
const assert = require('node:assert');
const { generateDemo } = require('../src/scripts/demoData');
const { trainSpending } = require('../src/ml/spendingModel');
const { trainClassifier, NaiveBayes } = require('../src/ml/naiveBayes');
const { currentYm } = require('../src/utils/dates');
const { registerSchema, transactionInputSchema, userRowSchema, transactionRowSchema, filterValid } = require('../src/models/schemas');

const demo = generateDemo();
const txs = demo.transactions.map((t, i) => ({ id: i + 1, user_id: t.userIdx + 1, ...t }));
const usersById = new Map(demo.users.map((u, i) => [i + 1, { id: i + 1, ...u }]));

test('regresión: mejora al baseline "repetir el mes anterior" o al menos es razonable', () => {
  const { metrics } = trainSpending(txs, usersById, currentYm());
  console.log('Métricas gasto:', { mae: metrics.mae.toFixed(0), r2: metrics.r2.toFixed(3), baseline: metrics.baselineMae.toFixed(0), mejora: (metrics.improvementVsBaseline * 100).toFixed(1) + '%' });
  assert.ok(metrics.r2 > 0.5, 'R2 debe ser > 0.5, fue ' + metrics.r2);
});

test('clasificador: accuracy > 80 %', () => {
  const samples = txs.filter((t) => t.type === 'gasto').map((t) => ({ text: t.description, label: t.category }));
  const { model, metrics } = trainClassifier(samples);
  console.log('Métricas clasificador:', metrics);
  assert.ok(metrics.accuracy > 0.8);
  const nb = NaiveBayes.fromJSON(JSON.parse(JSON.stringify(model)));
  assert.strictEqual(nb.predict('gasolina para el coche')[0].category, 'Transporte');
});

test('validación: no se permite asignarse rol ni edad inválida', () => {
  const base = { name: 'Ana', email: 'a@b.com', password: 'Clave1234', age: 20, monthly_income: 1000, monthly_budget: 800 };
  assert.ok(registerSchema.safeParse(base).success);
  assert.ok(!registerSchema.safeParse({ ...base, role: 'admin' }).success, 'role debe rechazarse');
  assert.ok(!registerSchema.safeParse({ ...base, age: -5 }).success);
  assert.ok(!registerSchema.safeParse({ ...base, password: 'corta' }).success);
  assert.ok(!transactionInputSchema.safeParse({ type: 'gasto', amount: -10, category: 'Ropa', tx_date: '2026-01-01' }).success);
  assert.ok(!transactionInputSchema.safeParse({ type: 'gasto', amount: 10, category: 'Inventada', tx_date: '2026-01-01' }).success);
});

test('lectura de BD: filas inválidas se excluyen y el hash nunca se devuelve', () => {
  const rows = [
    { id: 1, name: 'OK', email: 'ok@x.com', role: 'cliente', age: 30, monthly_income: 1, monthly_budget: 1, password_hash: 'x'.repeat(40) },
    { id: 2, name: 'Edad negativa', email: 'bad@x.com', role: 'cliente', age: -5, monthly_income: 1, monthly_budget: 1, password_hash: 'x'.repeat(40) },
  ];
  const { valid, skipped } = filterValid(rows, userRowSchema);
  assert.strictEqual(valid.length, 1); assert.strictEqual(skipped, 1);
  assert.strictEqual(valid[0].password_hash, undefined);
  assert.ok(!transactionRowSchema.safeParse({ id: 1, user_id: 1, type: 'gasto', amount: -3, category: 'Ropa', description: '', tx_date: '2026-01-01' }).success);
});
