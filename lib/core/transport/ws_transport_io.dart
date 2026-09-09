import 'dart:async';
import 'dart:io';

import 'ws_transport.dart';

WsTransport createTransport() => IOWsTransport();

class IOWsTransport implements WsTransport {
  WebSocket? _socket;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  @override
  Stream<String> get stream => _controller.stream;

  @override
  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  @override
  Stream<void> get onDisconnected => _disconnectController.stream;

  @override
  Future<void> connect(String url) async {
    await close();
    _socket = await WebSocket.connect(url);
    _socket!.pingInterval = const Duration(seconds: 15);
    _socket!.listen(
      (data) {
        if (data is String) {
          _controller.add(data);
          return;
        }
        if (data is List<int>) {
          _controller.add(String.fromCharCodes(data));
        }
      },
      onError: (error) {
        _controller.addError(error);
        close(notifyDisconnect: true);
      },
      onDone: () {
        close(notifyDisconnect: true);
      },
      cancelOnError: false,
    );
  }

  @override
  void send(String data) {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      return;
    }
    _socket!.add(data);
  }

  @override
  Future<void> close({bool notifyDisconnect = false}) async {
    if (_socket == null) {
      return;
    }
    await _socket!.close();
    _socket = null;
    if (notifyDisconnect) {
      _disconnectController.add(null);
    }
  }
}
