import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coder_flutter/core/widgets/app_icon_widget.dart';

Future<Uint8List> _renderIconBytes(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const painter = AppIconPainter();
  painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void _saveIcon(String path, Uint8List bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void main() {
  test('Generate app launcher icons across all platforms', () async {
    final targets = <String, int>{
      'assets/icon/app_icon.png': 1024,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/favicon.png': 64,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };

    final cache = <int, Uint8List>{};
    for (final entry in targets.entries) {
      final size = entry.value;
      final bytes = cache[size] ?? await _renderIconBytes(size);
      cache[size] = bytes;
      _saveIcon(entry.key, bytes);
    }
  });
}
