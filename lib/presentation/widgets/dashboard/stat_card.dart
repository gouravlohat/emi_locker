import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final int animationDelay;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.15),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        // LayoutBuilder adapts every dimension to whatever size the grid allocates
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            final isCompact = h < 120 || w < 150;

            final pad = isCompact ? 10.0 : 14.0;
            final iconBox = isCompact ? 30.0 : 36.0;
            final iconSize = isCompact ? 16.0 : 18.0;
            final gap1 = isCompact ? 6.0 : 10.0;
            final valueFontSize = isCompact ? 18.0 : 22.0;
            final titleFontSize = isCompact ? 10.0 : 11.0;
            final subFontSize = isCompact ? 9.0 : 10.0;
            final gap2 = isCompact ? 1.0 : 2.0;
            final gap3 = isCompact ? 2.0 : 4.0;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  SizedBox(height: gap1),
                  // FittedBox prevents value text from ever overflowing sideways
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: valueFontSize,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: gap2),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: gap3),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.7),
                        fontSize: subFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class EmiOverviewCard extends StatelessWidget {
  final double paidAmount;
  final double totalAmount;
  final double monthlyEmi;
  final int paidInstallments;
  final int totalInstallments;
  final DateTime nextDueDate;
  final VoidCallback? onTap;

  const EmiOverviewCard({
    super.key,
    required this.paidAmount,
    required this.totalAmount,
    required this.monthlyEmi,
    required this.paidInstallments,
    required this.totalInstallments,
    required this.nextDueDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
    final remaining = totalAmount - paidAmount;
    final screenW = MediaQuery.of(context).size.width;
    final isNarrow = screenW < 380;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isNarrow ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EMI Overview',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 8 : 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$paidInstallments/$totalInstallments EMIs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 8 : 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${remaining.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Text(
              'Remaining Balance',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            SizedBox(height: isNarrow ? 12 : 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid ₹${paidAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 10 : 14),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 10 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next EMI',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹${monthlyEmi.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white30),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${nextDueDate.day} ${_month(nextDueDate.month)} ${nextDueDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;

  const ActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(time),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
