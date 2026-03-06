import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );

  bool get isAdmin => user?.isAdmin ?? false;
  bool get isAgent => user?.isAgent ?? false;
  bool get isCustomer => user?.isCustomer ?? false;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthRepository _repo;

  @override
  Future<AuthState> build() async {
    _repo = ref.read(authRepositoryProvider);
    final user = await _repo.getCurrentUser();
    return AuthState(
      user: user,
      isLoggedIn: user != null && _repo.isLoggedIn,
    );
  }

  Future<bool> login({
    required String username,
    required String password,
    required String role,
  }) async {
    state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: true, error: null));
    try {
      final auth = await _repo.login(username: username, password: password, role: role);
      state = AsyncData(AuthState(user: auth.user, isLoggedIn: true));
      return true;
    } catch (e) {
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(AuthState(isLoggedIn: false));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value?.user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value?.isLoggedIn ?? false;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});
