const { z } = require('zod');
const { isValidDateStr, tomorrowStr } = require('../utils/dates');

const CATEGORIAS_GASTO = [
  'Alimentación', 'Transporte', 'Vivienda', 'Servicios', 'Salud',
  'Entretenimiento', 'Educación', 'Ropa', 'Otros',
];
const CATEGORIA_INGRESO = 'Ingresos';

// ---------- Entradas (body / params / query) ----------
const email = z.string({ required_error: 'El correo es obligatorio' })
  .trim().toLowerCase().email('Correo inválido').max(150);

const password = z.string({ required_error: 'La contraseña es obligatoria' })
  .min(8, 'Mínimo 8 caracteres').max(128)
  .regex(/[A-Za-z]/, 'Debe incluir al menos una letra')
  .regex(/[0-9]/, 'Debe incluir al menos un número');

// .strict() => cualquier campo extra (por ejemplo "role") se RECHAZA con 400
const registerSchema = z.object({
  name: z.string({ required_error: 'El nombre es obligatorio' }).trim().min(2, 'Mínimo 2 caracteres').max(100),
  email,
  password,
  age: z.number({ invalid_type_error: 'La edad debe ser numérica', required_error: 'La edad es obligatoria' })
    .int('La edad debe ser entera').min(13, 'Edad mínima: 13').max(120, 'Edad máxima: 120'),
  monthly_income: z.number({ invalid_type_error: 'Ingreso mensual inválido', required_error: 'El ingreso mensual es obligatorio' })
    .min(0, 'No puede ser negativo').max(10_000_000),
  monthly_budget: z.number({ invalid_type_error: 'Presupuesto inválido', required_error: 'El presupuesto mensual es obligatorio' })
    .min(0, 'No puede ser negativo').max(10_000_000),
}).strict();

const loginSchema = z.object({
  email,
  password: z.string({ required_error: 'La contraseña es obligatoria' }).min(1).max(128),
}).strict();

const dateField = z.string({ required_error: 'La fecha es obligatoria' })
  .refine(isValidDateStr, 'Fecha inválida (use AAAA-MM-DD)')
  .refine((s) => s <= tomorrowStr(), 'La fecha no puede estar en el futuro');

const transactionInputSchema = z.object({
  type: z.enum(['gasto', 'ingreso'], { errorMap: () => ({ message: "El tipo debe ser 'gasto' o 'ingreso'" }) }),
  amount: z.number({ invalid_type_error: 'El monto debe ser numérico', required_error: 'El monto es obligatorio' })
    .positive('El monto debe ser mayor a 0').max(10_000_000, 'Monto demasiado alto')
    .refine((n) => Math.round(n * 100) / 100 === n, 'Máximo 2 decimales'),
  category: z.string().trim().max(40).optional(),
  description: z.string().trim().max(200, 'Máximo 200 caracteres').default(''),
  tx_date: dateField,
}).strict().superRefine((v, ctx) => {
  if (v.type === 'gasto') {
    if (!v.category || !CATEGORIAS_GASTO.includes(v.category)) {
      ctx.addIssue({ code: 'custom', path: ['category'], message: `Categoría inválida. Use: ${CATEGORIAS_GASTO.join(', ')}` });
    }
  }
}).transform((v) => ({ ...v, category: v.type === 'ingreso' ? CATEGORIA_INGRESO : v.category }));

const idParam = z.object({ id: z.coerce.number().int().positive() });

const listQuery = z.object({
  limit: z.coerce.number().int().min(1).max(500).default(200),
  offset: z.coerce.number().int().min(0).default(0),
  type: z.enum(['gasto', 'ingreso']).optional(),
  month: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'Use AAAA-MM').optional(),
});

const categorizeSchema = z.object({
  description: z.string().trim().min(2, 'Escribe al menos 2 caracteres').max(200),
}).strict();

// ---------- Filas leídas de la BD (se validan ANTES de responder) ----------
// Los campos no declarados (p. ej. password_hash) se descartan automáticamente (strip).
const userRowSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(100),
  email: z.string().email().max(150),
  role: z.enum(['cliente', 'admin']),
  age: z.number().int().min(0).max(120),
  monthly_income: z.number().min(0),
  monthly_budget: z.number().min(0),
  created_at: z.union([z.string(), z.date()]).optional(),
});
const userRowWithHashSchema = userRowSchema.extend({ password_hash: z.string().min(20) });

const transactionRowSchema = z.object({
  id: z.number().int().positive(),
  user_id: z.number().int().positive(),
  type: z.enum(['gasto', 'ingreso']),
  amount: z.number().positive().max(10_000_000),
  category: z.string().min(1).max(40),
  description: z.string().max(200),
  tx_date: z.string().refine(isValidDateStr),
}).superRefine((v, ctx) => {
  if (v.type === 'gasto' && !CATEGORIAS_GASTO.includes(v.category)) ctx.addIssue({ code: 'custom', message: 'categoría inválida' });
  if (v.type === 'ingreso' && v.category !== CATEGORIA_INGRESO) ctx.addIssue({ code: 'custom', message: 'categoría inválida' });
});

// Devuelve solo las filas válidas; las inválidas se excluyen y se registran en el log
function filterValid(rows, schema, label = 'registro') {
  const ok = [];
  let skipped = 0;
  for (const r of rows) {
    const p = schema.safeParse(r);
    if (p.success) ok.push(p.data);
    else { skipped++; console.warn(`[validación] ${label} id=${r && r.id} excluido: ${p.error.issues[0].message}`); }
  }
  return { valid: ok, skipped };
}

module.exports = {
  CATEGORIAS_GASTO, CATEGORIA_INGRESO,
  registerSchema, loginSchema, transactionInputSchema, idParam, listQuery, categorizeSchema,
  userRowSchema, userRowWithHashSchema, transactionRowSchema, filterValid,
};
