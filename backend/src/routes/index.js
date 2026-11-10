const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const h = require('../utils/asyncHandler');
const { authenticate, requireRole } = require('../middleware/auth');
const { validateBody, validateParams, validateQuery } = require('../utils/validate');
const S = require('../models/schemas');
const auth = require('../controllers/authController');
const tx = require('../controllers/transactionController');
const users = require('../controllers/userController');
const ml = require('../controllers/mlController');
const admin = require('../controllers/adminController');

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 100, standardHeaders: true, legacyHeaders: false, message: { error: 'Demasiados intentos, intenta más tarde' } });

// Autenticación
router.post('/auth/register', authLimiter, validateBody(S.registerSchema), h(auth.register));
router.post('/auth/login', authLimiter, validateBody(S.loginSchema), h(auth.login));
router.get('/auth/me', authenticate, auth.me);

// Transacciones (solo las del usuario autenticado)
router.get('/transactions', authenticate, validateQuery(S.listQuery), h(tx.list));
router.post('/transactions', authenticate, validateBody(S.transactionInputSchema), h(tx.create));
router.get('/transactions/:id', authenticate, validateParams(S.idParam), h(tx.getOne));
router.put('/transactions/:id', authenticate, validateParams(S.idParam), validateBody(S.transactionInputSchema), h(tx.update));
router.delete('/transactions/:id', authenticate, validateParams(S.idParam), h(tx.remove));

// Machine Learning (cliente)
router.get('/ml/prediction', authenticate, h(ml.prediction));
router.post('/ml/categorize', authenticate, validateBody(S.categorizeSchema), h(ml.categorize));

// Administrador
router.get('/users', authenticate, requireRole('admin'), h(users.list));
router.patch('/users/:id/promote', authenticate, requireRole('admin'), validateParams(S.idParam), h(users.promote));
router.get('/admin/stats', authenticate, requireRole('admin'), h(admin.stats));
router.post('/admin/ml/train', authenticate, requireRole('admin'), h(ml.train));

module.exports = router;
