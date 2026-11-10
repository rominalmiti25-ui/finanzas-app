class Prediction {
  final bool ready;
  final String? message;
  final String month;
  final double predictedSpend;
  final double predictedIncome;
  final double predictedSavings;
  final double spentSoFar;
  final double? projectedSpend;
  final double monthlyBudget;
  final String alertLevel; // ok | warning | danger
  final List<String> alerts;
  final List<MapEntry<String, double>> categories;
  final List<MapEntry<String, double>> history;
  final double mae;
  final double r2;
  final List<String> features;

  Prediction({required this.ready, this.message, this.month = '', this.predictedSpend = 0,
      this.predictedIncome = 0, this.predictedSavings = 0, this.spentSoFar = 0, this.projectedSpend,
      this.monthlyBudget = 0, this.alertLevel = 'ok', this.alerts = const [], this.categories = const [],
      this.history = const [], this.mae = 0, this.r2 = 0, this.features = const []});

  factory Prediction.fromJson(Map<String, dynamic> j) {
    if (j['ready'] != true) return Prediction(ready: false, message: j['message'] as String?);
    final info = j['modelInfo'] as Map<String, dynamic>;
    return Prediction(
      ready: true,
      month: j['month'] as String,
      predictedSpend: (j['predictedSpend'] as num).toDouble(),
      predictedIncome: (j['predictedIncome'] as num).toDouble(),
      predictedSavings: (j['predictedSavings'] as num).toDouble(),
      spentSoFar: (j['spentSoFar'] as num).toDouble(),
      projectedSpend: (j['projectedSpend'] as num?)?.toDouble(),
      monthlyBudget: (j['monthlyBudget'] as num).toDouble(),
      alertLevel: j['alertLevel'] as String,
      alerts: (j['alerts'] as List).map((e) => e.toString()).toList(),
      categories: (j['categories'] as List)
          .map((e) => MapEntry(e['category'] as String, (e['amount'] as num).toDouble()))
          .toList(),
      history: (j['history'] as List)
          .map((e) => MapEntry(e['month'] as String, (e['spend'] as num).toDouble()))
          .toList(),
      mae: (info['mae'] as num).toDouble(),
      r2: (info['r2'] as num).toDouble(),
      features: (info['features'] as List).map((e) => e.toString()).toList(),
    );
  }
}
