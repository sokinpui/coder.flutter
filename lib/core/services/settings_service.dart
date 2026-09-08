import 'settings_service_stub.dart'
    if (dart.library.io) 'settings_service_io.dart'
    if (dart.library.html) 'settings_service_html.dart';

abstract class SettingsService {
  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);

  static SettingsService create() => createSettingsService();
}
