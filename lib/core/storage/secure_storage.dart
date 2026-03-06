import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static SecureStorage? _instance;
  final FlutterSecureStorage _storage;

  SecureStorage._()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  factory SecureStorage() => _instance ??= SecureStorage._();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyDeviceId = 'device_id';
  static const _keyUnlockCode = 'unlock_code';

  Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);
  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> saveUserId(String id) => _storage.write(key: _keyUserId, value: id);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> saveUserRole(String role) => _storage.write(key: _keyUserRole, value: role);
  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  Future<void> saveDeviceId(String id) => _storage.write(key: _keyDeviceId, value: id);
  Future<String?> getDeviceId() => _storage.read(key: _keyDeviceId);

  Future<void> saveUnlockCode(String code) => _storage.write(key: _keyUnlockCode, value: code);
  Future<String?> getUnlockCode() => _storage.read(key: _keyUnlockCode);

  Future<void> clearAll() => _storage.deleteAll();
}
