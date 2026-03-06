import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/emi_model.dart';
import '../models/payment_model.dart';

class EmiRepository {
  final ApiClient _api;

  EmiRepository({ApiClient? api}) : _api = api ?? ApiClient();

  // GET /emis/my  (client — returns list of all EMIs for the logged-in user)
  // Response: { success, data: { emis: [...], pagination: {...} } }
  // We return the first/most recent active EMI for the single-EMI view.
  Future<EmiModel> getEmiStatus(String customerId) async {
    try {
      final res = await _api.get(ApiEndpoints.myEmis);
      final data = ApiClient.unwrap(res);
      final list = (data is Map ? data['emis'] : data) as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        return EmiModel.fromJson(list.first as Map<String, dynamic>);
      }
      return EmiModel.mock();
    } on DioException {
      return EmiModel.mock();
    }
  }

  // GET /emis/my/:emiId/payments  (client)
  // Response: { success, data: { payments: [...], pagination: {...} } }
  Future<List<PaymentModel>> getPaymentHistory(String emiId) async {
    try {
      final res = await _api.get(ApiEndpoints.myEmiPayments(emiId));
      final data = ApiClient.unwrap(res);
      final list =
          (data is Map ? data['payments'] : data) as List<dynamic>? ?? [];
      return list
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return PaymentModel.mockList();
    }
  }

  // GET /emis/my (admin view uses /emis — same call, admin token returns all)
  // For admin, use getAdminEmis() which hits /emis with optional filters.
  Future<List<EmiModel>> getAdminEmis({
    String? userId,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _api.get(ApiEndpoints.emis, queryParameters: {
      if (userId != null) 'userId': userId,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    final data = ApiClient.unwrap(res);
    final list = (data is Map ? data['emis'] : data) as List<dynamic>? ?? [];
    return list.map((e) => EmiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /emis/:id/payments  (admin)
  Future<List<PaymentModel>> getAdminEmiPayments(String emiId) async {
    final res = await _api.get(ApiEndpoints.emiPayments(emiId));
    final data = ApiClient.unwrap(res);
    final list =
        (data is Map ? data['payments'] : data) as List<dynamic>? ?? [];
    return list
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /dashboard-stats/admin-stats  (admin)
  // GET /dashboard-stats/summary      (superadmin)
  Future<DashboardStats> getDashboardStats({bool isSuperAdmin = false}) async {
    try {
      final endpoint = isSuperAdmin
          ? ApiEndpoints.superadminDashboardStats
          : ApiEndpoints.adminDashboardStats;
      final res = await _api.get(endpoint);
      final data = ApiClient.unwrap(res) as Map<String, dynamic>;
      return DashboardStats.fromJson(data);
    } on DioException {
      return DashboardStats.mock();
    }
  }

  // POST /users/payments/razorpay/verify
  // Body: { emiPaymentId, razorpayOrderId, razorpayPaymentId, razorpaySignature }
  Future<bool> verifyRazorpayPayment({
    required String emiPaymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _api.post(ApiEndpoints.verifyRazorpayPayment, data: {
        'emiPaymentId': emiPaymentId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
      final data = ApiClient.unwrap(res);
      return data != null;
    } on DioException {
      return false;
    }
  }

  // POST /users/payments/qr/verify
  // Body: { emiPaymentId, transactionId }
  Future<bool> verifyQrPayment({
    required String emiPaymentId,
    required String transactionId,
  }) async {
    try {
      await _api.post(ApiEndpoints.verifyQrPayment, data: {
        'emiPaymentId': emiPaymentId,
        'transactionId': transactionId,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  // POST /users/payments/bank/verify
  // Body: { emiPaymentId, transactionId }
  Future<bool> verifyBankPayment({
    required String emiPaymentId,
    required String transactionId,
  }) async {
    try {
      await _api.post(ApiEndpoints.verifyBankPayment, data: {
        'emiPaymentId': emiPaymentId,
        'transactionId': transactionId,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  // GET /users/payments/pending?emiId=...  (client)
  Future<List<PaymentModel>> getPendingPayments({String? emiId}) async {
    try {
      final res = await _api.get(
        ApiEndpoints.pendingPayments,
        queryParameters: {
          if (emiId != null) 'emiId': emiId,
        },
      );
      final data = ApiClient.unwrap(res);
      final list =
          (data is Map ? data['payments'] : data) as List<dynamic>? ?? [];
      return list
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }
}
