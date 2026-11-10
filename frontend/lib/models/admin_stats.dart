class AdminStats {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> budgetRanges;
  final List<Map<String, dynamic>> monthly;
  final List<Map<String, dynamic>> clients;
  final Map<String, dynamic>? spendingModel;
  final Map<String, dynamic>? classifierModel;

  AdminStats({required this.summary, required this.categories, required this.budgetRanges,
      required this.monthly, required this.clients, this.spendingModel, this.classifierModel});

  static List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    final ml = (j['ml'] ?? {}) as Map<String, dynamic>;
    return AdminStats(
      summary: Map<String, dynamic>.from(j['summary'] as Map),
      categories: _list(j['categoryDistribution']),
      budgetRanges: _list(j['budgetRanges']),
      monthly: _list(j['monthlyActivity']),
      clients: _list(j['clientsTable']),
      spendingModel: ml['spending'] == null ? null : Map<String, dynamic>.from(ml['spending'] as Map),
      classifierModel: ml['classifier'] == null ? null : Map<String, dynamic>.from(ml['classifier'] as Map),
    );
  }
}
