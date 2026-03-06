import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'customer';
  bool _isLoading = false;

  static const _roles = [
    ('customer', 'Customer', Icons.person_rounded),
    ('agent', 'Agent', Icons.badge_rounded),
    ('admin', 'Admin', Icons.admin_panel_settings_rounded),
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [AppColors.darkBg, AppColors.darkSurface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFFF1F5FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.35, 0.35],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                SizedBox(
                  height: size.height * 0.25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 38),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),

                // Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back', style: theme.textTheme.headlineSmall)
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 4),
                        Text('Sign in to continue', style: theme.textTheme.bodyMedium)
                            .animate(delay: 400.ms)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),

                        // Role selector
                        Text('Login as', style: theme.textTheme.labelLarge)
                            .animate(delay: 450.ms)
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 10),
                        _RoleSelector(
                          roles: _roles,
                          selected: _selectedRole,
                          onChanged: (r) => setState(() => _selectedRole = r),
                        ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 20),

                        CustomTextField(
                          label: AppStrings.username,
                          hint: 'Enter your email or mobile number',
                          controller: _usernameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Email or mobile is required' : null,
                        ).animate(delay: 550.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 16),

                        CustomTextField(
                          label: AppStrings.password,
                          hint: 'Enter your password',
                          controller: _passwordCtrl,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Password is required' : null,
                        ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(AppStrings.forgotPassword),
                          ),
                        ).animate(delay: 650.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 8),

                        // Demo credentials hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.info, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use your registered email or mobile number. Customer/Agent → Dashboard, Admin → Admin Panel.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 680.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 20),

                        CustomButton(
                          label: AppStrings.login,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _login,
                        ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).login(
            username: _usernameCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _selectedRole,
          );
      if (mounted) {
        if (success) {
          final user = ref.read(currentUserProvider);
          if (user?.isAdmin ?? false) {
            context.go(AppRoutes.admin);
          } else {
            context.go(AppRoutes.dashboard);
          }
        } else {
          final err = ref.read(authProvider).value?.error ?? AppStrings.invalidCredentials;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _RoleSelector extends StatelessWidget {
  final List<(String, String, IconData)> roles;
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: roles.map((r) {
        final isSelected = r.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(r.$1),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? AppColors.darkCard
                        : AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    r.$3,
                    size: 22,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? AppColors.grey400
                            : AppColors.grey600,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? AppColors.grey400
                              : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
