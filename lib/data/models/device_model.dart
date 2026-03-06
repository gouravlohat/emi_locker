import 'package:equatable/equatable.dart';

enum DeviceStatus { active, locked, suspended, wiped, unregistered }
enum DeviceOwnerStatus { enabled, disabled, notSet }

class DeviceModel extends Equatable {
  final String id;
  final String imei;
  final String serialNumber;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkVersion;
  final DeviceStatus status;
  final DeviceOwnerStatus ownerStatus;
  final bool isKioskEnabled;
  final String? customerId;
  final String? agentId;
  final DateTime? enrollmentDate;
  final DateTime? lastSeen;
  final int batteryLevel;
  final String? ipAddress;
  final List<String> allowedApps;
  final Map<String, dynamic> policies;

  const DeviceModel({
    required this.id,
    required this.imei,
    required this.serialNumber,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkVersion,
    required this.status,
    required this.ownerStatus,
    this.isKioskEnabled = false,
    this.customerId,
    this.agentId,
    this.enrollmentDate,
    this.lastSeen,
    this.batteryLevel = 0,
    this.ipAddress,
    this.allowedApps = const [],
    this.policies = const {},
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id: json['id']?.toString() ?? '',
        imei: json['imei'] as String? ?? '',
        serialNumber: json['serial_number'] as String? ?? '',
        manufacturer: json['manufacturer'] as String? ?? '',
        model: json['model'] as String? ?? '',
        androidVersion: json['android_version'] as String? ?? '',
        sdkVersion: json['sdk_version'] as int? ?? 0,
        status: _parseStatus(json['status'] as String? ?? 'active'),
        ownerStatus: _parseOwnerStatus(json['owner_status'] as String? ?? 'not_set'),
        isKioskEnabled: json['kiosk_enabled'] as bool? ?? false,
        customerId: json['customer_id'] as String?,
        agentId: json['agent_id'] as String?,
        enrollmentDate: json['enrollment_date'] != null
            ? DateTime.tryParse(json['enrollment_date'] as String)
            : null,
        lastSeen: json['last_seen'] != null
            ? DateTime.tryParse(json['last_seen'] as String)
            : null,
        batteryLevel: json['battery_level'] as int? ?? 0,
        ipAddress: json['ip_address'] as String?,
        allowedApps: (json['allowed_apps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        policies: json['policies'] as Map<String, dynamic>? ?? {},
      );

  static DeviceStatus _parseStatus(String raw) => switch (raw.toLowerCase()) {
        'locked' => DeviceStatus.locked,
        'suspended' => DeviceStatus.suspended,
        'wiped' => DeviceStatus.wiped,
        'unregistered' => DeviceStatus.unregistered,
        _ => DeviceStatus.active,
      };

  static DeviceOwnerStatus _parseOwnerStatus(String raw) => switch (raw.toLowerCase()) {
        'enabled' => DeviceOwnerStatus.enabled,
        'disabled' => DeviceOwnerStatus.disabled,
        _ => DeviceOwnerStatus.notSet,
      };

  bool get isLocked => status == DeviceStatus.locked;
  bool get isActive => status == DeviceStatus.active;
  bool get isEnrolled => ownerStatus == DeviceOwnerStatus.enabled;

  String get statusLabel => switch (status) {
        DeviceStatus.active => 'Active',
        DeviceStatus.locked => 'Locked',
        DeviceStatus.suspended => 'Suspended',
        DeviceStatus.wiped => 'Wiped',
        DeviceStatus.unregistered => 'Unregistered',
      };

  String get fullName => '$manufacturer $model';

  DeviceModel copyWith({
    String? id,
    String? imei,
    String? serialNumber,
    String? manufacturer,
    String? model,
    String? androidVersion,
    int? sdkVersion,
    DeviceStatus? status,
    DeviceOwnerStatus? ownerStatus,
    bool? isKioskEnabled,
    String? customerId,
    String? agentId,
    DateTime? enrollmentDate,
    DateTime? lastSeen,
    int? batteryLevel,
    String? ipAddress,
    List<String>? allowedApps,
    Map<String, dynamic>? policies,
  }) =>
      DeviceModel(
        id: id ?? this.id,
        imei: imei ?? this.imei,
        serialNumber: serialNumber ?? this.serialNumber,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        androidVersion: androidVersion ?? this.androidVersion,
        sdkVersion: sdkVersion ?? this.sdkVersion,
        status: status ?? this.status,
        ownerStatus: ownerStatus ?? this.ownerStatus,
        isKioskEnabled: isKioskEnabled ?? this.isKioskEnabled,
        customerId: customerId ?? this.customerId,
        agentId: agentId ?? this.agentId,
        enrollmentDate: enrollmentDate ?? this.enrollmentDate,
        lastSeen: lastSeen ?? this.lastSeen,
        batteryLevel: batteryLevel ?? this.batteryLevel,
        ipAddress: ipAddress ?? this.ipAddress,
        allowedApps: allowedApps ?? this.allowedApps,
        policies: policies ?? this.policies,
      );

  @override
  List<Object?> get props => [id, imei, status, ownerStatus, isKioskEnabled];
}
