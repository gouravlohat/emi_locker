import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final ApiClient _api;
  final LocalStorage _localStorage;

  DeviceRepository({ApiClient? api, LocalStorage? localStorage})
      : _api = api ?? ApiClient(),
        _localStorage = localStorage ?? LocalStorage();

  // GET /device-lock/me  (client — uses JWT to identify the user)
  // Returns: { deviceLocked, hasPendingLockRequest }
  Future<DeviceModel> getDeviceStatus(String deviceId) async {
    try {
      final res = await _api.get(ApiEndpoints.deviceLockStatus);
      final data = ApiClient.unwrap(res) as Map<String, dynamic>;
      final locked = data['deviceLocked'] as bool? ?? false;
      await _localStorage.setDeviceLocked(locked);
      return _mockDevice(deviceId, locked: locked);
    } on DioException {
      return _mockDevice(deviceId);
    }
  }

  // POST /device-lock/devices/:userId/lock  (admin only)
  // Body: optional reason string
  Future<DeviceModel> lockDevice(String userId, {String? reason}) async {
    try {
      await _api.post(
        ApiEndpoints.lockUserDevice(userId),
        data: reason != null ? {'reason': reason} : {},
      );
      await _localStorage.setDeviceLocked(true);
      return _mockDevice(userId, locked: true);
    } on DioException {
      await _localStorage.setDeviceLocked(true);
      return _mockDevice(userId, locked: true);
    }
  }

  // POST /device-lock/devices/:userId/unlock  (admin only)
  Future<DeviceModel> unlockDevice(String userId) async {
    try {
      await _api.post(ApiEndpoints.unlockUserDevice(userId));
      await _localStorage.setDeviceLocked(false);
      return _mockDevice(userId, locked: false);
    } on DioException {
      await _localStorage.setDeviceLocked(false);
      return _mockDevice(userId, locked: false);
    }
  }

  // POST /device-lock/devices/:userId/extend-payment  (admin only)
  // Body: { emiPaymentId, extendDays, reason }
  Future<void> extendPayment(
    String userId, {
    required String emiPaymentId,
    required int extendDays,
    String? reason,
  }) async {
    await _api.post(
      ApiEndpoints.extendPayment(userId),
      data: {
        'emiPaymentId': emiPaymentId,
        'extendDays': extendDays,
        if (reason != null) 'reason': reason,
      },
    );
  }

  // GET /device-lock/overdue-users?page=1&limit=10  (admin only)
  // Returns paginated list of users with overdue EMIs
  Future<List<Map<String, dynamic>>> getOverdueUsers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await _api.get(
        ApiEndpoints.overdueUsers,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = ApiClient.unwrap(res);
      if (data is Map && data['users'] != null) {
        return List<Map<String, dynamic>>.from(data['users'] as List);
      }
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } on DioException {
      return [];
    }
  }

  // GET /users  (admin only) — list all registered users
  Future<List<DeviceModel>> getAllDevices() async {
    try {
      final res = await _api.get(ApiEndpoints.users);
      final data = ApiClient.unwrap(res);
      final list = (data is Map ? data['users'] : data) as List<dynamic>? ?? [];
      return list
          .map((e) => _deviceFromUserJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return List.generate(8, (i) => _mockDevice('dev_00${i + 1}', locked: i % 3 == 0));
    }
  }

  // The real API has no device enrollment endpoint.
  // Enrollment = admin creates the user account; the device registers itself
  // by logging in and posting its FCM token.
  // This method marks enrollment locally and stores the device ID.
  Future<DeviceModel> enrollDevice(Map<String, dynamic> enrollmentData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final deviceId = enrollmentData['imei']?.toString() ??
        'dev_${DateTime.now().millisecondsSinceEpoch}';
    await _localStorage.setEnrolled(true);
    return _mockDevice(deviceId);
  }

  // POST /users/fcm-token  (client only)
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _api.post(
        ApiEndpoints.registerFcmToken,
        data: {'fcmToken': fcmToken},
      );
    } on DioException {
      // Non-fatal — FCM registration failure is silent
    }
  }

  // Kiosk mode is device-local; no server endpoint exists in the real API.
  Future<void> setKioskMode(String deviceId, {required bool enabled, List<String>? apps}) async {
    await _localStorage.setKioskEnabled(enabled);
    if (apps != null) await _localStorage.setAllowedApps(apps);
  }

  // Build a DeviceModel from a user JSON object (admin list view).
  // Device hardware details are local — the server only knows { deviceLocked }.
  DeviceModel _deviceFromUserJson(Map<String, dynamic> json) {
    final locked = json['deviceLocked'] as bool? ?? false;
    final id = json['_id']?.toString() ?? '';
    return _mockDevice(id, locked: locked);
  }

  DeviceModel _mockDevice(String id, {bool locked = false}) {
    return DeviceModel(
      id: id,
      imei: '358520080042823',
      serialNumber: 'R38M702KXAE',
      manufacturer: 'Samsung',
      model: 'Galaxy A54 5G',
      androidVersion: '14',
      sdkVersion: 34,
      status: locked ? DeviceStatus.locked : DeviceStatus.active,
      ownerStatus: DeviceOwnerStatus.enabled,
      isKioskEnabled: _localStorage.isKioskEnabled,
      enrollmentDate: DateTime.now().subtract(const Duration(days: 45)),
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      batteryLevel: 78,
      ipAddress: '192.168.1.105',
      allowedApps: _localStorage.allowedApps,
    );
  }
}
