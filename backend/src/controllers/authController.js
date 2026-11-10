const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const { JWT_SECRET, JWT_EXPIRES } = require('../config/env');
const UserModel = require('../models/userModel');

let dummyHash; // para igualar tiempos cuando el correo no existe
const token = (id) => jwt.sign({ sub: id }, JWT_SECRET, { algorithm: 'HS256', expiresIn: JWT_EXPIRES });

exports.register = async (req, res) => {
  const { name, email, password, age, monthly_income, monthly_budget } = req.body;
  if (await UserModel.emailExists(email)) return res.status(409).json({ error: 'Ese correo ya está registrado' });
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  const id = await UserModel.create({ name, email, passwordHash, age, monthly_income, monthly_budget });
  const user = await UserModel.findById(id);
  res.status(201).json({ token: token(id), user });
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  const row = await UserModel.findByEmailWithHash(email);
  if (!row) {
    dummyHash = dummyHash || (await argon2.hash('dummy-password', { type: argon2.argon2id }));
    await argon2.verify(dummyHash, password).catch(() => false);
    return res.status(401).json({ error: 'Credenciales incorrectas' });
  }
  const ok = await argon2.verify(row.password_hash, password).catch(() => false);
  if (!ok) return res.status(401).json({ error: 'Credenciales incorrectas' });
  const { password_hash, ...user } = row; // nunca se devuelve el hash
  res.json({ token: token(row.id), user });
};

exports.me = (req, res) => res.json({ user: req.user });
