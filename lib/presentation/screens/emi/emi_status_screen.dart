import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/emi_model.dart';
import '../../../providers/emi_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/status_badge.dart';

class EmiStatusScreen extends ConsumerWidget {
  const EmiStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiAsync = ref.watch(emiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMI Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(emiProvider.notifier).refresh(),
          ),
        ],
      ),
      body: emiAsync.when(
        loading: () => const ListShimmer(count: 6),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(emiProvider.notifier).refresh(),
        ),
        data: (emi) {
          if (emi == null) {
            return const EmptyView(
              title: 'No EMI Found',
              subtitle: 'No active EMI loans assigned to your account.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(emiProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status header
                _StatusHeader(emi: emi).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                // Progress card
                _ProgressCard(emi: emi).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                // Chart
                _InstallmentChart(emi: emi).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                // Details card
                _DetailsCard(emi: emi).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Payment History',
                        variant: ButtonVariant.outlined,
                        leadingIcon: Icons.history_rounded,
                        onPressed: () => context.push(AppRoutes.paymentHistory),
                      ),
                    ),
                  ],
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final EmiModel emi;
  const _StatusHeader({required this.emi});

  @override
  Widget build(BuildContext context) {
    final isOverdue = emi.isOverdue;
    final isPending = emi.isPending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverdue
              ? AppColors.lockedGradient
              : isPending
                  ? AppColors.warningGradient
                  : AppColors.unlockedGradient,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge.emi(emi.status),
                    const SizedBox(width: 8),
                    if (emi.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTION REQUIRED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppFormatters.currency(emi.monthlyEmi),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Monthly EMI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOverdue
                      ? 'Overdue! Device may be locked'
                      : 'Due: ${AppFormatters.date(emi.nextDueDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${emi.remainingInstallments}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EMIs Left',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final EmiModel emi;
  const _ProgressCard({required this.emi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = emi.progressPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Repayment Progress', style: theme.textTheme.titleMedium),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProgressStat(
                  label: 'Paid',
                  value: AppFormatters.currency(emi.paidAmount),
                  color: AppColors.success,
                ),
                _ProgressStat(
                  label: 'Remaining',
                  value: AppFormatters.currency(emi.remainingAmount),
                  color: AppColors.warning,
                ),
                _ProgressStat(
                  label: 'Total',
                  value: AppFormatters.currency(emi.totalAmount),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _InstallmentChart extends StatelessWidget {
  final EmiModel emi;
  const _InstallmentChart({required this.emi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = emi.paidInstallments;
    final total = emi.totalInstallments;
    final remaining = emi.remainingInstallments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Installment Overview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      sections: [
                        PieChartSectionData(
                          value: paid.toDouble(),
                          color: AppColors.success,
                          radius: 22,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: remaining.toDouble(),
                          color: AppColors.grey200,
                          radius: 18,
                          title: '',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChartLegend(color: AppColors.success, label: 'Paid', count: paid),
                      const SizedBox(height: 12),
                      _ChartLegend(color: AppColors.grey300, label: 'Remaining', count: remaining),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total', style: theme.textTheme.bodySmall),
                            Text(
                              '$total installments',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
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
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _ChartLegend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final EmiModel emi;
  const _DetailsCard({required this.emi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            const Divider(height: 1),
            InfoRow(label: 'Product', value: emi.productName ?? 'N/A', icon: Icons.devices_rounded),
            InfoRow(label: 'Loan ID', value: emi.loanId ?? 'N/A', icon: Icons.tag_rounded),
            InfoRow(
              label: 'Start Date',
              value: emi.startDate != null ? AppFormatters.date(emi.startDate!) : 'N/A',
              icon: Icons.calendar_today_rounded,
            ),
            InfoRow(
              label: 'Next Due',
              value: AppFormatters.date(emi.nextDueDate),
              icon: Icons.event_rounded,
            ),
            InfoRow(
              label: 'Interest Rate',
              value: '${emi.interestRate ?? 0}% p.a.',
              icon: Icons.percent_rounded,
            ),
            InfoRow(
              label: 'Auto-Lock',
              value: emi.deviceLockOnOverdue ? 'Enabled' : 'Disabled',
              icon: Icons.lock_outline_rounded,
              valueColor: emi.deviceLockOnOverdue ? AppColors.error : AppColors.success,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}
