import 'package:intl/intl.dart';

/// Un evento del feed "Actividad en vivo" del administrador.
class ActivityItem {
  final String kind; // transaction | user | promote | ml
  final String text;
  final DateTime at;

  ActivityItem({required this.kind, required this.text, required this.at});

  static final NumberFormat _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  static String _txText(Map<String, dynamic> j, String name) {
    final isExpense = j['type'] == 'gasto';
    final what = isExpense ? 'gasto' : 'ingreso';
    final amount = _money.format((j['amount'] as num).toDouble());
    final cat = isExpense ? ' en ${j['category']}' : '';
    final verb = switch (j['action']) { 'updated' => 'editó un', 'deleted' => 'eliminó un', _ => 'registró un' };
    return '$name $verb $what de $amount$cat';
  }

  factory ActivityItem.fromJson(Map<String, dynamic> j) {
    final kind = (j['kind'] ?? '') as String;
    final name = (j['userName'] ?? 'Un usuario') as String;
    final text = switch (kind) {
      'transaction' => _txText(j, name),
      'user' => '$name se registró en la app',
      'promote' => '$name ahora es administrador',
      'ml' => 'Se reentrenaron los modelos de ML',
      _ => 'Actividad del sistema',
    };
    return ActivityItem(kind: kind, text: text, at: DateTime.tryParse((j['at'] ?? '') as String) ?? DateTime.now());
  }
}
