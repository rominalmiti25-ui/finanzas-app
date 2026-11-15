import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/prediction.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class PredictionViewModel extends ChangeNotifier {
  final ApiClient api;
  final RealtimeService rt;
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _debounce;

  PredictionViewModel(this.api, this.rt) {
    // Tiempo real: la predicción se recalcula cuando cambian los movimientos o se reentrena el modelo.
    _sub = rt.events.listen((e) {
      if (e.name.startsWith('transaction:') || e.name == 'ml:trained') {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 700), () => load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Prediction? prediction;
  bool loading = false;
  String? error;

  Future<void> load({bool reset = false, bool silent = false}) async {
    if (reset) prediction = null;
    if (!silent) { loading = true; error = null; notifyListeners(); }
    try {
      final res = await api.get('/api/ml/prediction');
      prediction = Prediction.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (!silent) error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }
}
