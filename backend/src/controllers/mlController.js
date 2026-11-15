const MlService = require('../services/mlService');
const realtime = require('../realtime/socket');
exports.prediction = async (req, res) => res.json(await MlService.predictForUser(req.user));
exports.categorize = async (req, res) => res.json(await MlService.categorize(req.body.description));
exports.train = async (req, res) => {
  const result = await MlService.trainAll();
  realtime.modelsTrained();
  res.json(result);
};
