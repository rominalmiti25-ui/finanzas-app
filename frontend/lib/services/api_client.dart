import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final List<String> details;
  ApiException(this.message, {this.status, this.details = const []});
  @override
  String toString() => details.isEmpty ? message : '$message\n• ${details.join('\n• ')}';
}

/// Cliente HTTP del backend. El token JWT se adjunta automáticamente.
class ApiClient {
  String? token;
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body: body);
  Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path) => _send('PATCH', path);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final uri = Uri.parse('$kApiUrl$path').replace(queryParameters: query);
    final req = http.Request(method, uri);
    req.headers['Content-Type'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 25));
      final res = await http.Response.fromStream(streamed);
      dynamic data;
      if (res.body.isNotEmpty) {
        try { data = jsonDecode(utf8.decode(res.bodyBytes)); } catch (_) { data = null; }
      }
      if (res.statusCode >= 400) {
        if (res.statusCode == 401 && token != null) onUnauthorized?.call();
        final msg = (data is Map && data['error'] != null) ? data['error'].toString() : 'Error ${res.statusCode}';
        final details = (data is Map && data['details'] is List)
            ? (data['details'] as List).map((d) => '${d['message']}').toList()
            : <String>[];
        throw ApiException(msg, status: res.statusCode, details: details);
      }
      return data;
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder.');
    } on SocketException {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    } on http.ClientException {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }
}
