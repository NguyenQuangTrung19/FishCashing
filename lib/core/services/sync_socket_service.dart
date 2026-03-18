/// WebSocket service for realtime sync notifications.
///
/// Connects to backend Socket.IO `/sync` namespace.
/// Emits [onSyncUpdated] stream when another device pushes data,
/// so this device can auto-pull.
/// Also supports auto-push: call [notifyLocalChange] after local writes.
library;

import 'dart:async';
import 'dart:developer' as dev;

import 'package:socket_io_client/socket_io_client.dart' as io;

class SyncSocketService {
  io.Socket? _socket;
  Timer? _autoPushTimer;

  final _syncUpdatedController = StreamController<void>.broadcast();
  final _localChangeController = StreamController<void>.broadcast();

  /// Stream that emits when another device pushed data (server broadcast).
  /// Listen to this → trigger pull.
  Stream<void> get onSyncUpdated => _syncUpdatedController.stream;

  /// Stream that emits (debounced) when local data changed.
  /// Listen to this → trigger push.
  Stream<void> get onLocalChange => _localChangeController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to the backend WebSocket server.
  void connect(String serverUrl, String token) {
    disconnect(); // Clean up any existing connection

    final wsUrl = serverUrl.replaceAll('/api', ''); // base URL

    dev.log('[SyncSocket] Connecting to $wsUrl/sync ...');

    _socket = io.io(
      '$wsUrl/sync',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(3000)
          .setReconnectionAttempts(double.infinity.toInt())
          .build(),
    );

    _socket!
      ..onConnect((_) {
        dev.log('[SyncSocket] ✅ Connected');
      })
      ..onDisconnect((_) {
        dev.log('[SyncSocket] ❌ Disconnected');
      })
      ..onReconnect((_) {
        dev.log('[SyncSocket] 🔄 Reconnected');
        // After reconnect, pull latest changes
        _syncUpdatedController.add(null);
      })
      ..onConnectError((err) {
        dev.log('[SyncSocket] ⚠️ Connection error: $err');
      })
      ..on('sync:updated', (data) {
        dev.log('[SyncSocket] 📥 Received sync:updated — pulling...');
        _syncUpdatedController.add(null);
      })
      ..on('sync:pong', (data) {
        dev.log('[SyncSocket] 🏓 Pong: $data');
      });
  }

  /// Notify that local data changed — debounce and emit for auto-push.
  /// Call this after any create/update/delete operation.
  void notifyLocalChange() {
    // Debounce: wait 2 seconds after last change before pushing
    _autoPushTimer?.cancel();
    _autoPushTimer = Timer(const Duration(seconds: 2), () {
      dev.log('[SyncSocket] 📤 Local changes detected — pushing...');
      _localChangeController.add(null);
    });
  }

  /// Send a ping to verify connection.
  void ping() {
    _socket?.emit('sync:ping');
  }

  /// Disconnect from WebSocket server.
  void disconnect() {
    _autoPushTimer?.cancel();
    _socket?.dispose();
    _socket = null;
  }

  /// Clean up resources.
  void dispose() {
    disconnect();
    _syncUpdatedController.close();
    _localChangeController.close();
  }
}
