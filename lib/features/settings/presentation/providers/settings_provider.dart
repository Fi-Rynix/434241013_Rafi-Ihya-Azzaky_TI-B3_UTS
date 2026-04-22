import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Provider untuk settings (dengan family parameter: username, email, role)
final userSettingsProvider = FutureProvider.family<UserSettings, ({String username, String email, String role})>((ref, params) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return await settingsRepo.getSettings(params.username, params.email, params.role);
});

// Provider untuk dark mode state
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref.watch(settingsRepositoryProvider));
});

class DarkModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  DarkModeNotifier(this._repository) : super(false);

  Future<void> toggleDarkMode() async {
    state = !state;
    await _repository.setDarkMode(state);
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    state = isDarkMode;
    await _repository.setDarkMode(isDarkMode);
  }
}

// Provider untuk language state
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(settingsRepositoryProvider));
});

class LanguageNotifier extends StateNotifier<String> {
  final SettingsRepository _repository;

  LanguageNotifier(this._repository) : super('en');

  Future<void> setLanguage(String language) async {
    state = language;
    await _repository.setLanguage(language);
  }
}

// Provider untuk notifications enabled state
final notificationsEnabledProvider = StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  return NotificationsEnabledNotifier(ref.watch(settingsRepositoryProvider));
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  NotificationsEnabledNotifier(this._repository) : super(true);

  Future<void> toggleNotifications() async {
    state = !state;
    await _repository.setNotificationsEnabled(state);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = enabled;
    await _repository.setNotificationsEnabled(enabled);
  }
}

// Provider untuk sound enabled state
final soundEnabledProvider = StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  return SoundEnabledNotifier(ref.watch(settingsRepositoryProvider));
});

class SoundEnabledNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  SoundEnabledNotifier(this._repository) : super(true);

  Future<void> toggleSound() async {
    state = !state;
    await _repository.setSoundEnabled(state);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = enabled;
    await _repository.setSoundEnabled(enabled);
  }
}

// Provider untuk reset settings
final resetSettingsProvider = FutureProvider((ref) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  await settingsRepo.resetSettings();
  // Reset all state notifiers to defaults
  ref.read(darkModeProvider.notifier).setDarkMode(false);
  ref.read(languageProvider.notifier).setLanguage('en');
  ref.read(notificationsEnabledProvider.notifier).setNotificationsEnabled(true);
  ref.read(soundEnabledProvider.notifier).setSoundEnabled(true);
});
