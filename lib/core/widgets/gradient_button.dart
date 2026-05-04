import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/xp_haptics.dart';

/// Primary CTA — Lumina: solid `#004BCA`, white label ([mockups/DESIGN.md]).
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: isExpanded ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isDisabled ? null : AppColors.orangeGradient,
        color: isDisabled ? AppColors.surfaceContainerHighest : null,
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  XpHaptics.primaryCta();
                  onPressed?.call();
                },
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize:
                        isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: AppColors.onPrimary, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: AppTypography.buttonOnAccent,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary — ghost / outline (Lumina COMPONENTS).
class RedTrimButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const RedTrimButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed == null
            ? null
            : () {
                XpHaptics.surfaceTap();
                onPressed!();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTypography.label.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
