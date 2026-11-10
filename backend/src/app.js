const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api', routes);
// Ruta pública equivalente a la del PDF (/users): protegida con permisos de administrador
app.get('/users', (req, res, next) => { req.url = '/users'; routes(req, res, next); });
app.use(notFound);
app.use(errorHandler);
module.exports = app;
