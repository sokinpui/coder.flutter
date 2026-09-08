// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'settings_service.dart';

SettingsService createSettingsService() => HtmlSettingsService();

class HtmlSettingsService implements SettingsService {
  static const String _storageKey = 'coder_flutter_settings';

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      html.window.localStorage[_storageKey] = jsonEncode(settings);
    } catch (_) {}
  }
}
