import 'package:flutter/foundation.dart';
import '../models/admin_stats.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';

class AdminViewModel extends ChangeNotifier {
  final ApiClient api;
  AdminViewModel(this.api);

  AdminStats? stats;
  List<AppUser> users = [];
  bool loading = false;
  String? error;

  Future<void> loadStats({bool reset = false}) async {
    if (reset) stats = null;
    loading = true; error = null; notifyListeners();
    try {
      final res = await api.get('/api/admin/stats');
      stats = AdminStats.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> loadUsers({bool reset = false}) async {
    if (reset) users = [];
    loading = true; error = null; notifyListeners();
    try {
      final res = await api.get('/api/users');
      users = (res['users'] as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<String?> promote(int id) async {
    try {
      await api.patch('/api/users/$id/promote');
      await loadUsers();
      return null;
    } on ApiException catch (e) {
      return e.toString();
    }
  }

  /// Reentrena los modelos de ML con los datos actuales. Devuelve un mensaje para mostrar.
  Future<String> retrain() async {
    try {
      final res = await api.post('/api/admin/ml/train') as Map<String, dynamic>;
      await loadStats();
      if (res['spendingError'] != null) return 'Regresión: ${res['spendingError']}';
      return 'Modelos reentrenados correctamente';
    } on ApiException catch (e) {
      return e.toString();
    }
  }
}
