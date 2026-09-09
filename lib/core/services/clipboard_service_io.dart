import 'dart:io';
import 'package:flutter/services.dart';

import 'clipboard_service.dart';

ClipboardService createClipboardService() => IoClipboardService();

class IoClipboardService implements ClipboardService {
  static const MethodChannel _macClipboardChannel = MethodChannel(
    'coder_flutter/clipboard',
  );
  static const MethodChannel _androidPickerChannel = MethodChannel(
    'coder_flutter/picker',
  );

  @override
  Future<Uint8List?> getClipboardImage() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final bytes = await _macClipboardChannel.invokeMethod<Uint8List>(
        'getClipboardImage',
      );
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> pickImage() async {
    if (Platform.isAndroid) {
      try {
        final bytes = await _androidPickerChannel.invokeMethod<Uint8List>(
          'pickImage',
        );
        return bytes;
      } catch (_) {
        return null;
      }
    }
    if (Platform.isMacOS) {
      try {
        return await _macClipboardChannel.invokeMethod<Uint8List>('pickImage');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> pickFilePath() async {
    if (Platform.isAndroid) {
      try {
        return await _androidPickerChannel.invokeMethod<String>('pickFile');
      } catch (_) {
        return null;
      }
    }
    if (Platform.isMacOS) {
      try {
        return await _macClipboardChannel.invokeMethod<String>('pickFile');
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
