import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';

// ── Screens ───────────────────────────────────────────────────────────────────
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/enrollment/enrollment_screen.dart';
import 'presentation/screens/enrollment/qr_scanner_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/emi/emi_status_screen.dart';
import 'presentation/screens/emi/payment_history_screen.dart';
import 'presentation/screens/locker/locker_screen.dart';
import 'presentation/screens/kiosk/kiosk_screen.dart';
import 'presentation/screens/admin/admin_panel_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/device/device_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  await LocalStorage().init();

  // Initialize notifications
  await NotificationService().init();

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: EmiLockerApp()));
}

// ── Router ────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.enrollment,
      builder: (_, __) => const EnrollmentScreen(),
      routes: [
        GoRoute(
          path: 'qr-scanner',
          builder: (_, __) => const QrScannerScreen(),
        ),
      ],
    ),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
    GoRoute(path: AppRoutes.emiStatus, builder: (_, __) => const EmiStatusScreen()),
    GoRoute(path: AppRoutes.paymentHistory, builder: (_, __) => const PaymentHistoryScreen()),
    GoRoute(path: AppRoutes.locker, builder: (_, __) => const LockerScreen()),
    GoRoute(path: AppRoutes.kiosk, builder: (_, __) => const KioskScreen()),
    GoRoute(path: AppRoutes.admin, builder: (_, __) => const AdminPanelScreen()),
    GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
    GoRoute(path: AppRoutes.deviceInfo, builder: (_, __) => const DeviceInfoScreen()),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Page not found: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.splash),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

// ── App Root ──────────────────────────────────────────────────────────────────

class EmiLockerApp extends ConsumerWidget {
  const EmiLockerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'EMI Locker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
