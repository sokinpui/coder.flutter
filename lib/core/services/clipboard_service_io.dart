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
  Future<List<Uint8List>> pickImages() async {
    if (Platform.isAndroid) {
      try {
        final list = await _androidPickerChannel.invokeListMethod<dynamic>(
          'pickImages',
        );
        return list?.whereType<Uint8List>().toList() ?? [];
      } catch (_) {
        return [];
      }
    }
    if (Platform.isMacOS) {
      try {
        final list = await _macClipboardChannel.invokeListMethod<dynamic>(
          'pickImages',
        );
        return list?.whereType<Uint8List>().toList() ?? [];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<List<String>> pickFilePaths() async {
    if (Platform.isAndroid) {
      try {
        final list = await _androidPickerChannel.invokeListMethod<dynamic>(
          'pickFiles',
        );
        return list?.whereType<String>().toList() ?? [];
      } catch (_) {
        return [];
      }
    }
    if (Platform.isMacOS) {
      try {
        final list = await _macClipboardChannel.invokeListMethod<dynamic>(
          'pickFiles',
        );
        return list?.whereType<String>().toList() ?? [];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<Uint8List?> pickImage() async {
    final images = await pickImages();
    return images.isEmpty ? null : images.first;
  }

  @override
  Future<String?> pickFilePath() async {
    final paths = await pickFilePaths();
    return paths.isEmpty ? null : paths.first;
  }
}
