const { getAdminStats } = require('../services/statsService');
exports.stats = async (req, res) => res.json(await getAdminStats());
