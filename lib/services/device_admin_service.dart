import 'package:flutter/services.dart';

/// Platform channel bridge to Android DevicePolicyManager.
/// Falls back gracefully when not running as Device Owner.
class DeviceAdminService {
  static DeviceAdminService? _instance;
  static const _channel = MethodChannel('com.example.emi_locker/device_policy');

  DeviceAdminService._();
  factory DeviceAdminService() => _instance ??= DeviceAdminService._();

  // ── Device Owner ─────────────────────────────────────────────────────────

  Future<bool> isDeviceOwner() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Lock / Unlock ─────────────────────────────────────────────────────────

  /// Immediately locks the screen using DPM.lockNow()
  Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod<void>('lockDevice');
    } on PlatformException catch (e) {
      throw Exception('Lock failed: ${e.message}');
    }
  }

  /// Removes the lock overlay (only valid when EMI is cleared)
  Future<void> unlockDevice() async {
    try {
      await _channel.invokeMethod<void>('unlockDevice');
    } on PlatformException {
      // Non-fatal — UI-level unlock still works
    }
  }

  // ── User Restrictions ─────────────────────────────────────────────────────

  Future<void> disableUninstall() async {
    try {
      await _channel.invokeMethod<void>('disableUninstall');
    } on PlatformException {
      // Log — non-fatal in demo mode
    }
  }

  Future<void> enableUninstall() async {
    try {
      await _channel.invokeMethod<void>('enableUninstall');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> disableFactoryReset() async {
    try {
      await _channel.invokeMethod<void>('disableFactoryReset');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> disableStatusBar() async {
    try {
      await _channel.invokeMethod<void>('disableStatusBar');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> enableStatusBar() async {
    try {
      await _channel.invokeMethod<void>('enableStatusBar');
    } on PlatformException {
      // ignore
    }
  }

  // ── Kiosk / Lock Task ─────────────────────────────────────────────────────

  Future<void> startKioskMode(List<String> allowedPackages) async {
    try {
      await _channel.invokeMethod<void>('startKioskMode', {
        'packages': allowedPackages,
      });
    } on PlatformException catch (e) {
      throw Exception('Kiosk start failed: ${e.message}');
    }
  }

  Future<void> stopKioskMode() async {
    try {
      await _channel.invokeMethod<void>('stopKioskMode');
    } on PlatformException {
      // ignore
    }
  }

  Future<bool> isInKioskMode() async {
    try {
      return await _channel.invokeMethod<bool>('isInKioskMode') ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── App Suspension ─────────────────────────────────────────────────────────

  Future<void> suspendPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod<void>('suspendPackages', {'packages': packages});
    } on PlatformException {
      // ignore
    }
  }

  Future<void> unsuspendPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod<void>('unsuspendPackages', {'packages': packages});
    } on PlatformException {
      // ignore
    }
  }

  // ── Device Wipe ─────────────────────────────────────────────────────────

  Future<void> wipeDevice() async {
    try {
      await _channel.invokeMethod<void>('wipeDevice');
    } on PlatformException catch (e) {
      throw Exception('Wipe failed: ${e.message}');
    }
  }

  // ── Device Info ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException {
      return {};
    }
  }

  // ── Enrollment ─────────────────────────────────────────────────────────

  Future<String?> getEnrollmentQRData() async {
    try {
      return await _channel.invokeMethod<String>('getEnrollmentQR');
    } on PlatformException {
      return null;
    }
  }

  Future<void> applySecurityPolicies() async {
    await Future.wait([
      disableUninstall(),
      disableFactoryReset(),
    ]);
  }
}
