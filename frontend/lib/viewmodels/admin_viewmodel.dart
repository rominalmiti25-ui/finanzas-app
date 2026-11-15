import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_item.dart';
import '../models/admin_stats.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class AdminViewModel extends ChangeNotifier {
  final ApiClient api;
  final RealtimeService rt;
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _debounce;
  bool _refreshUsers = false;

  AdminViewModel(this.api, this.rt) {
    // Tiempo real: cada actividad de un cliente aparece en el feed y refresca estadísticas/usuarios.
    _sub = rt.events.listen((e) {
      if (e.name == 'admin:activity' && e.data is Map) {
        final item = ActivityItem.fromJson(Map<String, dynamic>.from(e.data as Map));
        feed.insert(0, item);
        if (feed.length > 15) feed.removeLast();
        notifyListeners();
        _scheduleRefresh(users: item.kind == 'user' || item.kind == 'promote');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  /// Agrupa ráfagas de eventos en una sola recarga (evita pedir las estadísticas en cada evento).
  void _scheduleRefresh({bool users = false}) {
    _refreshUsers = _refreshUsers || users;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      await loadStats(silent: true);
      if (_refreshUsers) { _refreshUsers = false; await loadUsers(silent: true); }
    });
  }

  AdminStats? stats;
  List<AppUser> users = [];
  final List<ActivityItem> feed = [];
  bool loading = false;
  String? error;

  Future<void> loadStats({bool reset = false, bool silent = false}) async {
    if (reset) { stats = null; feed.clear(); }
    if (!silent) { loading = true; error = null; notifyListeners(); }
    try {
      final res = await api.get('/api/admin/stats');
      stats = AdminStats.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (!silent) error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> loadUsers({bool reset = false, bool silent = false}) async {
    if (reset) users = [];
    if (!silent) { loading = true; error = null; notifyListeners(); }
    try {
      final res = await api.get('/api/users');
      users = (res['users'] as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      if (!silent) error = e.toString();
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
