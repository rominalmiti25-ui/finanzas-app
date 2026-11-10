function notFound(req, res) { res.status(404).json({ error: 'Ruta no encontrada' }); }

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON mal formado' });
  if (err.type === 'entity.too.large') return res.status(413).json({ error: 'Solicitud demasiado grande' });
  if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'El registro ya existe' });
  if (err.status && err.status < 500) return res.status(err.status).json({ error: err.message });
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
}
module.exports = { notFound, errorHandler };
