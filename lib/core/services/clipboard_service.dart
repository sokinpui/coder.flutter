import 'dart:async';
import 'dart:typed_data';

import 'clipboard_service_stub.dart'
    if (dart.library.io) 'clipboard_service_io.dart'
    if (dart.library.html) 'clipboard_service_html.dart';

abstract class ClipboardService {
  Stream<Uint8List> get onImagePasted;
  Future<Uint8List?> getClipboardImage();
  Future<Uint8List?> pickImage();

  static ClipboardService create() => createClipboardService();
}
