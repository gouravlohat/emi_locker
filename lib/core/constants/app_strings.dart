abstract class AppStrings {
  // App
  static const appName = 'EMI Locker';
  static const appTagline = 'Enterprise Device Management';
  static const version = 'v1.0.0';

  // Splash
  static const initializing = 'Initializing...';
  static const checkingEnrollment = 'Checking enrollment status...';
  static const checkingStatus = 'Checking device status...';

  // Auth
  static const login = 'Login';
  static const logout = 'Logout';
  static const username = 'Email or Mobile';
  static const password = 'Password';
  static const agentCode = 'Agent Code';
  static const forgotPassword = 'Forgot Password?';
  static const loginAsAdmin = 'Admin Login';
  static const loginAsAgent = 'Agent Login';
  static const loginAsCustomer = 'Customer Login';
  static const invalidCredentials = 'Invalid credentials. Please try again.';

  // Enrollment
  static const enrollment = 'Device Enrollment';
  static const scanQR = 'Scan QR Code';
  static const manualEnroll = 'Manual Enrollment';
  static const enrollmentSuccess = 'Device enrolled successfully!';
  static const enrollmentFailed = 'Enrollment failed. Please try again.';
  static const deviceId = 'Device ID';
  static const imei = 'IMEI Number';
  static const step1 = 'Step 1: Scan QR';
  static const step2 = 'Step 2: Verify Device';
  static const step3 = 'Step 3: Apply Policies';
  static const enrollingDevice = 'Enrolling device...';

  // Dashboard
  static const dashboard = 'Dashboard';
  static const deviceStatus = 'Device Status';
  static const emiStatus = 'EMI Status';
  static const quickActions = 'Quick Actions';
  static const recentActivity = 'Recent Activity';
  static const totalDevices = 'Total Devices';
  static const activeDevices = 'Active Devices';
  static const lockedDevices = 'Locked Devices';
  static const overduePayments = 'Overdue';

  // EMI
  static const emiDetails = 'EMI Details';
  static const nextPayment = 'Next Payment';
  static const dueDate = 'Due Date';
  static const amountDue = 'Amount Due';
  static const totalAmount = 'Total Amount';
  static const paidAmount = 'Paid Amount';
  static const remainingAmount = 'Remaining Amount';
  static const emiPaid = 'EMI Paid';
  static const emiPending = 'EMI Pending';
  static const emiOverdue = 'EMI Overdue';
  static const paymentHistory = 'Payment History';
  static const makePayment = 'Make Payment';
  static const installments = 'Installments';
  static const monthlyEmi = 'Monthly EMI';

  // Locker
  static const deviceLocked = 'Device Locked';
  static const deviceUnlocked = 'Device Unlocked';
  static const lockDevice = 'Lock Device';
  static const unlockDevice = 'Unlock Device';
  static const lockReason = 'EMI payment overdue';
  static const unlockCode = 'Unlock Code';
  static const enterUnlockCode = 'Enter unlock code';
  static const emergencyCall = 'Emergency Call';
  static const contactSupport = 'Contact Support';
  static const lockerDescription =
      'Your device has been locked due to pending EMI payment. Please clear your dues to unlock.';

  // Kiosk
  static const kioskMode = 'Kiosk Mode';
  static const enableKiosk = 'Enable Kiosk Mode';
  static const disableKiosk = 'Disable Kiosk Mode';
  static const allowedApps = 'Allowed Applications';
  static const addApp = 'Add Application';
  static const kioskActive = 'Kiosk Mode Active';

  // Admin
  static const adminPanel = 'Admin Panel';
  static const remoteControl = 'Remote Control';
  static const deviceManagement = 'Device Management';
  static const policyManagement = 'Policy Management';
  static const bulkActions = 'Bulk Actions';
  static const lockAll = 'Lock All Devices';
  static const unlockAll = 'Unlock All Devices';
  static const pushPolicy = 'Push Policy';
  static const wipeDevice = 'Wipe Device';

  // Settings
  static const settings = 'Settings';
  static const notifications = 'Notifications';
  static const security = 'Security';
  static const biometricAuth = 'Biometric Authentication';
  static const autoLock = 'Auto-Lock Policy';
  static const theme = 'Theme';
  static const darkMode = 'Dark Mode';
  static const language = 'Language';
  static const about = 'About';
  static const privacyPolicy = 'Privacy Policy';

  // Device Info
  static const deviceInfo = 'Device Information';
  static const manufacturer = 'Manufacturer';
  static const model = 'Model';
  static const androidVersion = 'Android Version';
  static const sdkVersion = 'SDK Version';
  static const serialNumber = 'Serial Number';
  static const batteryLevel = 'Battery Level';
  static const storageInfo = 'Storage';
  static const networkInfo = 'Network';
  static const deviceOwner = 'Device Owner';
  static const enrollmentDate = 'Enrollment Date';

  // Common
  static const confirm = 'Confirm';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const retry = 'Retry';
  static const refresh = 'Refresh';
  static const loading = 'Loading...';
  static const noData = 'No data available';
  static const error = 'Something went wrong';
  static const networkError = 'No internet connection';
  static const success = 'Success';
  static const warning = 'Warning';
  static const info = 'Info';
  static const yes = 'Yes';
  static const no = 'No';
  static const ok = 'OK';
  static const close = 'Close';
  static const search = 'Search';
  static const filter = 'Filter';
  static const sort = 'Sort';
  static const export = 'Export';
  static const share = 'Share';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const view = 'View';
  static const back = 'Back';
  static const next = 'Next';
  static const done = 'Done';
  static const skip = 'Skip';
  static const apply = 'Apply';
}
