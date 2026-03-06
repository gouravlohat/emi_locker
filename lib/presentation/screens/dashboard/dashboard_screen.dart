import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/emi_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/emi_provider.dart';
import '../../../providers/app_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/dashboard/stat_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final isAgent = user?.isAgent ?? false;
    final notifCount = ref.watch(notificationCountProvider);

    final pages = [
      const _HomeTab(),
      const _DeviceTab(),
      isAgent ? const _AgentCollectionsTab() : const _EmiTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? 'Admin Panel' : isAgent ? 'Agent Dashboard' : 'My EMI',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Welcome, ${user?.name.split(' ').first ?? 'User'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              if (notifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$notifCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          if (isAdmin || isAgent)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push(AppRoutes.admin),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.smartphone_outlined), selectedIcon: Icon(Icons.smartphone_rounded), label: 'Device'),
          NavigationDestination(
            icon: Icon(isAgent ? Icons.receipt_long_outlined : Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(isAgent ? Icons.receipt_long_rounded : Icons.account_balance_wallet_rounded),
            label: isAgent ? 'Collections' : 'EMI',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider);
    final emiAsync = ref.watch(emiProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(deviceProvider);
        ref.invalidate(emiProvider);
        ref.invalidate(dashboardStatsProvider);
      },
      child: statsAsync.when(
        loading: () => const DashboardShimmer(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(dashboardStatsProvider)),
        data: (stats) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Device status banner
            deviceAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 72, borderRadius: 16),
              error: (_, __) => const SizedBox.shrink(),
              data: (state) {
                if (state.device == null) return const SizedBox.shrink();
                final isLocked = state.isLocked;
                return GestureDetector(
                  onTap: () => context.push(isLocked ? AppRoutes.locker : AppRoutes.deviceInfo),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLocked ? AppColors.lockedGradient : AppColors.unlockedGradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLocked ? 'Device Locked' : 'Device Active',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              Text(
                                isLocked ? 'Tap to view lock details' : 'All systems operational',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms);
              },
            ),
            const SizedBox(height: 16),

            // Stats grid — admin/agent only
            if (user?.isAdmin == true || user?.isAgent == true) ...[
              Builder(builder: (context) {
                // card width = (screenW - list padding*2 - grid spacing) / 2
                // target card height = 120px → ratio = cardW / 120
                final screenW = MediaQuery.of(context).size.width;
                final cardW = (screenW - 32 - 12) / 2;
                final ratio = (cardW / 120).clamp(1.2, 1.8);
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    StatCard(
                      title: 'Total Devices',
                      value: '${stats.totalDevices}',
                      icon: Icons.devices_rounded,
                      color: AppColors.primary,
                      animationDelay: 0,
                    ),
                    StatCard(
                      title: 'Active',
                      value: '${stats.activeDevices}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      animationDelay: 100,
                    ),
                    StatCard(
                      title: 'Locked',
                      value: '${stats.lockedDevices}',
                      icon: Icons.lock_outline_rounded,
                      color: AppColors.error,
                      animationDelay: 200,
                      onTap: () => context.push(AppRoutes.admin),
                    ),
                    StatCard(
                      title: 'Overdue',
                      value: '${stats.overdueCount}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      animationDelay: 300,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // Revenue stats
              Row(
                children: [
                  Expanded(
                    child: _AmountCard(
                      label: 'Collected',
                      amount: stats.totalCollected,
                      color: AppColors.success,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountCard(
                      label: 'Pending',
                      amount: stats.totalPending,
                      color: AppColors.warning,
                      icon: Icons.pending_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // EMI overview card — customer only
            if (user?.isCustomer == true) ...[
              emiAsync.when(
                loading: () => const ShimmerBox(width: double.infinity, height: 200, borderRadius: 20),
                error: (_, __) => const SizedBox.shrink(),
                data: (emi) {
                  if (emi == null) return const SizedBox.shrink();
                  return EmiOverviewCard(
                    paidAmount: emi.paidAmount,
                    totalAmount: emi.totalAmount,
                    monthlyEmi: emi.monthlyEmi,
                    paidInstallments: emi.paidInstallments,
                    totalInstallments: emi.totalInstallments,
                    nextDueDate: emi.nextDueDate,
                    onTap: () => context.push(AppRoutes.emiStatus),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Quick actions
            Text('Quick Actions', style: theme.textTheme.titleMedium)
                .animate(delay: 400.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            _QuickActionsGrid(isAdmin: user?.isAdmin ?? false, isAgent: user?.isAgent ?? false),

            const SizedBox(height: 20),

            // Recent activity
            Text('Recent Activity', style: theme.textTheme.titleMedium)
                .animate(delay: 500.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            ..._buildActivityList(isDark, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityList(bool isDark, ThemeData theme) {
    final activities = [
      (Icons.payment_rounded, 'Payment Received', '₹3,000 EMI collected', AppColors.success,
          DateTime.now().subtract(const Duration(hours: 2))),
      (Icons.lock_outline_rounded, 'Device Locked', 'Device ID: DEV-0042 locked', AppColors.error,
          DateTime.now().subtract(const Duration(hours: 5))),
      (Icons.lock_open_rounded, 'Device Unlocked', 'Payment verified & unlocked', AppColors.success,
          DateTime.now().subtract(const Duration(days: 1))),
      (Icons.phone_android_rounded, 'New Enrollment', 'Samsung Galaxy A54 enrolled', AppColors.primary,
          DateTime.now().subtract(const Duration(days: 1))),
    ];

    return activities
        .asMap()
        .entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ActivityTile(
              icon: e.value.$1,
              title: e.value.$2,
              subtitle: e.value.$3,
              color: e.value.$4,
              time: e.value.$5,
            ).animate(delay: Duration(milliseconds: 600 + e.key * 100)).fadeIn(duration: 300.ms),
          ),
        )
        .toList();
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _AmountCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            AppFormatters.compact(amount),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  final bool isAdmin;
  final bool isAgent;

  const _QuickActionsGrid({required this.isAdmin, required this.isAgent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (Icons.account_balance_wallet_rounded, 'EMI Status', AppColors.primary, () => context.push(AppRoutes.emiStatus)),
      (Icons.history_rounded, 'Payments', AppColors.secondary, () => context.push(AppRoutes.paymentHistory)),
      (Icons.smartphone_rounded, 'Device Info', AppColors.info, () => context.push(AppRoutes.deviceInfo)),
      (Icons.settings_rounded, 'Settings', AppColors.grey600, () => context.push(AppRoutes.settings)),
      if (isAdmin || isAgent) ...[
        (Icons.lock_rounded, 'Lock Device', AppColors.error, () => _lockDevice(context, ref)),
        (Icons.apps_rounded, 'Kiosk Mode', AppColors.warning, () => context.push(AppRoutes.kiosk)),
      ],
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions
          .asMap()
          .entries
          .map(
            (e) => _QuickAction(
              icon: e.value.$1,
              label: e.value.$2,
              color: e.value.$3,
              onTap: e.value.$4,
              delay: e.key * 60,
            ),
          )
          .toList(),
    );
  }

  void _lockDevice(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lock Device'),
        content: const Text('Are you sure you want to lock this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deviceProvider.notifier).lockDevice();
      if (context.mounted) context.push(AppRoutes.locker);
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
    );
  }
}

// ── Device Tab ───────────────────────────────────────────────────────────────

class _DeviceTab extends ConsumerWidget {
  const _DeviceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(deviceProvider),
      child: deviceAsync.when(
        loading: () => const ListShimmer(count: 6),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(deviceProvider)),
        data: (state) {
          final device = state.device;
          if (device == null) {
            return const EmptyView(
              title: 'No Device Found',
              subtitle: 'Please enroll your device first.',
              icon: Icons.phone_android_rounded,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Device header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.isLocked ? AppColors.lockedGradient : AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.smartphone_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Android ${device.androidVersion}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge.device(device.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DeviceStat(label: 'Battery', value: '${device.batteryLevel}%', icon: Icons.battery_std_rounded),
                        _DeviceStat(label: 'SDK', value: '${device.sdkVersion}', icon: Icons.code_rounded),
                        _DeviceStat(
                          label: 'Owner',
                          value: device.isEnrolled ? 'Active' : 'None',
                          icon: Icons.verified_user_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Device info list
              Card(
                child: Column(
                  children: [
                    InfoRow(label: 'IMEI', value: device.imei, icon: Icons.fingerprint_rounded),
                    InfoRow(label: 'Serial No.', value: device.serialNumber, icon: Icons.tag_rounded),
                    InfoRow(label: 'Manufacturer', value: device.manufacturer, icon: Icons.factory_rounded),
                    InfoRow(label: 'Android', value: device.androidVersion, icon: Icons.android_rounded),
                    InfoRow(label: 'Kiosk Mode', value: device.isKioskEnabled ? 'Enabled' : 'Disabled',
                        icon: Icons.apps_rounded,
                        valueColor: device.isKioskEnabled ? AppColors.warning : null),
                    if (device.enrollmentDate != null)
                      InfoRow(
                        label: 'Enrolled',
                        value: AppFormatters.date(device.enrollmentDate!),
                        icon: Icons.event_rounded,
                        isLast: device.lastSeen == null,
                      ),
                    if (device.lastSeen != null)
                      InfoRow(
                        label: 'Last Seen',
                        value: AppFormatters.timeAgo(device.lastSeen!),
                        icon: Icons.access_time_rounded,
                        isLast: true,
                      ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Full Details'),
                      onPressed: () => context.push(AppRoutes.deviceInfo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.apps_rounded, size: 18),
                      label: const Text('Kiosk Mode'),
                      onPressed: () => context.push(AppRoutes.kiosk),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            ],
          );
        },
      ),
    );
  }
}

class _DeviceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DeviceStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

// ── EMI Tab ──────────────────────────────────────────────────────────────────

class _EmiTab extends ConsumerWidget {
  const _EmiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiAsync = ref.watch(emiProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(emiProvider.notifier).refresh(),
      child: emiAsync.when(
        loading: () => const ListShimmer(count: 5),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(emiProvider)),
        data: (emi) {
          if (emi == null) return const EmptyView(title: 'No EMI Found', subtitle: 'No active EMI loans.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EmiOverviewCard(
                paidAmount: emi.paidAmount,
                totalAmount: emi.totalAmount,
                monthlyEmi: emi.monthlyEmi,
                paidInstallments: emi.paidInstallments,
                totalInstallments: emi.totalInstallments,
                nextDueDate: emi.nextDueDate,
                onTap: () => context.push(AppRoutes.emiStatus),
              ),
              const SizedBox(height: 20),
              _EmiSummaryCard(emi: emi),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.paymentHistory),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('View Payment History'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ).animate(delay: 400.ms).fadeIn(duration: 300.ms),
            ],
          );
        },
      ),
    );
  }
}

class _EmiSummaryCard extends StatelessWidget {
  final EmiModel emi;
  const _EmiSummaryCard({required this.emi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loan Details', style: theme.textTheme.titleMedium),
                StatusBadge.emi(emi.status),
              ],
            ),
            const Divider(height: 24),
            _SummaryRow(label: 'Product', value: emi.productName ?? 'N/A'),
            _SummaryRow(label: 'Loan ID', value: emi.loanId ?? 'N/A'),
            _SummaryRow(label: 'Total Amount', value: AppFormatters.currency(emi.totalAmount)),
            _SummaryRow(label: 'Monthly EMI', value: AppFormatters.currency(emi.monthlyEmi)),
            _SummaryRow(label: 'Interest Rate', value: '${emi.interestRate ?? 0}% p.a.'),
            _SummaryRow(label: 'Next Due', value: AppFormatters.date(emi.nextDueDate)),
            _SummaryRow(
              label: 'Status',
              value: AppFormatters.daysRemaining(emi.nextDueDate),
              valueColor: emi.isOverdue ? AppColors.error : emi.isDueSoon ? AppColors.warning : null,
              isLast: true,
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(user?.email ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.roleLabel ?? 'Customer',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 20),

        // Settings options
        Card(
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _ProfileTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => context.push(AppRoutes.settings),
              ),
              const Divider(height: 1, indent: 56),
              _ProfileTile(
                icon: Icons.security_rounded,
                title: 'Security',
                onTap: () => context.push(AppRoutes.settings),
              ),
              const Divider(height: 1, indent: 56),
              _ProfileTile(
                icon: Icons.smartphone_rounded,
                title: 'Device Info',
                onTap: () => context.push(AppRoutes.deviceInfo),
              ),
              const Divider(height: 1, indent: 56),
              _ProfileTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'v1.0.0',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context, ref),
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text('Logout', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size(double.infinity, 50),
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}

// ── Agent Collections Tab ─────────────────────────────────────────────────────

class _AgentCollectionsTab extends ConsumerWidget {
  const _AgentCollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock collection entries for demo
    final collections = [
      _CollectionEntry('Rahul Sharma', 'Samsung Galaxy A54', 3500, true, DateTime.now()),
      _CollectionEntry('Priya Mehta', 'Redmi Note 12', 2800, false, DateTime.now().subtract(const Duration(days: 3))),
      _CollectionEntry('Suresh Patel', 'OnePlus Nord CE3', 4200, false, DateTime.now().subtract(const Duration(days: 7))),
      _CollectionEntry('Anjali Singh', 'Realme 11 Pro', 3100, true, DateTime.now().subtract(const Duration(days: 1))),
      _CollectionEntry('Vikram Kumar', 'Poco X5 Pro', 5000, false, DateTime.now().subtract(const Duration(days: 15))),
      _CollectionEntry('Neha Joshi', 'iQOO Z7 Pro', 3750, false, DateTime.now().subtract(const Duration(days: 2))),
    ];

    final pending = collections.where((c) => !c.collected).toList();
    final done = collections.where((c) => c.collected).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      child: statsAsync.when(
        loading: () => const ListShimmer(count: 5),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(dashboardStatsProvider)),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Target',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(AppFormatters.currency(stats.totalPending),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${pending.length} pending collections',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppFormatters.currency(stats.totalCollected),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const Text('Collected', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${done.length}/${collections.length} done',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Pending section
            if (pending.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('Pending (${pending.length})', style: theme.textTheme.titleSmall),
                ],
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 10),
              ...pending.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CollectionTile(entry: e.value, isDark: isDark)
                        .animate(delay: Duration(milliseconds: 150 + e.key * 60))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.1, end: 0),
                  )),
              const SizedBox(height: 10),
            ],

            // Collected section
            if (done.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('Collected (${done.length})', style: theme.textTheme.titleSmall),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 10),
              ...done.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CollectionTile(entry: e.value, isDark: isDark)
                        .animate(delay: Duration(milliseconds: 350 + e.key * 60))
                        .fadeIn(duration: 300.ms),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionEntry {
  final String customerName;
  final String deviceModel;
  final double amount;
  final bool collected;
  final DateTime dueDate;
  const _CollectionEntry(this.customerName, this.deviceModel, this.amount, this.collected, this.dueDate);
}

class _CollectionTile extends StatelessWidget {
  final _CollectionEntry entry;
  final bool isDark;
  const _CollectionTile({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = !entry.collected && entry.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.collected
              ? AppColors.success.withValues(alpha: 0.3)
              : isOverdue
                  ? AppColors.error.withValues(alpha: 0.3)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (entry.collected ? AppColors.success : isOverdue ? AppColors.error : AppColors.warning)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.customerName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: entry.collected ? AppColors.success : isOverdue ? AppColors.error : AppColors.warning,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.customerName, style: theme.textTheme.titleSmall),
                Text(entry.deviceModel, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  isOverdue
                      ? 'Overdue by ${DateTime.now().difference(entry.dueDate).inDays}d'
                      : entry.collected
                          ? 'Collected ${AppFormatters.timeAgo(entry.dueDate)}'
                          : 'Due today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: entry.collected ? AppColors.success : isOverdue ? AppColors.error : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.currency(entry.amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: entry.collected ? AppColors.success : AppColors.grey700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (entry.collected ? AppColors.success : isOverdue ? AppColors.error : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.collected ? 'Done' : isOverdue ? 'Overdue' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: entry.collected ? AppColors.success : isOverdue ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
