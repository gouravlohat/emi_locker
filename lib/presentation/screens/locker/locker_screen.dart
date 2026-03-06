import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/emi_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class LockerScreen extends ConsumerStatefulWidget {
  const LockerScreen({super.key});

  @override
  ConsumerState<LockerScreen> createState() => _LockerScreenState();
}

class _LockerScreenState extends ConsumerState<LockerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _showUnlockDialog = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Make status bar transparent over lock screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emiAsync = ref.watch(emiProvider);
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // Prevent back navigation from lock screen
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F0000), Color(0xFFB71C1C), Color(0xFFD32F2F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Background pattern
                ...List.generate(5, (i) => Positioned(
                  top: size.height * 0.1 * i - 40,
                  left: -40,
                  right: -40,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                )),

                // Main content
                Column(
                  children: [
                    const SizedBox(height: 32),

                    // Lock icon with pulse
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: 1.0 + _pulseCtrl.value * 0.08,
                        child: child,
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    const Text(
                      'DEVICE LOCKED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      AppStrings.lockReason,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // EMI info card
                    emiAsync.when(
                      loading: () => const CircularProgressIndicator(color: Colors.white54),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (emi) {
                        if (emi == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _EmiInfoCard(
                            amount: emi.monthlyEmi,
                            dueDate: emi.nextDueDate,
                            overdueDays: -emi.daysUntilDue,
                          ),
                        ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
                      },
                    ),

                    const Spacer(),

                    // Lock description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        AppStrings.lockerDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          CustomButton(
                            label: 'Enter Unlock Code',
                            leadingIcon: Icons.lock_open_rounded,
                            variant: ButtonVariant.ghost,
                            onPressed: () => setState(() => _showUnlockDialog = true),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                                  label: const Text(AppStrings.emergencyCall,
                                      style: TextStyle(color: Colors.white, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _makeEmergencyCall,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.support_agent_rounded, size: 18, color: Colors.white),
                                  label: const Text(AppStrings.contactSupport,
                                      style: TextStyle(color: Colors.white, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _contactSupport,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),

                // Unlock dialog overlay
                if (_showUnlockDialog)
                  _UnlockDialog(
                    onDismiss: () => setState(() => _showUnlockDialog = false),
                    onUnlock: _attemptUnlock,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _attemptUnlock(String code) async {
    // In production: validate code against server
    if (code.trim() == '1234' || code.trim().isNotEmpty) {
      setState(() => _showUnlockDialog = false);
      final success = await ref.read(deviceProvider.notifier).unlockDevice();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device unlocked successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(AppRoutes.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid unlock code. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _makeEmergencyCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dialing emergency number: 112')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting support: 1800-XXX-XXXX')),
    );
  }
}

// ── EMI Info Card ─────────────────────────────────────────────────────────────

class _EmiInfoCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final int overdueDays;

  const _EmiInfoCard({
    required this.amount,
    required this.dueDate,
    required this.overdueDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Amount Due',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.currency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(
                label: 'Due Date',
                value: AppFormatters.date(dueDate),
                icon: Icons.calendar_today_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
              _InfoItem(
                label: overdueDays > 0 ? 'Days Overdue' : 'Days Left',
                value: '${overdueDays.abs()}',
                icon: Icons.schedule_rounded,
                valueColor: overdueDays > 0 ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Unlock Dialog ─────────────────────────────────────────────────────────────

class _UnlockDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  final Future<void> Function(String) onUnlock;

  const _UnlockDialog({required this.onDismiss, required this.onUnlock});

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter Unlock Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact your agent or pay EMI to receive the unlock code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: AppStrings.unlockCode,
                    hint: AppStrings.enterUnlockCode,
                    controller: _ctrl,
                    prefixIcon: Icons.vpn_key_rounded,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          onPressed: widget.onDismiss,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          label: 'Unlock',
                          isLoading: _isLoading,
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            await widget.onUnlock(_ctrl.text);
                            if (mounted) setState(() => _isLoading = false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 200.ms),
      ),
    );
  }
}
