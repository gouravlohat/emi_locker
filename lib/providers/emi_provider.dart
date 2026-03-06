import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/emi_model.dart';
import '../data/models/payment_model.dart';
import '../data/repositories/emi_repository.dart';
import '../core/storage/local_storage.dart';

final emiRepositoryProvider = Provider<EmiRepository>((ref) => EmiRepository());

// EMI status provider
final emiStatusProvider = FutureProvider.family<EmiModel, String>((ref, customerId) async {
  final repo = ref.read(emiRepositoryProvider);
  return repo.getEmiStatus(customerId);
});

// Current customer EMI (auto-fetches using stored customer ID)
class EmiNotifier extends AsyncNotifier<EmiModel?> {
  late EmiRepository _repo;

  @override
  Future<EmiModel?> build() async {
    _repo = ref.read(emiRepositoryProvider);
    final customerId = LocalStorage().customerId;
    if (customerId == null) return EmiModel.mock();
    return _repo.getEmiStatus(customerId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final customerId = LocalStorage().customerId ?? 'cust_001';
    state = await AsyncValue.guard(() => _repo.getEmiStatus(customerId));
  }

  void updateFromSocket(Map<String, dynamic> data) {
    final current = state.value;
    if (current == null) return;
    final newStatus = data['status'] as String?;
    if (newStatus != null) {
      state = AsyncData(current.copyWith(
        status: _parseStatus(newStatus),
      ));
    }
  }

  EmiPaymentStatus _parseStatus(String raw) => switch (raw.toLowerCase()) {
        'paid' => EmiPaymentStatus.paid,
        'overdue' => EmiPaymentStatus.overdue,
        _ => EmiPaymentStatus.pending,
      };
}

final emiProvider = AsyncNotifierProvider<EmiNotifier, EmiModel?>(EmiNotifier.new);

// Payment history
final paymentHistoryProvider = FutureProvider.family<List<PaymentModel>, String>(
  (ref, customerId) async {
    final repo = ref.read(emiRepositoryProvider);
    return repo.getPaymentHistory(customerId);
  },
);

// Dashboard stats
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.read(emiRepositoryProvider);
  return repo.getDashboardStats();
});
