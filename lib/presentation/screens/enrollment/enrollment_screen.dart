import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/local_storage.dart';
import '../../../providers/device_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  int _step = 0;
  bool _isLoading = false;
  final _imeiCtrl = TextEditingController();
  final _agentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _steps = [
    ('Scan QR Code', Icons.qr_code_scanner_rounded),
    ('Verify Device', Icons.phonelink_setup_rounded),
    ('Apply Policies', Icons.security_rounded),
  ];

  // Mock QR data for enrollment
  final _qrData =
      '{"type":"emi_enrollment","version":"1.0","server":"https://api.emilocker.com","token":"ENROLL_TOKEN_2024","org":"EMI Locker Corp"}';

  @override
  void dispose() {
    _imeiCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.grey100,
      appBar: AppBar(
        title: const Text(AppStrings.enrollment),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _step, steps: _steps),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: switch (_step) {
                0 => _QRStep(
                    key: const ValueKey(0),
                    qrData: _qrData,
                    onScanQR: () => context.push(AppRoutes.qrScanner),
                    onNext: () => setState(() => _step = 1),
                  ),
                1 => _VerifyStep(
                    key: const ValueKey(1),
                    imeiCtrl: _imeiCtrl,
                    agentCtrl: _agentCtrl,
                    formKey: _formKey,
                    onNext: () => setState(() => _step = 2),
                  ),
                _ => _PolicyStep(
                    key: const ValueKey(2),
                    isLoading: _isLoading,
                    onEnroll: _completeEnrollment,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeEnrollment() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(deviceRepositoryProvider);
      final device = await repo.enrollDevice({
        'imei': _imeiCtrl.text.trim().isEmpty ? '358520080042823' : _imeiCtrl.text.trim(),
        'agent_code': _agentCtrl.text.trim(),
        'enrollment_type': 'qr',
      });
      await LocalStorage().setEnrollmentData('{"enrolled":true,"device_id":"${device.id}"}');
      await ref.read(deviceProvider.notifier).setDeviceFromEnrollment(device);
      if (mounted) {
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrollment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enrolled Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your device has been enrolled in the EMI Locker program. Security policies are now active.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Continue to Login',
              onPressed: () {
                Navigator.pop(context);
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<(String, IconData)> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: 300.ms,
                height: 2,
                color: stepIdx < currentStep
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx < currentStep;
          final isCurrent = stepIdx == currentStep;

          return Column(
            children: [
              AnimatedContainer(
                duration: 300.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : steps[stepIdx].$2,
                  size: 18,
                  color: isCompleted || isCurrent ? AppColors.primary : Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Step ${stepIdx + 1}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 1: QR ────────────────────────────────────────────────────────────────

class _QRStep extends StatelessWidget {
  final String qrData;
  final VoidCallback onScanQR;
  final VoidCallback onNext;

  const _QRStep({super.key, required this.qrData, required this.onScanQR, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Scan Enrollment QR',
            style: theme.textTheme.headlineSmall,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Use the camera below to scan the enrollment QR code provided by your agent, or use the displayed QR to enroll another device.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // QR Code display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primaryDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primaryDark,
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              ),

          const SizedBox(height: 12),
          Text(
            'Enrollment QR Code',
            style: theme.textTheme.bodySmall,
          ),

          const SizedBox(height: 32),

          CustomButton(
            label: 'Scan QR Code',
            leadingIcon: Icons.qr_code_scanner_rounded,
            onPressed: onScanQR,
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          CustomButton(
            label: 'Continue Without Scanning',
            variant: ButtonVariant.outlined,
            onPressed: onNext,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Step 2: Verify ────────────────────────────────────────────────────────────

class _VerifyStep extends StatelessWidget {
  final TextEditingController imeiCtrl;
  final TextEditingController agentCtrl;
  final GlobalKey<FormState> formKey;
  final VoidCallback onNext;

  const _VerifyStep({
    super.key,
    required this.imeiCtrl,
    required this.agentCtrl,
    required this.formKey,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Verify Device', style: theme.textTheme.headlineSmall)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Enter your device IMEI number and agent code to verify enrollment.',
              style: theme.textTheme.bodyMedium,
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            CustomTextField(
              label: AppStrings.imei,
              hint: 'e.g. 358520080042823',
              controller: imeiCtrl,
              prefixIcon: Icons.smartphone_rounded,
              keyboardType: TextInputType.number,
              maxLength: 15,
              validator: (v) {
                if (v == null || v.isEmpty) return 'IMEI is required';
                if (v.length != 15) return 'IMEI must be 15 digits';
                return null;
              },
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            CustomTextField(
              label: AppStrings.agentCode,
              hint: 'Enter agent code',
              controller: agentCtrl,
              prefixIcon: Icons.badge_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Agent code is required' : null,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Verify & Continue',
              leadingIcon: Icons.verified_rounded,
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) onNext();
              },
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Policy ────────────────────────────────────────────────────────────

class _PolicyStep extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onEnroll;

  const _PolicyStep({super.key, required this.isLoading, required this.onEnroll});

  static const _policies = [
    (Icons.block_rounded, 'Uninstall Protection', 'Prevents removal of this app'),
    (Icons.restart_alt_rounded, 'Factory Reset Protection', 'Blocks unauthorized factory reset'),
    (Icons.lock_clock_rounded, 'Auto-Lock Policy', 'Locks device on payment default'),
    (Icons.apps_rounded, 'App Whitelist', 'Controls which apps can run'),
    (Icons.notifications_active_rounded, 'Payment Reminders', 'Sends EMI due notifications'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Security Policies', style: theme.textTheme.headlineSmall)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'The following policies will be applied to your device upon enrollment.',
            style: theme.textTheme.bodyMedium,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          ...List.generate(
            _policies.length,
            (i) => _PolicyTile(
              icon: _policies[i].$1,
              title: _policies[i].$2,
              subtitle: _policies[i].$3,
              delay: 150 + (i * 80),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Enroll Device',
            leadingIcon: Icons.security_rounded,
            isLoading: isLoading,
            onPressed: isLoading ? null : onEnroll,
          ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  const _PolicyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          ],
        ),
      ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 350.ms).slideX(
            begin: 0.2,
            end: 0,
            duration: 350.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}
