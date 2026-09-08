import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'settings_service.dart';

SettingsService createSettingsService() => IoSettingsService();

class IoSettingsService implements SettingsService {
  static const MethodChannel _androidSettingsChannel = MethodChannel(
    'coder_flutter/settings',
  );

  File? _resolveFile() {
    if (Platform.isAndroid) {
      return null;
    }
    try {
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'];
      if (home != null && home.isNotEmpty) {
        final dir = Directory('$home/.config/coder_flutter');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/settings.json');
      }
      final fallbackDir = Directory('.coder');
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      return File('.coder/gui_settings.json');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    if (Platform.isAndroid) {
      try {
        final raw = await _androidSettingsChannel.invokeMethod<String>(
          'loadSettings',
        );
        if (raw == null || raw.isEmpty) {
          return {};
        }
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
      return {};
    }
    try {
      final file = _resolveFile();
      if (file == null || !await file.exists()) {
        return {};
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (Platform.isAndroid) {
      try {
        await _androidSettingsChannel.invokeMethod('saveSettings', {
          'settings': jsonEncode(settings),
        });
      } catch (_) {}
      return;
    }
    try {
      final file = _resolveFile();
      if (file == null) {
        return;
      }
      await file.writeAsString(jsonEncode(settings));
    } catch (_) {}
  }
}
