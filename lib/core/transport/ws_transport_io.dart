import 'dart:async';
import 'dart:io';

import 'ws_transport.dart';

WsTransport createTransport() => IOWsTransport();

class IOWsTransport implements WsTransport {
  WebSocket? _socket;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  @override
  Stream<String> get stream => _controller.stream;

  @override
  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  @override
  Future<void> connect(String url) async {
    await close();
    _socket = await WebSocket.connect(url);
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
      },
      onDone: () {},
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
  Future<void> close() async {
    if (_socket == null) {
      return;
    }
    await _socket!.close();
    _socket = null;
  }
}
