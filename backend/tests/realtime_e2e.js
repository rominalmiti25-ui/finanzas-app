// Prueba de tiempo real. Requiere la API en marcha + datos del seed.
// Uso: node tests/realtime_e2e.js [URL_BASE]
const { io } = require('socket.io-client');
const base = process.argv[2] || 'http://localhost:3000';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const api = async (path, token, method = 'GET', body) => {
  const r = await fetch(base + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: body && JSON.stringify(body) });
  return { status: r.status, data: r.status === 204 ? null : await r.json() };
};
const login = async (email, pw) => (await api('/api/auth/login', null, 'POST', { email, password: pw })).data.token;
const connect = (token) => new Promise((res, rej) => {
  const s = io(base, { auth: { token }, transports: ['websocket'], reconnection: false });
  s.on('connect', () => res(s)); s.on('connect_error', (e) => rej(e));
});
let fails = 0;
const check = (name, ok, extra = '') => { console.log((ok ? 'OK   ' : 'FALLA') + ' ' + name + (extra ? '  ' + extra : '')); if (!ok) fails++; };

(async () => {
  const adminT = await login('admin@demo.com', 'Admin1234');
  const clientT = await login('cliente@demo.com', 'Cliente1234');
  const otherT = await login('usuario41@demo.com', 'Demo12345');

  // 1. sin token o con token falso se rechaza
  let rejected = false; try { await connect(undefined); } catch { rejected = true; }
  check('conexión sin token rechazada', rejected);
  rejected = false; try { await connect('token.falso.123'); } catch { rejected = true; }
  check('conexión con token falso rechazada', rejected);

  const sAdmin = await connect(adminT), sClient = await connect(clientT), sOther = await connect(otherT);
  const got = { adminAct: [], clientTx: [], clientSawAdmin: [], otherTx: [], otherRole: [], otherAct: [] };
  sAdmin.on('admin:activity', (d) => got.adminAct.push(d));
  sClient.on('transaction:created', (d) => got.clientTx.push(d)); sClient.on('transaction:deleted', (d) => got.clientTx.push(d));
  sClient.on('admin:activity', (d) => got.clientSawAdmin.push(d));
  sOther.on('transaction:created', (d) => got.otherTx.push(d));
  sOther.on('role:changed', (d) => got.otherRole.push(d)); sOther.on('admin:activity', (d) => got.otherAct.push(d));

  // 2. el cliente crea un gasto -> el admin lo recibe sin pedirlo
  const today = new Date().toISOString().slice(0, 10);
  const created = await api('/api/transactions', clientT, 'POST', { type: 'gasto', amount: 123.45, category: 'Alimentación', description: 'Prueba tiempo real', tx_date: today });
  await wait(600);
  const a = got.adminAct.find((x) => x.kind === 'transaction' && x.action === 'created');
  check('admin recibe la transacción en vivo', !!a && a.amount === 123.45 && a.category === 'Alimentación', JSON.stringify(a));
  check('el cliente recibe el evento en su otro dispositivo', got.clientTx.some((x) => x.item && x.item.amount === 123.45));
  check('un cliente NO recibe eventos de admin', got.clientSawAdmin.length === 0);
  check('otro cliente NO recibe la transacción ajena', got.otherTx.length === 0);

  // 3. borrar
  await api('/api/transactions/' + created.data.item.id, clientT, 'DELETE'); await wait(400);
  check('admin recibe el borrado', got.adminAct.some((x) => x.action === 'deleted'));

  // 4. promoción en vivo: el usuario conectado se vuelve admin sin reconectar
  const users = (await api('/api/users', adminT)).data.users; const target = users.find((u) => u.email === 'usuario41@demo.com');
  const pr = await api('/api/users/' + target.id + '/promote', adminT, 'PATCH'); await wait(500);
  if (pr.status === 200) {
    check('usuario promovido recibe role:changed', got.otherRole.length === 1);
    await api('/api/transactions', clientT, 'POST', { type: 'gasto', amount: 50, category: 'Otros', description: 'otra', tx_date: today }); await wait(500);
    check('el nuevo admin recibe actividad sin reconectar', got.otherAct.some((x) => x.kind === 'transaction'));
  } else console.log('INFO  usuario41 ya era admin (409), se omite la prueba de promoción');
  check('admin ve el evento de promoción', pr.status !== 200 || got.adminAct.some((x) => x.kind === 'promote'));

  // 5. alta de usuario
  const email = 'live' + Date.now() + '@demo.com';
  await api('/api/auth/register', null, 'POST', { name: 'Usuario Vivo', email, password: 'Clave1234', age: 22, monthly_income: 9000, monthly_budget: 7000 }); await wait(500);
  check('admin recibe el alta de un usuario nuevo', got.adminAct.some((x) => x.kind === 'user' && x.userName === 'Usuario Vivo'));

  [sAdmin, sClient, sOther].forEach((s) => s.close());
  console.log(fails ? `\n${fails} prueba(s) fallaron` : '\nTodas las pruebas de tiempo real pasaron');
  process.exit(fails ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
