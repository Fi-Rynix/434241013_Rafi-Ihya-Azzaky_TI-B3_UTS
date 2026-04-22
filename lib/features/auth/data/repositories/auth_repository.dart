import '../models/user_model.dart';

class AuthRepository {
  // Predefined users
  static final List<User> _users = [
    User(username: 'user1', password: 'password', role: 'user'),
    User(username: 'user2', password: 'password', role: 'user'),
    User(username: 'admin', password: 'admin123', role: 'admin'),
  ];

  /// Login dengan username dan password
  /// Returns User jika login berhasil, null jika gagal
  Future<User?> login(String username, String password) async {
    // Simulasi delay network
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      return user;
    } catch (e) {
      return null; // Login gagal
    }
  }

  /// Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
