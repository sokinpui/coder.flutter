import 'dart:typed_data';

import 'clipboard_service_io.dart';

abstract class ClipboardService {
  Future<Uint8List?> getClipboardImage();
  Future<Uint8List?> pickImage();
  Future<List<Uint8List>> pickImages();
  Future<String?> pickFilePath();
  Future<List<String>> pickFilePaths();

  static ClipboardService create() => createClipboardService();
}
