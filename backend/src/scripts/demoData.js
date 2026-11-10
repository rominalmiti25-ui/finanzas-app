// Generador de datos de prueba REPRODUCIBLE (semilla fija). Sirve para el seed y para los tests de ML.
const { mulberry32, round2 } = require('../utils/math');
const { ymIndex, ymFromIndex, currentYm, daysInMonth } = require('../utils/dates');

const DESC = {
  'Alimentación': ['Supermercado', 'Tacos al pastor', 'Comida en restaurante', 'Despensa semanal', 'Café y pan dulce', 'Frutas y verduras', 'Pizza a domicilio', 'Tortillas y leche'],
  'Transporte': ['Gasolina', 'Uber al trabajo', 'Pasaje de autobús', 'Estacionamiento', 'Recarga tarjeta metro', 'Mantenimiento del auto', 'Caseta de peaje'],
  'Vivienda': ['Renta mensual', 'Mantenimiento del hogar', 'Muebles para casa', 'Reparación de plomería'],
  'Servicios': ['Recibo de luz CFE', 'Internet Telmex', 'Recibo de agua', 'Plan de celular', 'Gas estacionario', 'Suscripción de streaming'],
  'Salud': ['Consulta médica', 'Medicinas en farmacia', 'Dentista', 'Análisis de laboratorio', 'Mensualidad del gimnasio'],
  'Entretenimiento': ['Cine con amigos', 'Boletos de concierto', 'Videojuego Steam', 'Salida al bar', 'Spotify premium', 'Parque de diversiones'],
  'Educación': ['Colegiatura', 'Libros universitarios', 'Curso en línea', 'Papelería y útiles', 'Examen de certificación'],
  'Ropa': ['Zapatos tenis', 'Camisa nueva', 'Pantalón de mezclilla', 'Chamarra de invierno', 'Accesorios y gorras'],
  'Otros': ['Regalo de cumpleaños', 'Donativo', 'Propina', 'Trámite de gobierno', 'Veterinario de la mascota'],
};
// peso relativo de cada categoría en el gasto mensual
const WEIGHT = { 'Alimentación': 0.26, 'Transporte': 0.13, 'Vivienda': 0.25, 'Servicios': 0.10, 'Salud': 0.05, 'Entretenimiento': 0.08, 'Educación': 0.05, 'Ropa': 0.04, 'Otros': 0.04 };
const NAMES = ['Ana', 'Luis', 'María', 'Carlos', 'Sofía', 'Jorge', 'Lucía', 'Pedro', 'Valeria', 'Diego', 'Fernanda', 'Andrés', 'Paola', 'Ricardo', 'Daniela', 'Miguel'];
const LASTS = ['García', 'Hernández', 'López', 'Martínez', 'Rodríguez', 'Pérez', 'Sánchez', 'Ramírez', 'Torres', 'Flores'];

function generateDemo({ nUsers = 40, monthsBack = 6, today = new Date(), seed = 2026 } = {}) {
  const rng = mulberry32(seed);
  const pick = (a) => a[Math.floor(rng() * a.length)];
  const cur = currentYm(today);
  const users = [], transactions = [];

  for (let u = 0; u < nUsers; u++) {
    const income = Math.round((8000 + rng() * 32000) / 500) * 500;
    const base = 0.5 + rng() * 0.35;              // proporción de gasto habitual
    const trend = (rng() - 0.45) * 0.03;          // tendencia mensual
    const spender = rng() < 0.12;                 // algunos gastan de forma desmedida
    users.push({
      name: `${pick(NAMES)} ${pick(LASTS)}`, email: `usuario${String(u + 1).padStart(2, '0')}@demo.com`,
      age: 18 + Math.floor(rng() * 45), monthly_income: income, monthly_budget: Math.round((income * 0.8) / 500) * 500,
    });
    let prev = income * base;
    for (let k = monthsBack; k >= 0; k--) {
      const ym = ymFromIndex(ymIndex(cur) - k);
      const partial = k === 0;
      const lastDay = partial ? Math.min(today.getDate(), daysInMonth(ym)) : daysInMonth(ym);
      // el gasto depende del mes previo (inercia) + ingreso + ruido => hay patrón que el modelo puede aprender
      let target = 0.6 * prev + 0.4 * income * (base + trend * (monthsBack - k)) + (rng() - 0.5) * income * 0.06;
      if (spender && rng() < 0.3) target *= 1.35;
      target = Math.max(income * 0.2, target);
      if (!partial) prev = target;
      const frac = partial ? lastDay / daysInMonth(ym) : 1;
      for (const [cat, w] of Object.entries(WEIGHT)) {
        const catTotal = target * w * (0.75 + rng() * 0.5) * frac;
        const n = 1 + Math.floor(rng() * 4);
        for (let t = 0; t < n; t++) {
          const amount = round2(Math.max(20, (catTotal / n) * (0.6 + rng() * 0.8)));
          transactions.push({
            userIdx: u, type: 'gasto', amount, category: cat, description: pick(DESC[cat]),
            tx_date: `${ym}-${String(1 + Math.floor(rng() * lastDay)).padStart(2, '0')}`,
          });
        }
      }
      for (const d of [1, 15]) {
        if (d > lastDay) continue;
        transactions.push({ userIdx: u, type: 'ingreso', amount: round2(income / 2), category: 'Ingresos', description: 'Pago de nómina quincenal', tx_date: `${ym}-${String(d).padStart(2, '0')}` });
      }
    }
  }
  return { users, transactions };
}

module.exports = { generateDemo, DESC };
