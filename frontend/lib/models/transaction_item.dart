class TransactionItem {
  final int id;
  final String type; // 'gasto' | 'ingreso'
  final double amount;
  final String category;
  final String description;
  final String date; // AAAA-MM-DD

  TransactionItem({required this.id, required this.type, required this.amount,
      required this.category, required this.description, required this.date});

  bool get isExpense => type == 'gasto';

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
        id: j['id'] as int,
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        description: (j['description'] ?? '') as String,
        date: j['tx_date'] as String,
      );
}
