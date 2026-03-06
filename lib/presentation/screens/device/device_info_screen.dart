import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/device_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/status_badge.dart';

class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.deviceInfo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(deviceProvider),
          ),
        ],
      ),
      body: deviceAsync.when(
        loading: () => const ListShimmer(count: 8),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceProvider),
        ),
        data: (state) {
          final device = state.device;
          if (device == null) {
            return const EmptyView(
              title: 'No Device',
              subtitle: 'No enrolled device found.',
              icon: Icons.phone_android_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Device header
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.smartphone_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      device.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Android ${device.androidVersion} • SDK ${device.sdkVersion}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatusBadge.device(device.status),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.battery_std_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${device.batteryLevel}%',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Device Owner Status
              _InfoSection(
                title: 'Enrollment Status',
                isDark: isDark,
                children: [
                  InfoRow(
                    label: 'Device Owner',
                    value: device.isEnrolled ? 'Active' : 'Not Set',
                    icon: Icons.verified_user_rounded,
                    valueColor: device.isEnrolled ? AppColors.success : AppColors.error,
                  ),
                  InfoRow(
                    label: 'Enrollment Date',
                    value: device.enrollmentDate != null
                        ? AppFormatters.date(device.enrollmentDate!)
                        : 'N/A',
                    icon: Icons.calendar_today_rounded,
                  ),
                  InfoRow(
                    label: 'Kiosk Mode',
                    value: device.isKioskEnabled ? 'Enabled' : 'Disabled',
                    icon: Icons.apps_rounded,
                    valueColor: device.isKioskEnabled ? AppColors.warning : null,
                    isLast: true,
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Hardware info
              _InfoSection(
                title: 'Hardware Information',
                isDark: isDark,
                children: [
                  InfoRow(label: AppStrings.manufacturer, value: device.manufacturer, icon: Icons.factory_rounded),
                  InfoRow(label: AppStrings.model, value: device.model, icon: Icons.smartphone_rounded),
                  InfoRow(label: AppStrings.androidVersion, value: device.androidVersion, icon: Icons.android_rounded),
                  InfoRow(label: AppStrings.sdkVersion, value: '${device.sdkVersion}', icon: Icons.code_rounded),
                  InfoRow(label: AppStrings.serialNumber, value: device.serialNumber, icon: Icons.tag_rounded),
                  InfoRow(label: AppStrings.imei, value: AppFormatters.imei(device.imei), icon: Icons.fingerprint_rounded, isLast: true),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Network info
              _InfoSection(
                title: 'Network',
                isDark: isDark,
                children: [
                  InfoRow(label: 'IP Address', value: device.ipAddress ?? 'Unknown', icon: Icons.wifi_rounded),
                  InfoRow(
                    label: 'Last Seen',
                    value: device.lastSeen != null ? AppFormatters.timeAgo(device.lastSeen!) : 'N/A',
                    icon: Icons.access_time_rounded,
                    isLast: true,
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              if (device.allowedApps.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Allowed Apps (${device.allowedApps.length})',
                  isDark: isDark,
                  children: device.allowedApps.indexed
                      .map(
                        (e) => InfoRow(
                          label: 'App ${e.$1 + 1}',
                          value: e.$2,
                          icon: Icons.apps_rounded,
                          isLast: e.$1 == device.allowedApps.length - 1,
                        ),
                      )
                      .toList(),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _InfoSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.grey500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }
}
