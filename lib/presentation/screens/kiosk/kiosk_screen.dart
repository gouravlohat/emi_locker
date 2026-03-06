import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/device_provider.dart';
import '../../widgets/common/custom_button.dart';

class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  bool _isKioskEnabled = false;
  bool _isLoading = false;
  final List<_AppEntry> _apps = [
    const _AppEntry('com.google.android.dialer', 'Phone', Icons.phone_rounded, true),
    const _AppEntry('com.android.settings', 'Settings', Icons.settings_rounded, false),
    const _AppEntry('com.google.android.gms', 'Google Play Services', Icons.play_arrow_rounded, true),
    const _AppEntry('com.android.chrome', 'Chrome', Icons.public_rounded, false),
    const _AppEntry('com.whatsapp', 'WhatsApp', Icons.chat_rounded, false),
    const _AppEntry('com.google.android.youtube', 'YouTube', Icons.play_circle_rounded, false),
    const _AppEntry('com.example.emi_locker', 'EMI Locker', Icons.lock_rounded, true),
    const _AppEntry('com.android.camera2', 'Camera', Icons.camera_alt_rounded, false),
  ];

  @override
  void initState() {
    super.initState();
    _isKioskEnabled = ref.read(deviceProvider).value?.device?.isKioskEnabled ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabledApps = _apps.where((a) => a.isAllowed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kiosk Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isKioskEnabled ? AppColors.warningGradient : AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isKioskEnabled ? Icons.lock_person_rounded : Icons.apps_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isKioskEnabled ? 'Kiosk Mode Active' : 'Kiosk Mode Inactive',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _isKioskEnabled
                            ? '${enabledApps.length} apps allowed'
                            : 'All apps accessible',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isKioskEnabled,
                  onChanged: _isLoading ? null : (v) => _toggleKiosk(v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // Info banner when enabled
          if (_isKioskEnabled)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Device is restricted to allowed apps only. Users cannot access other applications.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Apps section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('App Whitelist', style: theme.textTheme.titleMedium),
              Text(
                '${enabledApps.length}/${_apps.length} allowed',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 12),

          ..._apps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AppTile(
                app: e.value,
                isDark: isDark,
                onToggle: (allowed) {
                  setState(() => _apps[e.key] = e.value.copyWith(isAllowed: allowed));
                },
              ).animate(delay: Duration(milliseconds: 150 + e.key * 60)).fadeIn(duration: 300.ms),
            ),
          ),

          const SizedBox(height: 20),

          CustomButton(
            label: 'Apply Whitelist',
            leadingIcon: Icons.check_rounded,
            isLoading: _isLoading,
            onPressed: _applyWhitelist,
          ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Future<void> _toggleKiosk(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      final allowedPkgs = _apps.where((a) => a.isAllowed).map((a) => a.packageName).toList();
      await ref.read(deviceProvider.notifier).setKioskMode(enabled: enabled, apps: allowedPkgs);
      setState(() => _isKioskEnabled = enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Kiosk mode enabled' : 'Kiosk mode disabled'),
            backgroundColor: enabled ? AppColors.warning : AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyWhitelist() async {
    setState(() => _isLoading = true);
    try {
      final allowedPkgs = _apps.where((a) => a.isAllowed).map((a) => a.packageName).toList();
      await ref.read(deviceProvider.notifier).setKioskMode(
            enabled: _isKioskEnabled,
            apps: allowedPkgs,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Whitelist applied successfully'), backgroundColor: AppColors.success),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _AppEntry {
  final String packageName;
  final String name;
  final IconData icon;
  final bool isAllowed;

  const _AppEntry(this.packageName, this.name, this.icon, this.isAllowed);

  _AppEntry copyWith({bool? isAllowed}) =>
      _AppEntry(packageName, name, icon, isAllowed ?? this.isAllowed);
}

class _AppTile extends StatelessWidget {
  final _AppEntry app;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const _AppTile({required this.app, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystem = app.packageName.startsWith('com.android') || app.packageName.startsWith('com.google');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: app.isAllowed
              ? AppColors.success.withValues(alpha: 0.4)
              : isDark
                  ? AppColors.darkBorder
                  : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (app.isAllowed ? AppColors.success : AppColors.grey400).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              app.icon,
              color: app.isAllowed ? AppColors.success : AppColors.grey400,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: theme.textTheme.titleSmall),
                Text(
                  isSystem ? 'System App' : app.packageName,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: app.isAllowed,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
