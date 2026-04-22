import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  static const String _keyDarkMode = 'isDarkMode';
  static const String _keyLanguage = 'language';
  static const String _keyNotificationsEnabled = 'notificationsEnabled';
  static const String _keySoundEnabled = 'soundEnabled';

  /// Get user settings
  Future<UserSettings> getSettings(String username, String email, String role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();

    return UserSettings(
      username: username,
      email: email,
      role: role,
      isDarkMode: prefs.getBool(_keyDarkMode) ?? false,
      language: prefs.getString(_keyLanguage) ?? 'en',
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
    );
  }

  /// Update dark mode setting
  Future<void> setDarkMode(bool isDarkMode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDarkMode);
  }

  /// Update language setting
  Future<void> setLanguage(String language) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  /// Update notifications enabled setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Update sound enabled setting
  Future<void> setSoundEnabled(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  /// Reset all settings to default
  Future<void> resetSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyNotificationsEnabled);
    await prefs.remove(_keySoundEnabled);
  }
}
