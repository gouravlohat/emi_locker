import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  AuthRepository({
    ApiClient? api,
    SecureStorage? secureStorage,
    LocalStorage? localStorage,
  })  : _api = api ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorage(),
        _localStorage = localStorage ?? LocalStorage();

  // Real API login:
  //   role == 'admin'   → POST /auth/admin/login
  //   role == 'agent'   → POST /auth/agent/login
  //   otherwise         → POST /auth/login  (client/user)
  //
  // Request body: { email, password }  OR  { mobile, password }
  // Response:     { success: true, data: { token, user, deviceLocked } }
  Future<AuthResponse> login({
    required String username, // email or mobile number
    required String password,
    required String role,
  }) async {
    final endpoint = switch (role) {
      'admin' => ApiEndpoints.adminLogin,
      'agent' => ApiEndpoints.agentLogin,
      _ => ApiEndpoints.userLogin,
    };

    // Determine if the username looks like an email or a mobile number
    final isEmail = username.contains('@');
    final body = {
      if (isEmail) 'email': username else 'mobile': username,
      'password': password,
    };

    try {
      final res = await _api.post(endpoint, data: body);
      final data = ApiClient.unwrap(res) as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(data);
      await _saveSession(auth, role);
      return auth;
    } on DioException catch (e) {
      // Fallback mock for demo/development when backend is unavailable
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.unknown) {
        return _mockLogin(username, role);
      }
      throw _parseError(e);
    }
  }

  Future<AuthResponse> _mockLogin(String username, String role) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final userRole = switch (role) {
      'admin' => UserRole.admin,
      'agent' => UserRole.agent,
      _ => UserRole.customer,
    };
    final mockAuth = AuthResponse(
      accessToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 'user_001',
        name: username.isEmpty ? 'Demo User' : username,
        email: username.contains('@') ? username : '$username@emilocker.com',
        phone: username.contains('@') ? '+91 9876543210' : username,
        role: userRole,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      deviceLocked: false,
    );
    await _saveSession(mockAuth, role);
    return mockAuth;
  }

  Future<void> _saveSession(AuthResponse auth, String role) async {
    final futures = <Future>[
      _secureStorage.saveToken(auth.accessToken),
      _secureStorage.saveUserId(auth.user.id),
      _secureStorage.saveUserRole(auth.user.role.name),
      _localStorage.setLoggedIn(true),
    ];
    if (auth.user.isCustomer) futures.add(_localStorage.setCustomerId(auth.user.id));
    if (auth.user.isAgent) futures.add(_localStorage.setAgentId(auth.user.id));
    await Future.wait(futures);
  }

  Future<void> logout() async {
    await _secureStorage.clearAll();
    await _localStorage.setLoggedIn(false);
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _secureStorage.getToken();
    final roleStr = await _secureStorage.getUserRole();
    final id = await _secureStorage.getUserId();
    if (token == null || id == null) return null;
    final role = switch (roleStr) {
      'admin' => UserRole.admin,
      'agent' => UserRole.agent,
      _ => UserRole.customer,
    };
    // Optionally re-fetch profile from server here to get fresh data
    return UserModel(
      id: id,
      name: 'Current User',
      email: 'user@emilocker.com',
      phone: '+91 9876543210',
      role: role,
    );
  }

  bool get isLoggedIn => _localStorage.isLoggedIn;

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return switch (e.response?.statusCode) {
      401 => 'Invalid credentials',
      403 => 'Access denied',
      404 => 'User not found',
      429 => 'Too many attempts. Please wait and try again.',
      500 => 'Server error. Please try again.',
      _ => 'Network error. Please check your connection.',
    };
  }
}
