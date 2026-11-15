import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class TransactionsViewModel extends ChangeNotifier {
  final ApiClient api;
  final RealtimeService rt;
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _debounce;

  TransactionsViewModel(this.api, this.rt) {
    // Tiempo real: si cambia un movimiento (desde este u otro dispositivo), se recarga la lista.
    _sub = rt.events.listen((e) {
      if (e.name.startsWith('transaction:')) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), () => load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  List<TransactionItem> items = [];
  bool loading = false;
  String? error;

  // ---------- Validaciones ----------
  String? validateAmount(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Ingresa un monto numérico';
    if (n <= 0) return 'El monto debe ser mayor a 0';
    if (n > 10000000) return 'Monto demasiado alto';
    if (((n * 100) - (n * 100).round()).abs() > 1e-6) return 'Máximo 2 decimales';
    return null;
  }

  String? validateCategory(String? v, String type) =>
      (type == 'gasto' && (v == null || v.isEmpty)) ? 'Selecciona una categoría' : null;

  String? validateDescription(String? v) => (v ?? '').length > 200 ? 'Máximo 200 caracteres' : null;

  String? validateDate(String? v) {
    if (v == null || v.isEmpty) return 'Selecciona una fecha';
    final d = DateTime.tryParse(v);
    if (d == null) return 'Fecha inválida';
    if (d.isAfter(DateTime.now().add(const Duration(days: 1)))) return 'La fecha no puede estar en el futuro';
    return null;
  }

  // ---------- Operaciones ----------
  /// [silent] = recarga en segundo plano (tiempo real): sin spinner y sin mostrar errores.
  Future<void> load({bool reset = false, bool silent = false}) async {
    if (reset) items = [];
    if (!silent) { loading = true; error = null; notifyListeners(); }
    try {
      final res = await api.get('/api/transactions', query: {'limit': '500'});
      items = (res['items'] as List).map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      if (!silent) error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  /// Devuelve null si todo salió bien, o el mensaje de error.
  Future<String?> add({required String type, required double amount, String? category,
      required String description, required String date}) async {
    try {
      await api.post('/api/transactions', {
        'type': type, 'amount': amount, if (type == 'gasto') 'category': category,
        'description': description.trim(), 'tx_date': date,
      });
      await load();
      return null;
    } on ApiException catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove(int id) async {
    try {
      await api.delete('/api/transactions/$id');
      items.removeWhere((t) => t.id == id);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.toString();
    }
  }

  /// Sugerencia de categoría con el modelo de ML (Naive Bayes) del backend.
  Future<String?> suggestCategory(String description) async {
    try {
      final res = await api.post('/api/ml/categorize', {'description': description.trim()});
      return res['suggested'] as String;
    } on ApiException {
      return null;
    }
  }

  // ---------- Resumen del mes actual ----------
  String get _ym {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  double get monthExpenses => items.where((t) => t.isExpense && t.date.startsWith(_ym)).fold(0.0, (s, t) => s + t.amount);
  double get monthIncome => items.where((t) => !t.isExpense && t.date.startsWith(_ym)).fold(0.0, (s, t) => s + t.amount);

  Map<String, double> get monthByCategory {
    final m = <String, double>{};
    for (final t in items.where((t) => t.isExpense && t.date.startsWith(_ym))) {
      m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    return m;
  }
}
