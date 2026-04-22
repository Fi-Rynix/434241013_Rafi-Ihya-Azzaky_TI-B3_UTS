import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

// Provider untuk track user yang sedang login
final currentUserProvider = StateProvider<User?>((ref) => null);

// Credentials class untuk login
class LoginCredentials {
  final String username;
  final String password;

  LoginCredentials(this.username, this.password);
}

// Provider untuk login
final loginProvider = FutureProvider.family<User?, LoginCredentials>((ref, credentials) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.login(credentials.username, credentials.password);

  if (user != null) {
    ref.read(currentUserProvider.notifier).state = user;
  }

  return user;
});

// Provider untuk logout
final logoutProvider = FutureProvider((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  await authRepo.logout();
  ref.read(currentUserProvider.notifier).state = null;
});

// Provider untuk check apakah user sudah login
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Provider untuk role user saat ini
final userRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});
