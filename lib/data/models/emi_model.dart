import 'package:equatable/equatable.dart';

// EMI-level status from real API: 'active' | 'completed'
// Payment-level status (per installment): 'pending' | 'paid' | 'overdue'
enum EmiPaymentStatus { paid, pending, overdue, partiallyPaid }

class EmiModel extends Equatable {
  final String id;
  final String customerId;
  final String deviceId;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double monthlyEmi;
  final int totalInstallments;
  final int paidInstallments;
  final int remainingInstallments;
  final DateTime nextDueDate;
  final EmiPaymentStatus status;
  final String? loanId;         // maps to billNumber
  final String? productName;    // maps to description
  final DateTime? startDate;
  final double? interestRate;   // maps to interestPercentage
  final bool deviceLockOnOverdue;

  const EmiModel({
    required this.id,
    required this.customerId,
    required this.deviceId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.monthlyEmi,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.remainingInstallments,
    required this.nextDueDate,
    required this.status,
    this.loanId,
    this.productName,
    this.startDate,
    this.interestRate,
    this.deviceLockOnOverdue = true,
  });

  // Real API EMI fields:
  //   _id, clientUser (ObjectId or object), createdBy,
  //   billNumber, principalAmount, interestPercentage, totalAmount,
  //   paymentScheduleType (months), dueDates ([1-31]),
  //   paidInstallments, totalInstallments,
  //   status ('active' | 'completed'),
  //   description, createdAt, updatedAt
  factory EmiModel.fromJson(Map<String, dynamic> json) {
    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ?? 0;
    final totalInstallments = json['totalInstallments'] as int? ?? 0;
    final paidInstallments = json['paidInstallments'] as int? ?? 0;
    final monthlyEmi =
        totalInstallments > 0 ? totalAmount / totalInstallments : 0.0;
    final paidAmount = monthlyEmi * paidInstallments;

    return EmiModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: _extractId(json['clientUser']) ?? '',
      // deviceId lives in UserDevice, not EMI — store user id as fallback
      deviceId: _extractId(json['clientUser']) ?? '',
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: totalAmount - paidAmount,
      monthlyEmi: monthlyEmi,
      totalInstallments: totalInstallments,
      paidInstallments: paidInstallments,
      remainingInstallments: totalInstallments - paidInstallments,
      nextDueDate: _nextDueDateFromDueDates(json['dueDates']),
      status: _parseStatus(json['status'] as String? ?? 'active'),
      loanId: json['billNumber'] as String?,
      productName: json['description'] as String?,
      startDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      interestRate: (json['interestPercentage'] as num?)?.toDouble(),
      deviceLockOnOverdue: true,
    );
  }

  // Extract a MongoDB ObjectId string from either a raw id string or a populated object
  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? value['id']?.toString();
    return null;
  }

  // dueDates is an array of day-of-month integers (e.g. [5, 20]).
  // Return the next upcoming due date from today.
  static DateTime _nextDueDateFromDueDates(dynamic dueDates) {
    final now = DateTime.now();
    if (dueDates is List && dueDates.isNotEmpty) {
      final days = dueDates
          .whereType<int>()
          .map((d) {
            var candidate = DateTime(now.year, now.month, d);
            if (!candidate.isAfter(now)) {
              candidate = DateTime(now.year, now.month + 1, d);
            }
            return candidate;
          })
          .toList()
        ..sort((a, b) => a.compareTo(b));
      if (days.isNotEmpty) return days.first;
    }
    return now.add(const Duration(days: 30));
  }

  // Real EMI-level status: 'active' → pending, 'completed' → paid
  // Overdue is determined per-installment, but we map 'overdue' too if present.
  static EmiPaymentStatus _parseStatus(String raw) => switch (raw.toLowerCase()) {
        'completed' => EmiPaymentStatus.paid,
        'overdue' => EmiPaymentStatus.overdue,
        'partial' || 'partially_paid' => EmiPaymentStatus.partiallyPaid,
        _ => EmiPaymentStatus.pending, // 'active' → pending
      };

  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue => status == EmiPaymentStatus.overdue;
  bool get isPaid => status == EmiPaymentStatus.paid;
  bool get isPending => status == EmiPaymentStatus.pending;

  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;
  bool get isDueToday => daysUntilDue == 0;
  bool get isDueSoon => daysUntilDue <= 3 && daysUntilDue >= 0;

  String get statusLabel => switch (status) {
        EmiPaymentStatus.paid => 'Completed',
        EmiPaymentStatus.pending => 'Active',
        EmiPaymentStatus.overdue => 'Overdue',
        EmiPaymentStatus.partiallyPaid => 'Partially Paid',
      };

  EmiModel copyWith({
    String? id,
    String? customerId,
    String? deviceId,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    double? monthlyEmi,
    int? totalInstallments,
    int? paidInstallments,
    int? remainingInstallments,
    DateTime? nextDueDate,
    EmiPaymentStatus? status,
    String? loanId,
    String? productName,
    DateTime? startDate,
    double? interestRate,
    bool? deviceLockOnOverdue,
  }) =>
      EmiModel(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        deviceId: deviceId ?? this.deviceId,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        remainingAmount: remainingAmount ?? this.remainingAmount,
        monthlyEmi: monthlyEmi ?? this.monthlyEmi,
        totalInstallments: totalInstallments ?? this.totalInstallments,
        paidInstallments: paidInstallments ?? this.paidInstallments,
        remainingInstallments:
            remainingInstallments ?? this.remainingInstallments,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        status: status ?? this.status,
        loanId: loanId ?? this.loanId,
        productName: productName ?? this.productName,
        startDate: startDate ?? this.startDate,
        interestRate: interestRate ?? this.interestRate,
        deviceLockOnOverdue: deviceLockOnOverdue ?? this.deviceLockOnOverdue,
      );

  static EmiModel mock() => EmiModel(
        id: 'emi_001',
        customerId: 'cust_001',
        deviceId: 'dev_001',
        totalAmount: 36000,
        paidAmount: 18000,
        remainingAmount: 18000,
        monthlyEmi: 3000,
        totalInstallments: 12,
        paidInstallments: 6,
        remainingInstallments: 6,
        nextDueDate: DateTime.now().add(const Duration(days: 5)),
        status: EmiPaymentStatus.pending,
        loanId: 'BILL-2024-001',
        productName: 'Samsung Galaxy A54',
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        interestRate: 12.0,
        deviceLockOnOverdue: true,
      );

  @override
  List<Object?> get props => [id, customerId, deviceId, status, paidAmount];
}
