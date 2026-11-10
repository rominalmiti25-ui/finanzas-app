import 'package:flutter/foundation.dart';
import '../models/prediction.dart';
import '../services/api_client.dart';

class PredictionViewModel extends ChangeNotifier {
  final ApiClient api;
  PredictionViewModel(this.api);

  Prediction? prediction;
  bool loading = false;
  String? error;

  Future<void> load({bool reset = false}) async {
    if (reset) prediction = null;
    loading = true; error = null; notifyListeners();
    try {
      final res = await api.get('/api/ml/prediction');
      prediction = Prediction.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }
}
