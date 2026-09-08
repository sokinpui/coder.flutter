// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'ws_transport.dart';

WsTransport createTransport() => HtmlWsTransport();

class HtmlWsTransport implements WsTransport {
  html.WebSocket? _socket;
  final StreamController<String> _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get stream => _controller.stream;

  @override
  bool get isConnected => _socket != null && _socket!.readyState == html.WebSocket.OPEN;

  @override
  Future<void> connect(String url) async {
    await close();
    final completer = Completer<void>();
    final ws = html.WebSocket(url);
    _socket = ws;

    ws.onOpen.listen((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    ws.onError.listen((error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      _controller.addError(error);
    });

    ws.onMessage.listen((event) {
      if (event.data is String) {
        _controller.add(event.data as String);
      }
    });

    return completer.future;
  }

  @override
  void send(String data) {
    if (_socket == null || _socket!.readyState != html.WebSocket.OPEN) {
      return;
    }
    _socket!.send(data);
  }

  @override
  Future<void> close() async {
    if (_socket == null) {
      return;
    }
    _socket!.close();
    _socket = null;
  }
}
