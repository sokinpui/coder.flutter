import 'settings_service_io.dart';

abstract class SettingsService {
  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);

  static SettingsService create() => createSettingsService();
}
