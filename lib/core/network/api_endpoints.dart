abstract class ApiEndpoints {

  static const baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  // static const baseUrl = 'http://localhost:5000/api';          // iOS Simulator / Postman
  // static const baseUrl = 'http://192.168.1.5:5000/api';       // Physical device (use your PC IP)

  static const socketUrl = 'http://10.0.2.2:5000'; // match the host above, no /api

  // ── Auth ─────────────────────────────────────────────────────────────────
  // POST { email|mobile, password }  →  { success, data: { token, user, deviceLocked } }
  static const userLogin = '/auth/login';
  static const adminLogin = '/auth/admin/login';
  static const agentLogin = '/auth/agent/login';
  // POST { name, email, mobile, password, role }  (superadmin only)
  static const adminRegister = '/auth/register';

  // ── User profile (client) ─────────────────────────────────────────────────
  static const myProfile = '/users/me';
  static const registerFcmToken = '/users/fcm-token';

  // ── Users (admin) ─────────────────────────────────────────────────────────
  static const users = '/users';
  static String userById(String id) => '/users/$id';
  static String renewUserKey(String id) => '/users/$id/renew-key';

  // ── Device lock (client) ──────────────────────────────────────────────────
  // GET  → { success, data: { deviceLocked, hasPendingLockRequest } }
  static const deviceLockStatus = '/device-lock/me';

  // ── Device lock (admin) ───────────────────────────────────────────────────
  // GET  ?page&limit  → overdue users list
  static const overdueUsers = '/device-lock/overdue-users';
  // POST {}  → send lock/unlock command to a user's device
  static String lockUserDevice(String userId) => '/device-lock/devices/$userId/lock';
  static String unlockUserDevice(String userId) => '/device-lock/devices/$userId/unlock';
  // POST { emiPaymentId, extendDays, reason }
  static String extendPayment(String userId) => '/device-lock/devices/$userId/extend-payment';

  // ── EMI (client) ──────────────────────────────────────────────────────────
  static const myEmis = '/emis/my';
  static String myEmiById(String emiId) => '/emis/my/$emiId';
  static String myEmiPayments(String emiId) => '/emis/my/$emiId/payments';

  // ── EMI (admin) ───────────────────────────────────────────────────────────
  static const emis = '/emis';
  static String emiById(String id) => '/emis/$id';
  static String emiPayments(String emiId) => '/emis/$emiId/payments';

  // ── Payments (client) ─────────────────────────────────────────────────────
  // GET ?emiId&startDate&endDate&page&limit
  static const pendingPayments = '/users/payments/pending';
  // POST { emiPaymentId }
  static const createRazorpayOrder = '/users/payments/razorpay/order';
  // POST { emiPaymentId, razorpayOrderId, razorpayPaymentId, razorpaySignature }
  static const verifyRazorpayPayment = '/users/payments/razorpay/verify';
  // GET
  static String paymentQr(String emiPaymentId) => '/users/payments/qr/$emiPaymentId';
  // POST { emiPaymentId, transactionId }
  static const verifyQrPayment = '/users/payments/qr/verify';
  // POST { emiPaymentId, transactionId }
  static const verifyBankPayment = '/users/payments/bank/verify';

  // ── EMI Payment Transactions (admin) ──────────────────────────────────────
  static const emiPaymentTransactions = '/admins/emi-payment-transactions';
  static const pendingEmiTransactions = '/admins/emi-payment-transactions/pending';
  static String verifyEmiTransaction(String id) =>
      '/admins/emi-payment-transactions/$id/verify';
  static String rejectEmiTransaction(String id) =>
      '/admins/emi-payment-transactions/$id/reject';

  // ── Dashboard stats ───────────────────────────────────────────────────────
  static const adminDashboardStats = '/dashboard-stats/admin-stats';
  static const superadminDashboardStats = '/dashboard-stats/summary';
  static const paymentsToday = '/dashboard-stats/payments-today';
  static String adminStatsById(String adminId) => '/dashboard-stats/admin/$adminId';

  // ── Admin management (superadmin) ─────────────────────────────────────────
  static const myAdminProfile = '/admins/me';
  static const admins = '/admins';
  static String adminById(String id) => '/admins/$id';
  static String blockAdmin(String id) => '/admins/$id/block';
  static String unblockAdmin(String id) => '/admins/$id/unblock';

  // ── Key prices ────────────────────────────────────────────────────────────
  static const activeKeyPrices = '/key-prices/active';
  static const keyPrices = '/key-prices';
  static String keyPriceById(String id) => '/key-prices/$id';

  // ── Key packages ──────────────────────────────────────────────────────────
  static const keyPackageConfigs = '/key-packages/configs';
  static const myKeyPackages = '/key-packages/my-packages';

  // ── Razorpay (package purchase, admin) ───────────────────────────────────
  static const razorpayPackageOrder = '/razorpay/package/order';
  static const razorpayPackageVerify = '/razorpay/package/verify';

  // ── Payment config (admin) ────────────────────────────────────────────────
  static const paymentConfig = '/payment-config';

  // ── Agents ────────────────────────────────────────────────────────────────
  static const agents = '/agents';
  static String agentById(String id) => '/agents/$id';
  static const agentDashboard = '/agents/dashboard';
  static const agentProfile = '/agents/profile';

  // ── Health ────────────────────────────────────────────────────────────────
  static const health = '/health';
}

abstract class SocketEvents {
  // Incoming (server → client)
  static const deviceLocked = 'device:locked';
  static const deviceUnlocked = 'device:unlocked';
  static const paymentReceived = 'payment:received';
  static const emiStatusUpdated = 'emi:status_updated';
  static const policyPushed = 'policy:pushed';
  static const connected = 'connect';
  static const disconnected = 'disconnect';

  // Outgoing (client → server)
  static const joinDevice = 'join:device';
  static const deviceHeartbeat = 'device:heartbeat';
}




// 1. Check server is alive

// GET  http://localhost:5000/health
// Expected response: { "status": "ok", "env": "development" }

// 2. Admin Login

// POST  http://localhost:5000/api/auth/admin/login
// Content-Type: application/json

// {
//   "email": "admin@emilocker.com",
//   "password": "Admin@123"
// }
// OR with mobile:


// {
//   "mobile": "9999999999",
//   "password": "Admin@123"
// }
// Expected response:


// {
//   "success": true,
//   "data": {
//     "token": "eyJhbGci...",
//     "user": { "_id": "...", "name": "Admin", "email": "...", "role": "admin" }
//   }
// }
// 3. Client Login

// POST  http://localhost:5000/api/auth/login
// Content-Type: application/json

// {
//   "email": "user@example.com",
//   "password": "secret123"
// }
// 4. Agent Login

// POST  http://localhost:5000/api/auth/agent/login
// Content-Type: application/json

// {
//   "email": "agent@example.com",
//   "password": "secret123"
// }