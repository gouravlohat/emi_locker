import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/device_model.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/emi_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/status_badge.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Devices', icon: Icon(Icons.devices_rounded, size: 18)),
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart_rounded, size: 18)),
            Tab(text: 'Controls', icon: Icon(Icons.tune_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _DevicesTab(),
          _StatsTab(),
          _ControlsTab(),
        ],
      ),
    );
  }
}

// ── Devices Tab ───────────────────────────────────────────────────────────────

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);

    return devicesAsync.when(
      loading: () => const ListShimmer(count: 6),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(allDevicesProvider),
      ),
      data: (devices) {
        return Column(
          children: [
            // Summary chips
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Total: ${devices.length}',
                    color: AppColors.primary,
                    icon: Icons.devices_rounded,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Locked: ${devices.where((d) => d.isLocked).length}',
                    color: AppColors.error,
                    icon: Icons.lock_rounded,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Active: ${devices.where((d) => d.isActive).length}',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _DeviceTile(
                  device: devices[i],
                  index: i,
                  onLock: () => _lockDevice(context, ref, devices[i]),
                  onUnlock: () => _unlockDevice(context, ref, devices[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _lockDevice(BuildContext ctx, WidgetRef ref, DeviceModel device) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Lock Device'),
        content: Text('Lock ${device.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lock'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(deviceProvider.notifier).lockDevice(reason: 'Admin action');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Device locked'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _unlockDevice(BuildContext ctx, WidgetRef ref, DeviceModel device) async {
    await ref.read(deviceProvider.notifier).unlockDevice();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Device unlocked'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceModel device;
  final int index;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  const _DeviceTile({
    required this.device,
    required this.index,
    required this.onLock,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: device.isLocked
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
              color: (device.isLocked ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              device.isLocked ? Icons.lock_rounded : Icons.smartphone_rounded,
              color: device.isLocked ? AppColors.error : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.fullName, style: theme.textTheme.titleSmall),
                Text(
                  'IMEI: ${device.imei.length > 10 ? '${device.imei.substring(0, 10)}...' : device.imei}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge.device(device.status),
                    const SizedBox(width: 6),
                    if (device.lastSeen != null)
                      Text(
                        AppFormatters.timeAgo(device.lastSeen!),
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: device.isLocked ? onUnlock : onLock,
                icon: Icon(
                  device.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: device.isLocked ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                tooltip: device.isLocked ? 'Unlock' : 'Lock',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return statsAsync.when(
      loading: () => const DashboardShimmer(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(dashboardStatsProvider)),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Revenue row
          Row(
            children: [
              Expanded(
                child: _StatContainer(
                  title: 'Total Collected',
                  value: AppFormatters.currency(stats.totalCollected),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatContainer(
                  title: 'Pending',
                  value: AppFormatters.currency(stats.totalPending),
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatContainer(
                  title: 'Enrolled Today',
                  value: '${stats.enrolledToday}',
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatContainer(
                  title: 'Overdue',
                  value: '${stats.overdueCount}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Monthly breakdown
          Text('Monthly Breakdown', style: theme.textTheme.titleMedium)
              .animate(delay: 200.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          ...stats.monthlyData.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MonthRow(data: e.value, isDark: isDark)
                  .animate(delay: Duration(milliseconds: 300 + e.key * 60))
                  .fadeIn(duration: 300.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatContainer extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatContainer({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(title, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final dynamic data;
  final bool isDark;

  const _MonthRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxVal = 250000.0;
    final ratio = ((data.collected as double) / maxVal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppFormatters.monthYear(data.month), style: theme.textTheme.titleSmall),
              Text(AppFormatters.currency(data.collected),
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 4),
          Text('${data.newDevices} new devices', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Controls Tab ──────────────────────────────────────────────────────────────

class _ControlsTab extends ConsumerWidget {
  const _ControlsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ControlSection(
          title: 'Bulk Device Actions',
          children: [
            _ControlTile(
              icon: Icons.lock_rounded,
              title: 'Lock All Overdue Devices',
              subtitle: 'Lock devices with overdue EMI payments',
              color: AppColors.error,
              onTap: () => _bulkAction(context, 'Lock all overdue devices?'),
            ),
            _ControlTile(
              icon: Icons.lock_open_rounded,
              title: 'Unlock Cleared Devices',
              subtitle: 'Unlock devices with cleared payments',
              color: AppColors.success,
              onTap: () => _bulkAction(context, 'Unlock all cleared devices?'),
            ),
            _ControlTile(
              icon: Icons.sync_rounded,
              title: 'Sync All Devices',
              subtitle: 'Force sync device status and policies',
              color: AppColors.primary,
              onTap: () => _bulkAction(context, 'Sync all devices?'),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        _ControlSection(
          title: 'Policy Management',
          children: [
            _ControlTile(
              icon: Icons.security_rounded,
              title: 'Push Security Policies',
              subtitle: 'Apply updated security configuration',
              color: AppColors.primary,
              onTap: () => _bulkAction(context, 'Push policies to all devices?'),
            ),
            _ControlTile(
              icon: Icons.apps_rounded,
              title: 'Update App Whitelist',
              subtitle: 'Manage allowed apps across devices',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.kiosk),
            ),
          ],
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        _ControlSection(
          title: 'Enrollment',
          children: [
            _ControlTile(
              icon: Icons.qr_code_rounded,
              title: 'Generate Enrollment QR',
              subtitle: 'Create new enrollment QR codes',
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.enrollment),
            ),
            _ControlTile(
              icon: Icons.add_to_queue_rounded,
              title: 'Manual Enrollment',
              subtitle: 'Enroll device by IMEI number',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.enrollment),
            ),
          ],
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  void _bulkAction(BuildContext ctx, String message) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Action executed successfully'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _ControlSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ControlSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: children.indexed
                .map(
                  (e) => Column(
                    children: [
                      e.$2,
                      if (e.$1 < children.length - 1) const Divider(height: 1, indent: 56),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
