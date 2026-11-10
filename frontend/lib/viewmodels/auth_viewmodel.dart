import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiClient api;
  AppUser? user;
  bool initialized = false;
  bool loading = false;
  String? error;

  AuthViewModel(this.api) {
    api.onUnauthorized = () { _clearSession(); notifyListeners(); };
  }

  // ---------- Validaciones de entrada (VistaModelo) ----------
  String? validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 2) return 'Mínimo 2 caracteres';
    return null;
  }

  String? validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El correo es obligatorio';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Correo inválido';
    return null;
  }

  String? validateLoginPassword(String? v) => (v == null || v.isEmpty) ? 'La contraseña es obligatoria' : null;

  String? validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Debe incluir al menos una letra';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe incluir al menos un número';
    return null;
  }

  String? validateAge(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Ingresa una edad válida (número entero)';
    if (n < 13 || n > 120) return 'La edad debe estar entre 13 y 120';
    return null;
  }

  String? validateMoney(String? v, {String label = 'El monto'}) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return '$label debe ser un número';
    if (n < 0) return '$label no puede ser negativo';
    if (n > 10000000) return '$label es demasiado alto';
    return null;
  }

  // ---------- Sesión ----------
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('token');
    if (t != null) {
      api.token = t;
      try {
        final res = await api.get('/api/auth/me');
        user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      } catch (_) {
        await _clearSession();
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) => _auth('/api/auth/login', {'email': email.trim(), 'password': password});

  Future<bool> register({required String name, required String email, required String password,
      required int age, required double income, required double budget}) =>
      _auth('/api/auth/register', {
        'name': name.trim(), 'email': email.trim(), 'password': password,
        'age': age, 'monthly_income': income, 'monthly_budget': budget,
      });

  Future<bool> _auth(String path, Map<String, dynamic> body) async {
    loading = true; error = null; notifyListeners();
    try {
      final res = await api.post(path, body);
      api.token = res['token'] as String;
      user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', api.token!);
      return true;
    } on ApiException catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    api.token = null; user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> logout() async { await _clearSession(); notifyListeners(); }
  void clearError() { error = null; }
}
