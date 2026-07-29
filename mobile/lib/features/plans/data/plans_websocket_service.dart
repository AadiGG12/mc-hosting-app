import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants.dart';

/// Riverpod signal provider — increments every time plans change.
///
/// Every WebSocket event increments the counter, guaranteeing unique values
/// so both [plansProvider] and [PlansScreen] react to every update,
/// even consecutive events of the same type (e.g., two "update" actions).
final planUpdateSignalProvider = StateProvider<int>((ref) => 0);

/// WebSocket service for receiving real-time plan updates.
///
/// When an admin creates/updates/deletes a plan on the backend,
/// this service updates [planUpdateSignalProvider], which triggers
/// auto-refresh in [plansProvider] and shows a notification in the UI.
class PlanWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  /// A reference to the Riverpod Ref so we can write to [planUpdateSignalProvider].
  Ref? _ref;

  bool _isConnected = false;
  bool _shouldReconnect = true;

  /// Initialize with a Riverpod Ref to update the signal provider.
  void init(Ref ref) {
    _ref = ref;
  }

  /// Connect to the backend WebSocket endpoint for real-time plan updates.
  Future<void> connect() async {
    _shouldReconnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      String wsUrl = Constants.backendUrl.replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://');
      wsUrl = '$wsUrl/ws/plans';

      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sendPing());

      _subscription = _channel!.stream.listen(
        (message) => _handleMessage(message.toString()),
        onError: (_) { _isConnected = false; _scheduleReconnect(); },
        onDone: () { _isConnected = false; _scheduleReconnect(); },
      );
    } catch (_) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(String message) {
    try {
      if (message == 'pong') return;
      final data = jsonDecode(message);
      if (data is! Map) return;

      final event = data['event']?.toString();

      if (event == 'plans_updated' || event == 'plans_refresh_all') {
        // Increment the counter — this triggers plansProvider invalidation
        // Every event gets a unique value so no updates are ever missed
        _ref?.read(planUpdateSignalProvider.notifier).update((count) => count + 1);
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _sendPing() {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add('ping');
      } catch (_) {
        _isConnected = false;
      }
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldReconnect && !_isConnected) {
        _doConnect();
      }
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}

/// Riverpod provider for the WebSocket service (singleton).
final planWebSocketServiceProvider = Provider<PlanWebSocketService>((ref) {
  final service = PlanWebSocketService();
  service.init(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});
