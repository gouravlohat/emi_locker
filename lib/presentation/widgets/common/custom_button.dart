import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outlined, danger, success, ghost }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? height;
  final double borderRadius;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      child: _buildButton(context),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildButton(BuildContext context) {
    final (bgColor, fgColor, borderColor) = _resolveColors();

    return AnimatedContainer(
      duration: 150.ms,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading || onPressed == null ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: onPressed == null ? bgColor.withValues(alpha: 0.5) : bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              gradient: variant == ButtonVariant.primary
                  ? const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : variant == ButtonVariant.danger
                      ? const LinearGradient(
                          colors: AppColors.lockedGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : variant == ButtonVariant.success
                          ? const LinearGradient(
                              colors: AppColors.unlockedGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: _buildContent(fgColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(fgColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: fgColor, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, color: fgColor, size: 20),
        ],
      ],
    );
  }

  (Color bg, Color fg, Color? border) _resolveColors() => switch (variant) {
        ButtonVariant.primary => (AppColors.primary, AppColors.white, null),
        ButtonVariant.secondary => (AppColors.secondary, AppColors.white, null),
        ButtonVariant.outlined => (Colors.transparent, AppColors.primary, AppColors.primary),
        ButtonVariant.danger => (AppColors.error, AppColors.white, null),
        ButtonVariant.success => (AppColors.success, AppColors.white, null),
        ButtonVariant.ghost => (Colors.transparent, AppColors.primary, null),
      };
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? theme.colorScheme.primary, size: size * 0.45),
        padding: EdgeInsets.zero,
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}
