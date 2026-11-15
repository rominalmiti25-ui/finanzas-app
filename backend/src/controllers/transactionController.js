const TransactionModel = require('../models/transactionModel');
const { transactionRowSchema } = require('../models/schemas');
const realtime = require('../realtime/socket');

// Verifica pertenencia: cambiar el id en la URL no permite ver/editar datos de otro cliente
async function ownedOr(req, res) {
  const raw = await TransactionModel.getRaw(req.params.id);
  if (!raw) { res.status(404).json({ error: 'Transacción no encontrada' }); return null; }
  if (raw.user_id !== req.user.id) { res.status(403).json({ error: 'No tienes permiso sobre este registro' }); return null; }
  return raw;
}

exports.list = async (req, res) => {
  const items = await TransactionModel.listByUser(req.user.id, req.validatedQuery);
  res.json({ items });
};

exports.create = async (req, res) => {
  const id = await TransactionModel.create(req.user.id, req.body);
  const raw = await TransactionModel.getRaw(id);
  const item = transactionRowSchema.parse(raw);
  realtime.transactionChanged('created', req.user, item); // tiempo real
  res.status(201).json({ item });
};

exports.getOne = async (req, res) => {
  const raw = await ownedOr(req, res); if (!raw) return;
  const p = transactionRowSchema.safeParse(raw);
  if (!p.success) return res.status(422).json({ error: 'El registro almacenado es inválido' }); // error controlado
  res.json({ item: p.data });
};

exports.update = async (req, res) => {
  const raw = await ownedOr(req, res); if (!raw) return;
  await TransactionModel.update(req.params.id, req.user.id, req.body);
  const item = transactionRowSchema.parse(await TransactionModel.getRaw(req.params.id));
  realtime.transactionChanged('updated', req.user, item);
  res.json({ item });
};

exports.remove = async (req, res) => {
  const raw = await ownedOr(req, res); if (!raw) return;
  await TransactionModel.remove(req.params.id, req.user.id);
  realtime.transactionChanged('deleted', req.user, raw);
  res.status(204).end();
};
