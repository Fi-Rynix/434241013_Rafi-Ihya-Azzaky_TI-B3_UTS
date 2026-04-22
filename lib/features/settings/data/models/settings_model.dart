class UserSettings {
  final String username;
  final String email;
  final String role;
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;

  UserSettings({
    required this.username,
    required this.email,
    required this.role,
    this.isDarkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
  });

  // CopyWith method untuk immutability
  UserSettings copyWith({
    String? username,
    String? email,
    String? role,
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
  }) {
    return UserSettings(
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
