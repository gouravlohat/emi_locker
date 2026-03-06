import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/device_model.dart';
import '../data/repositories/device_repository.dart';
import '../core/storage/local_storage.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => DeviceRepository());

// Current device state
class DeviceState {
  final DeviceModel? device;
  final bool isLoading;
  final String? error;
  final bool isLockLoading;
  final bool isKioskLoading;

  const DeviceState({
    this.device,
    this.isLoading = false,
    this.error,
    this.isLockLoading = false,
    this.isKioskLoading = false,
  });

  DeviceState copyWith({
    DeviceModel? device,
    bool? isLoading,
    String? error,
    bool? isLockLoading,
    bool? isKioskLoading,
  }) =>
      DeviceState(
        device: device ?? this.device,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isLockLoading: isLockLoading ?? this.isLockLoading,
        isKioskLoading: isKioskLoading ?? this.isKioskLoading,
      );

  bool get isLocked => device?.isLocked ?? LocalStorage().isDeviceLocked;
}

class DeviceNotifier extends AsyncNotifier<DeviceState> {
  late DeviceRepository _repo;

  @override
  Future<DeviceState> build() async {
    _repo = ref.read(deviceRepositoryProvider);
    final deviceId = await _getDeviceId();
    if (deviceId == null) return const DeviceState();
    final device = await _repo.getDeviceStatus(deviceId);
    return DeviceState(device: device);
  }

  Future<String?> _getDeviceId() async {
    // Get from secure storage or local storage
    return LocalStorage().enrollmentData != null ? 'dev_001' : null;
  }

  Future<void> refreshDevice() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isLoading: true));
    try {
      final deviceId = current.device?.id ?? 'dev_001';
      final device = await _repo.getDeviceStatus(deviceId);
      state = AsyncData(DeviceState(device: device));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<bool> lockDevice({String? reason}) async {
    final current = state.value;
    if (current == null) return false;
    state = AsyncData(current.copyWith(isLockLoading: true));
    try {
      final deviceId = current.device?.id ?? 'dev_001';
      final device = await _repo.lockDevice(deviceId, reason: reason);
      state = AsyncData(DeviceState(device: device));
      return true;
    } catch (e) {
      state = AsyncData(current.copyWith(isLockLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<bool> unlockDevice() async {
    final current = state.value;
    if (current == null) return false;
    state = AsyncData(current.copyWith(isLockLoading: true));
    try {
      final deviceId = current.device?.id ?? 'dev_001';
      final device = await _repo.unlockDevice(deviceId);
      state = AsyncData(DeviceState(device: device));
      return true;
    } catch (e) {
      state = AsyncData(current.copyWith(isLockLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<void> setKioskMode({required bool enabled, List<String>? apps}) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isKioskLoading: true));
    try {
      final deviceId = current.device?.id ?? 'dev_001';
      await _repo.setKioskMode(deviceId, enabled: enabled, apps: apps);
      final updated = current.device?.copyWith(
        isKioskEnabled: enabled,
        allowedApps: apps ?? current.device?.allowedApps ?? [],
      );
      state = AsyncData(DeviceState(device: updated));
    } catch (e) {
      state = AsyncData(current.copyWith(isKioskLoading: false, error: e.toString()));
    }
  }

  Future<void> setDeviceFromEnrollment(DeviceModel device) async {
    state = AsyncData(DeviceState(device: device));
  }
}

final deviceProvider = AsyncNotifierProvider<DeviceNotifier, DeviceState>(DeviceNotifier.new);

// All devices for admin view
final allDevicesProvider = FutureProvider<List<DeviceModel>>((ref) async {
  final repo = ref.read(deviceRepositoryProvider);
  return repo.getAllDevices();
});

// Computed lock state
final isDeviceLockedProvider = Provider<bool>((ref) {
  return ref.watch(deviceProvider).value?.isLocked ?? LocalStorage().isDeviceLocked;
});
