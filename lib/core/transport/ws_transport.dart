import 'ws_transport_stub.dart'
    if (dart.library.io) 'ws_transport_io.dart'
    if (dart.library.html) 'ws_transport_html.dart';

abstract class WsTransport {
  Stream<String> get stream;
  bool get isConnected;

  Future<void> connect(String url);
  void send(String data);
  Future<void> close();

  static WsTransport create() => createTransport();
}
