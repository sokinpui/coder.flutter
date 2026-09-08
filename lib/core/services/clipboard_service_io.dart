import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'clipboard_service.dart';

ClipboardService createClipboardService() => IoClipboardService();

class IoClipboardService implements ClipboardService {
  static const MethodChannel _macClipboardChannel = MethodChannel('coder_flutter/clipboard');
  static const MethodChannel _androidPickerChannel = MethodChannel('coder_flutter/picker');

  final StreamController<Uint8List> _imageStreamController = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get onImagePasted => _imageStreamController.stream;

  @override
  Future<Uint8List?> getClipboardImage() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final bytes = await _macClipboardChannel.invokeMethod<Uint8List>('getClipboardImage');
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> pickImage() async {
    if (Platform.isAndroid) {
      try {
        final bytes = await _androidPickerChannel.invokeMethod<Uint8List>('pickImage');
        return bytes;
      } catch (_) {
        return null;
      }
    }
    if (Platform.isMacOS) {
      try {
        final bytes = await _macClipboardChannel.invokeMethod<Uint8List>('pickImage');
        if (bytes != null) {
          return bytes;
        }
      } catch (_) {}
      return getClipboardImage();
    }
    return null;
  }
}
