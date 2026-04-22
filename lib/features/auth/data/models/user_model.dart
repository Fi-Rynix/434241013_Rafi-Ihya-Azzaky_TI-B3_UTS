class User {
  final String username;
  final String password;
  final String role; // "user" or "admin"

  User({
    required this.username,
    required this.password,
    required this.role,
  });
}
