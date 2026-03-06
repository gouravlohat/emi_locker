import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService._() : _plugin = FlutterLocalNotificationsPlugin();
  factory NotificationService() => _instance ??= NotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'emi_locker_channel',
    'EMI Locker Alerts',
    description: 'Device lock, payment due, and EMI status alerts',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigation handled via GoRouter from app context
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> showDeviceLocked({String reason = 'EMI payment overdue'}) async {
    await _show(
      id: 1001,
      title: '🔒 Device Locked',
      body: reason,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );
  }

  Future<void> showDeviceUnlocked() async {
    await _cancelById(1001);
    await _show(
      id: 1002,
      title: '🔓 Device Unlocked',
      body: 'Your device has been unlocked. Thank you for your payment!',
    );
  }

  Future<void> showEmiDueReminder({required String amount, required int daysLeft}) async {
    final body = daysLeft == 0
        ? 'Your EMI of ₹$amount is due today!'
        : daysLeft < 0
            ? 'Your EMI of ₹$amount is overdue by ${-daysLeft} days'
            : 'Your EMI of ₹$amount is due in $daysLeft days';

    await _show(
      id: 1003,
      title: '💳 EMI Payment Reminder',
      body: body,
      importance: daysLeft <= 0 ? Importance.max : Importance.high,
    );
  }

  Future<void> showPaymentReceived({required String amount}) async {
    await _show(
      id: 1004,
      title: '✅ Payment Received',
      body: 'Payment of ₹$amount received successfully.',
    );
  }

  Future<void> showPolicyUpdate({required String policyName}) async {
    await _show(
      id: 1005,
      title: '📋 Policy Updated',
      body: '$policyName has been applied to your device.',
    );
  }

  Future<void> showEnrollmentComplete() async {
    await _show(
      id: 1006,
      title: '✅ Enrollment Complete',
      body: 'Your device has been successfully enrolled in the EMI Locker program.',
    );
  }

  // ── Core ───────────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    bool ongoing = false,
    bool autoCancel = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: importance,
      priority: priority,
      ongoing: ongoing,
      autoCancel: autoCancel,
      styleInformation: const BigTextStyleInformation(''),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
  Future<void> _cancelById(int id) => _plugin.cancel(id);

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? false;
    return granted;
  }
}
