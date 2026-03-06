import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_endpoints.dart';

typedef SocketEventCallback = void Function(dynamic data);

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  final Map<String, List<SocketEventCallback>> _listeners = {};
  bool _isConnected = false;

  SocketService._();
  factory SocketService() => _instance ??= SocketService._();

  bool get isConnected => _isConnected;

  void connect(String deviceId, String token) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _socket!.emit(SocketEvents.joinDevice, {'device_id': deviceId});
      _notifyListeners(SocketEvents.connected, null);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _notifyListeners(SocketEvents.disconnected, null);
    });

    _setupEventListeners();
    _socket!.connect();
  }

  void _setupEventListeners() {
    for (final event in [
      SocketEvents.deviceLocked,
      SocketEvents.deviceUnlocked,
      SocketEvents.paymentReceived,
      SocketEvents.emiStatusUpdated,
      SocketEvents.policyPushed,
    ]) {
      _socket!.on(event, (data) => _notifyListeners(event, data));
    }
  }

  void on(String event, SocketEventCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, [SocketEventCallback? callback]) {
    if (callback == null) {
      _listeners.remove(event);
    } else {
      _listeners[event]?.remove(callback);
    }
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void _notifyListeners(String event, dynamic data) {
    for (final cb in _listeners[event] ?? []) {
      cb(data);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _listeners.clear();
  }

  void sendHeartbeat(String deviceId) {
    emit(SocketEvents.deviceHeartbeat, {
      'device_id': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
