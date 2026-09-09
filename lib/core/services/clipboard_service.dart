import 'dart:typed_data';

import 'clipboard_service_io.dart';

abstract class ClipboardService {
  Future<Uint8List?> getClipboardImage();
  Future<Uint8List?> pickImage();
  Future<String?> pickFilePath();

  static ClipboardService create() => createClipboardService();
}
