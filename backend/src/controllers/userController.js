const UserModel = require('../models/userModel');

exports.list = async (req, res) => {
  const { valid } = await UserModel.listValid(); // usuarios inválidos se excluyen
  res.json({ users: valid });
};

exports.promote = async (req, res) => {
  const user = await UserModel.findById(req.params.id);
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  if (user.invalid) return res.status(422).json({ error: 'El registro del usuario es inválido' });
  if (user.role === 'admin') return res.status(409).json({ error: 'El usuario ya es administrador' });
  await UserModel.promote(user.id);
  res.json({ user: await UserModel.findById(user.id) });
};
