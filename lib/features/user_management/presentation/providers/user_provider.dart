import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// All users provider
final allUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAllUsers();
});

/// Users by role provider
final usersByRoleProvider =
    FutureProvider.family<List<AppUser>, String>((ref, role) async {
  final repo = ref.watch(userRepositoryProvider);
  if (role == 'all') return repo.getAllUsers();
  return repo.getUsersByRole(role);
});

/// Search users provider
final searchUsersProvider =
    FutureProvider.family<List<AppUser>, String>((ref, query) async {
  final repo = ref.watch(userRepositoryProvider);
  if (query.isEmpty) return repo.getAllUsers();
  return repo.searchUsers(query);
});

/// Update user provider
final updateUserProvider =
    FutureProvider.family<AppUser?, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(userRepositoryProvider);
  final updated = await repo.updateUser(
    idUser: params['idUser'] as int,
    username: params['username'] as String?,
    role: params['role'] as String?,
    isActive: params['isActive'] as bool?,
  );
  // Refresh all user providers
  ref.invalidate(allUsersProvider);
  ref.invalidate(usersByRoleProvider);
  return updated;
});

/// Toggle active provider
final toggleUserActiveProvider =
    FutureProvider.family<AppUser?, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(userRepositoryProvider);
  final updated = await repo.toggleUserActive(
    params['idUser'] as int,
    params['isActive'] as bool,
  );
  ref.invalidate(allUsersProvider);
  ref.invalidate(usersByRoleProvider);
  return updated;
});

/// Add user provider (creates auth account + profile with custom role)
class NewUserData {
  final String email;
  final String password;
  final String username;
  final String role;
  NewUserData({required this.email, required this.password, required this.username, required this.role});
}

final addUserProvider =
    FutureProvider.family<AppUser?, NewUserData>((ref, data) async {
  final supabase = Supabase.instance.client;
  try {
    // 1) Create auth user
    final authRes = await supabase.auth.signUp(
      email: data.email,
      password: data.password,
      data: {'username': data.username},
    );
    final authUser = authRes.user;
    if (authUser == null) return null;

    // 2) Wait for trigger to create public.users row, then read it
    AppUser? profile;
    for (int i = 0; i < 5; i++) {
      final r = await supabase
          .from('users')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();
      if (r != null) {
        profile = AppUser.fromJson(r);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (profile == null) return null;

    // 3) Update role if not 'user' default
    if (data.role != profile.role) {
      final updateRes = await supabase
          .from('users')
          .update({'role': data.role})
          .eq('id_user', profile.idUser)
          .select()
          .maybeSingle();
      if (updateRes != null) {
        profile = AppUser.fromJson(updateRes);
      }
    }

    ref.invalidate(allUsersProvider);
    ref.invalidate(usersByRoleProvider);
    return profile;
  } catch (e) {
    print('Add user error: $e');
    rethrow;
  }
});