import 'dart:async';
import 'dart:convert';

import '../transport/ws_transport.dart';

typedef NotificationCallback = void Function(String method, dynamic params);

class CoderRpcClient {
  CoderRpcClient() : _transport = WsTransport.create();

  final WsTransport _transport;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  NotificationCallback? onNotification;
  int _requestId = 0;
  StreamSubscription? _subscription;

  bool get isConnected => _transport.isConnected;

  Future<void> connect(String serverUrl) async {
    await _subscription?.cancel();
    await _transport.connect(serverUrl);
    _subscription = _transport.stream.listen(_handleIncomingMessage);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _transport.close();
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Connection closed');
      }
    }
    _pendingRequests.clear();
  }

  Future<dynamic> request(String method, [Map<String, dynamic>? params]) {
    if (!isConnected) {
      return Future.error('Not connected to Coder server');
    }

    final id = ++_requestId;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
    };
    if (params != null) {
      payload['params'] = params;
    }

    _transport.send(jsonEncode(payload));
    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Request $method timed out');
      },
    );
  }

  void _handleIncomingMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _processSingleMessage(item);
          }
        }
        return;
      }
      if (decoded is Map<String, dynamic>) {
        _processSingleMessage(decoded);
      }
    } catch (_) {}
  }

  void _processSingleMessage(Map<String, dynamic> msg) {
    if (msg.containsKey('id') && msg['id'] != null) {
      final id = msg['id'] as int?;
      if (id == null) {
        return;
      }
      final completer = _pendingRequests.remove(id);
      if (completer == null || completer.isCompleted) {
        return;
      }

      if (msg.containsKey('error') && msg['error'] != null) {
        final err = msg['error'];
        final message = err is Map ? err['message'] ?? 'RPC Error' : err.toString();
        completer.completeError(message);
        return;
      }

      completer.complete(msg['result']);
      return;
    }

    if (msg.containsKey('method')) {
      final method = msg['method'] as String;
      final params = msg['params'];
      onNotification?.call(method, params);
    }
  }
}
