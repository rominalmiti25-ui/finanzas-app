// Tiempo real con Socket.IO.
// Salas (rooms):
//   user:<id>  -> todos los dispositivos de un mismo usuario
//   admins     -> todos los administradores conectados
// El token JWT se valida al conectar y el ROL se lee de la base de datos (igual que en la API REST).
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const UserModel = require('../models/userModel');

let io = null;

function init(httpServer) {
  io = new Server(httpServer, { cors: { origin: '*' } });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token) return next(new Error('No autenticado'));
      const payload = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
      const user = await UserModel.findById(Number(payload.sub));
      if (!user || user.invalid) return next(new Error('Sesión inválida'));
      socket.data.user = user;
      next();
    } catch (e) {
      next(new Error('Sesión inválida'));
    }
  });

  io.on('connection', (socket) => {
    const u = socket.data.user;
    socket.join(`user:${u.id}`);
    if (u.role === 'admin') socket.join('admins');
  });
  return io;
}

// Todas las funciones son "no-op" si el servidor de sockets no está iniciado (scripts, pruebas).
const emitToUser = (userId, event, payload) => { if (io) io.to(`user:${userId}`).emit(event, payload); };
const emitToAdmins = (event, payload) => { if (io) io.to('admins').emit(event, payload); };
const broadcast = (event, payload) => { if (io) io.emit(event, payload); };
const now = () => new Date().toISOString();

// Un cliente creó/editó/borró un movimiento
function transactionChanged(action, user, tx) {
  emitToUser(user.id, `transaction:${action}`, action === 'deleted' ? { id: tx.id } : { item: tx });
  emitToAdmins('admin:activity', {
    kind: 'transaction', action, userName: user.name, type: tx.type, amount: tx.amount, category: tx.category, at: now(),
  });
}
const userRegistered = (user) => emitToAdmins('admin:activity', { kind: 'user', userName: user.name, at: now() });

// Un admin promovió a un usuario: sus sockets abiertos pasan a la sala de admins sin reconectar
function userPromoted(user) {
  if (io) {
    io.in(`user:${user.id}`).socketsJoin('admins');
    io.to(`user:${user.id}`).emit('role:changed', { role: 'admin' });
  }
  emitToAdmins('admin:activity', { kind: 'promote', userName: user.name, at: now() });
}
function modelsTrained() {
  broadcast('ml:trained', { at: now() });
  emitToAdmins('admin:activity', { kind: 'ml', at: now() });
}

module.exports = { init, emitToUser, emitToAdmins, broadcast, transactionChanged, userRegistered, userPromoted, modelsTrained };
