import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/local_storage.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometric = false;
  bool _notifications = true;
  bool _autoLock = true;
  bool _paymentReminders = true;
  bool _emailAlerts = false;

  @override
  void initState() {
    super.initState();
    _biometric = LocalStorage().isBiometricEnabled;
    _notifications = LocalStorage().isNotificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          // Appearance
          const _SectionHeader(title: 'Appearance'),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: AppStrings.darkMode,
                subtitle: 'Use dark color scheme',
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          // Security
          const _SectionHeader(title: 'Security'),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.fingerprint_rounded,
                title: AppStrings.biometricAuth,
                subtitle: 'Use fingerprint / face unlock',
                value: _biometric,
                onChanged: (v) async {
                  setState(() => _biometric = v);
                  await LocalStorage().setBiometricEnabled(v);
                },
              ),
              const Divider(height: 1, indent: 56),
              _SwitchTile(
                icon: Icons.lock_clock_rounded,
                title: AppStrings.autoLock,
                subtitle: 'Lock device when EMI is overdue',
                value: _autoLock,
                onChanged: (v) => setState(() => _autoLock = v),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          // Notifications
          const _SectionHeader(title: 'Notifications'),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive device and EMI alerts',
                value: _notifications,
                onChanged: (v) async {
                  setState(() => _notifications = v);
                  await LocalStorage().setNotificationsEnabled(v);
                },
              ),
              const Divider(height: 1, indent: 56),
              _SwitchTile(
                icon: Icons.payment_rounded,
                title: 'Payment Reminders',
                subtitle: 'Get reminded before EMI due date',
                value: _paymentReminders,
                onChanged: (v) => setState(() => _paymentReminders = v),
              ),
              const Divider(height: 1, indent: 56),
              _SwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Alerts',
                subtitle: 'Receive alerts via email',
                value: _emailAlerts,
                onChanged: (v) => setState(() => _emailAlerts = v),
              ),
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          // Account
          const _SectionHeader(title: 'Account'),
          _SettingCard(
            children: [
              _NavTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: user?.name ?? 'Not logged in',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _NavTile(
                icon: Icons.phone_rounded,
                title: 'Contact Number',
                subtitle: user?.phone ?? 'N/A',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _NavTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user?.email ?? 'N/A',
                onTap: () {},
              ),
            ],
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

          // About
          const _SectionHeader(title: 'About'),
          _SettingCard(
            children: [
              _NavTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: AppStrings.version,
                onTap: () {},
                showChevron: false,
              ),
              const Divider(height: 1, indent: 56),
              _NavTile(
                icon: Icons.policy_outlined,
                title: AppStrings.privacyPolicy,
                onTap: () => _showPrivacyPolicy(context),
              ),
              const Divider(height: 1, indent: 56),
              _NavTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support: support@emilocker.com')),
                  );
                },
              ),
            ],
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Danger zone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                        title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Sign out of your account'),
                        onTap: () => _logout(context),
                      ),
                      const Divider(height: 1, color: AppColors.error, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                        title: const Text('Clear App Data', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Remove all local data'),
                        onTap: () => _clearData(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Privacy Policy', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: const Text(
                    'EMI Locker collects device information, payment status, and location data to enforce EMI policies. Data is stored securely and shared only with authorized financial partners. Device locking is enforced upon payment default as per the loan agreement. Users have the right to contact support for any data-related concerns.\n\nContact: privacy@emilocker.com',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }

  void _clearData(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text('This will remove all local settings and cached data. You will need to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await LocalStorage().clearAll();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('App data cleared'), backgroundColor: AppColors.success),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.5,
          color: AppColors.grey500,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(margin: EdgeInsets.zero, child: Column(children: children)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: showChevron ? const Icon(Icons.chevron_right_rounded, size: 20) : null,
      onTap: onTap,
    );
  }
}
