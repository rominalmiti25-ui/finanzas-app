const { PORT } = require('./config/env');
const http = require('http');
const app = require('./app');
const realtime = require('./realtime/socket');
const MlService = require('./services/mlService');

const server = http.createServer(app);
realtime.init(server); // Socket.IO comparte el mismo puerto que la API

server.listen(PORT, () => {
  console.log(`API escuchando en el puerto ${PORT}`);
  // Si aún no hay modelos entrenados y hay datos suficientes, entrena en segundo plano
  MlService.getMetrics().then(async (m) => {
    if (!m.spending || !m.classifier) { const r = await MlService.trainAll(); console.log('Entrenamiento inicial ML:', JSON.stringify(r)); }
  }).catch((e) => console.warn('ML no inicializado:', e.message));
});
