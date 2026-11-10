const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const UserModel = require('../models/userModel');

// Verifica el token y CARGA el usuario desde la BD en cada petición:
// el rol sale del servidor (no del token ni del cliente), así una promoción aplica de inmediato.
async function authenticate(req, res, next) {
  try {
    const h = req.headers.authorization || '';
    const [scheme, token] = h.split(' ');
    if (scheme !== 'Bearer' || !token) return res.status(401).json({ error: 'No autenticado' });
    let payload;
    try { payload = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] }); }
    catch { return res.status(401).json({ error: 'Sesión inválida o expirada' }); }
    const user = await UserModel.findById(Number(payload.sub));
    if (!user || user.invalid) return res.status(401).json({ error: 'Sesión inválida' });
    req.user = user;
    next();
  } catch (e) { next(e); }
}

const requireRole = (role) => (req, res, next) => {
  if (!req.user || req.user.role !== role) return res.status(403).json({ error: 'Permisos insuficientes' });
  next();
};

module.exports = { authenticate, requireRole };
