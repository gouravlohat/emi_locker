import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static LocalStorage? _instance;
  SharedPreferences? _prefs;

  LocalStorage._();
  factory LocalStorage() => _instance ??= LocalStorage._();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    assert(_prefs != null, 'LocalStorage.init() must be called before use');
    return _prefs!;
  }

  // Keys
  static const _keyIsEnrolled = 'is_enrolled';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyDarkMode = 'dark_mode';
  static const _keyDeviceLocked = 'device_locked';
  static const _keyKioskEnabled = 'kiosk_enabled';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyLastSyncTime = 'last_sync_time';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyCustomerId = 'customer_id';
  static const _keyAgentId = 'agent_id';
  static const _keyAllowedApps = 'allowed_apps';
  static const _keyEnrollmentData = 'enrollment_data';

  // Enrollment
  bool get isEnrolled => prefs.getBool(_keyIsEnrolled) ?? false;
  Future<void> setEnrolled(bool v) => prefs.setBool(_keyIsEnrolled, v);

  // Auth
  bool get isLoggedIn => prefs.getBool(_keyIsLoggedIn) ?? false;
  Future<void> setLoggedIn(bool v) => prefs.setBool(_keyIsLoggedIn, v);

  // Theme
  bool get isDarkMode => prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) => prefs.setBool(_keyDarkMode, v);

  // Device
  bool get isDeviceLocked => prefs.getBool(_keyDeviceLocked) ?? false;
  Future<void> setDeviceLocked(bool v) => prefs.setBool(_keyDeviceLocked, v);

  bool get isKioskEnabled => prefs.getBool(_keyKioskEnabled) ?? false;
  Future<void> setKioskEnabled(bool v) => prefs.setBool(_keyKioskEnabled, v);

  // Security
  bool get isBiometricEnabled => prefs.getBool(_keyBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool v) => prefs.setBool(_keyBiometricEnabled, v);

  bool get isNotificationsEnabled => prefs.getBool(_keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool v) => prefs.setBool(_keyNotificationsEnabled, v);

  // Sync
  String? get lastSyncTime => prefs.getString(_keyLastSyncTime);
  Future<void> setLastSyncTime(String v) => prefs.setString(_keyLastSyncTime, v);

  // User IDs
  String? get customerId => prefs.getString(_keyCustomerId);
  Future<void> setCustomerId(String v) => prefs.setString(_keyCustomerId, v);

  String? get agentId => prefs.getString(_keyAgentId);
  Future<void> setAgentId(String v) => prefs.setString(_keyAgentId, v);

  bool get isOnboardingDone => prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) => prefs.setBool(_keyOnboardingDone, v);

  // Kiosk apps (stored as comma-separated package names)
  List<String> get allowedApps {
    final raw = prefs.getString(_keyAllowedApps) ?? '';
    return raw.isEmpty ? [] : raw.split(',');
  }

  Future<void> setAllowedApps(List<String> apps) =>
      prefs.setString(_keyAllowedApps, apps.join(','));

  // Enrollment data (JSON string)
  String? get enrollmentData => prefs.getString(_keyEnrollmentData);
  Future<void> setEnrollmentData(String v) => prefs.setString(_keyEnrollmentData, v);

  Future<void> clearAll() => prefs.clear();
}
