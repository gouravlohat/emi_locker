import 'package:equatable/equatable.dart';

// Payment mode comes from EmiPaymentTransaction, not the EMI payment itself.
// Keeping this enum for UI display; real values: 'razorpay' | 'qr_code' | 'bank_transfer' | 'cash'
enum PaymentMode { online, cash, upi, netBanking, card, cheque }

// Per-installment status from real API: 'pending' | 'paid' | 'overdue'
enum PaymentStatus { success, failed, pending, refunded }

class PaymentModel extends Equatable {
  final String id;
  final String customerId;    // maps to userId
  final String emiId;
  final double amount;
  final PaymentMode mode;
  final PaymentStatus status;
  final DateTime date;        // dueDate or paidDate
  final String? transactionId;
  final String? receiptNumber;
  final String? agentId;
  final String? notes;
  final int installmentNumber;

  const PaymentModel({
    required this.id,
    required this.customerId,
    required this.emiId,
    required this.amount,
    required this.mode,
    required this.status,
    required this.date,
    this.transactionId,
    this.receiptNumber,
    this.agentId,
    this.notes,
    this.installmentNumber = 0,
  });

  // Real API EMI payment (installment) fields:
  //   _id, emiId (ObjectId|object), userId (ObjectId|object),
  //   installmentNumber, dueDate, paidDate,
  //   amount, percentage,
  //   status ('pending' | 'paid' | 'overdue'),
  //   extendDays, extendReason, extendedBy, extendedAt,
  //   alertSent, secondAlertSent, createdAt, updatedAt
  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        customerId: _extractId(json['userId']) ?? '',
        emiId: _extractId(json['emiId']) ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        // mode is not available at installment level; default online
        mode: _parseMode(json['paymentMethod'] as String? ?? ''),
        status: _parseStatus(json['status'] as String? ?? 'pending'),
        // prefer paidDate when available, fall back to dueDate
        date: _parseDate(json['paidDate']) ??
            _parseDate(json['dueDate']) ??
            DateTime.now(),
        transactionId: json['transactionId'] as String?,
        receiptNumber: json['_id']?.toString(),
        agentId: null,
        notes: json['extendReason'] as String?,
        installmentNumber: json['installmentNumber'] as int? ?? 0,
      );

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? value['id']?.toString();
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // 'razorpay' → online, 'qr_code' → upi, 'bank_transfer' → netBanking, 'cash' → cash
  static PaymentMode _parseMode(String raw) => switch (raw.toLowerCase()) {
        'cash' => PaymentMode.cash,
        'qr_code' || 'upi' => PaymentMode.upi,
        'bank_transfer' || 'netbanking' || 'net_banking' => PaymentMode.netBanking,
        'card' => PaymentMode.card,
        'cheque' => PaymentMode.cheque,
        _ => PaymentMode.online, // razorpay and unknown
      };

  // 'paid' → success, 'overdue' → failed, 'pending' → pending
  static PaymentStatus _parseStatus(String raw) => switch (raw.toLowerCase()) {
        'paid' => PaymentStatus.success,
        'overdue' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        _ => PaymentStatus.pending,
      };

  String get modeLabel => switch (mode) {
        PaymentMode.online => 'Online',
        PaymentMode.cash => 'Cash',
        PaymentMode.upi => 'UPI',
        PaymentMode.netBanking => 'Bank Transfer',
        PaymentMode.card => 'Card',
        PaymentMode.cheque => 'Cheque',
      };

  String get statusLabel => switch (status) {
        PaymentStatus.success => 'Paid',
        PaymentStatus.failed => 'Overdue',
        PaymentStatus.pending => 'Pending',
        PaymentStatus.refunded => 'Refunded',
      };

  bool get isSuccess => status == PaymentStatus.success;

  static List<PaymentModel> mockList() => List.generate(
        8,
        (i) => PaymentModel(
          id: 'pay_${i + 1}',
          customerId: 'cust_001',
          emiId: 'emi_001',
          amount: 3000,
          mode: PaymentMode.values[i % PaymentMode.values.length],
          status: i == 3 ? PaymentStatus.failed : PaymentStatus.success,
          date: DateTime.now().subtract(Duration(days: i * 30)),
          transactionId: 'TXN${100000 + i}',
          receiptNumber: 'REC${200000 + i}',
          installmentNumber: i + 1,
        ),
      );

  @override
  List<Object?> get props => [id, customerId, emiId, amount, status, date];
}

class DashboardStats {
  final int totalDevices;
  final int activeDevices;
  final int lockedDevices;
  final int overdueCount;
  final double totalCollected;
  final double totalPending;
  final int enrolledToday;
  final List<MonthlyData> monthlyData;

  const DashboardStats({
    required this.totalDevices,
    required this.activeDevices,
    required this.lockedDevices,
    required this.overdueCount,
    required this.totalCollected,
    required this.totalPending,
    required this.enrolledToday,
    required this.monthlyData,
  });

  // Real API admin dashboard stats (GET /dashboard-stats/admin-stats):
  //   totalUsers, activeUsers, lockedDevices, overdueCount,
  //   totalCollected, totalPending, todayEnrollments,
  //   monthlyStats: [{ month, collected, pending, newUsers }]
  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalDevices: json['totalUsers'] as int? ??
            json['total_devices'] as int? ??
            0,
        activeDevices: json['activeUsers'] as int? ??
            json['active_devices'] as int? ??
            0,
        lockedDevices: json['lockedDevices'] as int? ??
            json['locked_devices'] as int? ??
            0,
        overdueCount: json['overdueCount'] as int? ??
            json['overdue_count'] as int? ??
            0,
        totalCollected: (json['totalCollected'] as num?)?.toDouble() ??
            (json['total_collected'] as num?)?.toDouble() ??
            0,
        totalPending: (json['totalPending'] as num?)?.toDouble() ??
            (json['total_pending'] as num?)?.toDouble() ??
            0,
        enrolledToday: json['todayEnrollments'] as int? ??
            json['enrolled_today'] as int? ??
            0,
        monthlyData: (json['monthlyStats'] as List<dynamic>? ??
                json['monthly_data'] as List<dynamic>? ??
                [])
            .map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static DashboardStats mock() => DashboardStats(
        totalDevices: 248,
        activeDevices: 201,
        lockedDevices: 34,
        overdueCount: 13,
        totalCollected: 1240000,
        totalPending: 312000,
        enrolledToday: 7,
        monthlyData: List.generate(
          6,
          (i) => MonthlyData(
            month: DateTime.now().subtract(Duration(days: i * 30)),
            collected: 180000.0 + (i * 15000),
            pending: 45000.0 - (i * 3000),
            newDevices: 12 + i,
          ),
        ).reversed.toList(),
      );
}

class MonthlyData {
  final DateTime month;
  final double collected;
  final double pending;
  final int newDevices;

  const MonthlyData({
    required this.month,
    required this.collected,
    required this.pending,
    required this.newDevices,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
        month: DateTime.parse(
            json['month'] as String? ?? DateTime.now().toIso8601String()),
        collected: (json['collected'] as num?)?.toDouble() ?? 0,
        pending: (json['pending'] as num?)?.toDouble() ?? 0,
        newDevices:
            json['newUsers'] as int? ?? json['new_devices'] as int? ?? 0,
      );
}
