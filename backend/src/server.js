const { PORT } = require('./config/env');
const app = require('./app');
const MlService = require('./services/mlService');

app.listen(PORT, () => {
  console.log(`API escuchando en el puerto ${PORT}`);
  // Si aún no hay modelos entrenados y hay datos suficientes, entrena en segundo plano
  MlService.getMetrics().then(async (m) => {
    if (!m.spending || !m.classifier) { const r = await MlService.trainAll(); console.log('Entrenamiento inicial ML:', JSON.stringify(r)); }
  }).catch((e) => console.warn('ML no inicializado:', e.message));
});
