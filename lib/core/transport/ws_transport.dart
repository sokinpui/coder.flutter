import 'ws_transport_io.dart';

abstract class WsTransport {
  Stream<String> get stream;
  bool get isConnected;

  Future<void> connect(String url);
  void send(String data);
  Future<void> close();

  static WsTransport create() => createTransport();
}
