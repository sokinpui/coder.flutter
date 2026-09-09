import 'dart:async';
import 'dart:typed_data';

import 'clipboard_service_io.dart';

abstract class ClipboardService {
  Stream<Uint8List> get onImagePasted;
  Future<Uint8List?> getClipboardImage();
  Future<Uint8List?> pickImage();

  static ClipboardService create() => createClipboardService();
}
