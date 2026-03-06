import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/app_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoCtrl;
  String _statusText = AppStrings.initializing;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _navigate();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _statusText = AppStrings.checkingEnrollment);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _statusText = AppStrings.checkingStatus);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final appState = await ref.read(appInitProvider.future);

    if (!mounted) return;

    if (!appState.isEnrolled) {
      context.go(AppRoutes.enrollment);
    } else if (!appState.isLoggedIn) {
      context.go(AppRoutes.login);
    } else if (appState.isDeviceLocked) {
      context.go(AppRoutes.locker);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B3E), Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.3,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.2,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                      .animate(controller: _logoCtrl)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1.0, 1.0),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // App name
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    AppStrings.appTagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 80),

                  // Status indicator
                  Column(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Version tag
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Text(
                AppStrings.version,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
