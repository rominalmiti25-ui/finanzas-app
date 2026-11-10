const MlService = require('../services/mlService');
exports.prediction = async (req, res) => res.json(await MlService.predictForUser(req.user));
exports.categorize = async (req, res) => res.json(await MlService.categorize(req.body.description));
exports.train = async (req, res) => res.json(await MlService.trainAll());
