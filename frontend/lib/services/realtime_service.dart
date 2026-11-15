import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../config/app_config.dart';

class RealtimeEvent {
  final String name;
  final dynamic data;
  RealtimeEvent(this.name, this.data);
}

/// Conexión de tiempo real (Socket.IO) con el backend.
/// Los ViewModels se suscriben a [events] y se actualizan cuando el servidor "empuja" un evento.
class RealtimeService {
  sio.Socket? _socket;
  final StreamController<RealtimeEvent> _controller = StreamController<RealtimeEvent>.broadcast();
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  Stream<RealtimeEvent> get events => _controller.stream;

  static const List<String> _eventNames = [
    'transaction:created', 'transaction:updated', 'transaction:deleted',
    'admin:activity', 'role:changed', 'ml:trained',
  ];

  /// Abre la conexión usando el mismo token JWT de la sesión.
  void connect(String token) {
    disconnect();
    final s = sio.io(
      kApiUrl,
      sio.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build(),
    );
    s.onConnect((_) => connected.value = true);
    s.onDisconnect((_) => connected.value = false);
    s.onConnectError((_) => connected.value = false);
    for (final name in _eventNames) {
      s.on(name, (data) => _controller.add(RealtimeEvent(name, data)));
    }
    s.connect(); // si se cae la red o el servidor, el cliente reintenta solo
    _socket = s;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    connected.value = false;
  }
}
