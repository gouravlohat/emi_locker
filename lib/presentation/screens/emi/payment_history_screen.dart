import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/payment_model.dart';
import '../../../providers/emi_provider.dart';
import '../../widgets/common/shimmer_loading.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerId = LocalStorage().customerId ?? 'cust_001';
    final historyAsync = ref.watch(paymentHistoryProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting payment history...')),
              );
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const ListShimmer(count: 8),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(paymentHistoryProvider(customerId)),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyView(
              title: 'No Payments',
              subtitle: 'No payment records found.',
              icon: Icons.receipt_long_outlined,
            );
          }

          final totalPaid = payments
              .where((p) => p.isSuccess)
              .fold<double>(0, (s, p) => s + p.amount);

          return Column(
            children: [
              // Summary bar
              _SummaryBar(
                totalPaid: totalPaid,
                paymentCount: payments.where((p) => p.isSuccess).length,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PaymentTile(
                    payment: payments[i],
                    index: i,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final double totalPaid;
  final int paymentCount;

  const _SummaryBar({required this.totalPaid, required this.paymentCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: isDark ? AppColors.darkSurface : AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Paid', style: theme.textTheme.bodySmall),
                Text(
                  AppFormatters.currency(totalPaid),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Transactions', style: theme.textTheme.bodySmall),
                Text(
                  '$paymentCount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  final int index;

  const _PaymentTile({required this.payment, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (color, icon) = _resolveStatus();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.grey200),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Installment #${payment.installmentNumber}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(status: payment.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.modeLabel} • ${AppFormatters.date(payment.date)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (payment.transactionId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'TXN: ${payment.transactionId}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),

          // Amount
          Text(
            AppFormatters.currency(payment.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: payment.isSuccess ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms).slideX(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
        );
  }

  (Color, IconData) _resolveStatus() => switch (payment.status) {
        PaymentStatus.success => (AppColors.success, Icons.check_circle_outline_rounded),
        PaymentStatus.failed => (AppColors.error, Icons.cancel_outlined),
        PaymentStatus.pending => (AppColors.warning, Icons.pending_outlined),
        PaymentStatus.refunded => (AppColors.info, Icons.replay_rounded),
      };
}

class _StatusChip extends StatelessWidget {
  final PaymentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      PaymentStatus.success => (AppColors.success, 'Paid'),
      PaymentStatus.failed => (AppColors.error, 'Failed'),
      PaymentStatus.pending => (AppColors.warning, 'Pending'),
      PaymentStatus.refunded => (AppColors.info, 'Refunded'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
