import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/emi_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.pulse = false,
  });

  factory StatusBadge.device(DeviceStatus status) {
    return switch (status) {
      DeviceStatus.active => const StatusBadge(
          label: 'Active',
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
      DeviceStatus.locked => const StatusBadge(
          label: 'Locked',
          color: AppColors.error,
          icon: Icons.lock_outline_rounded,
          pulse: true,
        ),
      DeviceStatus.suspended => const StatusBadge(
          label: 'Suspended',
          color: AppColors.warning,
          icon: Icons.pause_circle_outline_rounded,
        ),
      DeviceStatus.wiped => const StatusBadge(
          label: 'Wiped',
          color: AppColors.grey500,
          icon: Icons.delete_outline_rounded,
        ),
      DeviceStatus.unregistered => const StatusBadge(
          label: 'Unregistered',
          color: AppColors.grey400,
          icon: Icons.device_unknown_outlined,
        ),
    };
  }

  factory StatusBadge.emi(EmiPaymentStatus status) {
    return switch (status) {
      EmiPaymentStatus.paid => const StatusBadge(
          label: 'Paid',
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
      EmiPaymentStatus.pending => const StatusBadge(
          label: 'Pending',
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        ),
      EmiPaymentStatus.overdue => const StatusBadge(
          label: 'Overdue',
          color: AppColors.error,
          icon: Icons.warning_amber_rounded,
          pulse: true,
        ),
      EmiPaymentStatus.partiallyPaid => const StatusBadge(
          label: 'Partial',
          color: AppColors.info,
          icon: Icons.pie_chart_outline_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            _PulseDot(color: color)
          else if (icon != null)
            Icon(icon, color: color, size: 13),
          if (icon != null || pulse) const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool isLast;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }
}
