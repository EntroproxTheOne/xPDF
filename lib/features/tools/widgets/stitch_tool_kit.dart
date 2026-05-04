import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';

/// Vertical pill + section title (mock 7 `Tools` page).
class ToolsSectionHeader extends StatelessWidget {
  const ToolsSectionHeader({
    super.key,
    required this.title,
    required this.pillColor,
  });

  final String title;
  final Color pillColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: AppTypography.headline),
        ],
      ),
    );
  }
}

/// Tool grid cell: glass surface, round icon well, title + body (mock 7 cards).
class ToolsGridCard extends StatelessWidget {
  const ToolsGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        XpHaptics.surfaceTap();
        onTap();
      },
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          height: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback when an action expects a PDF path selected first.
Future<void> showPdfRequiredToast(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        'Pick a PDF from History or Tools to use this.',
        style: AppTypography.bodySmall,
      ),
    ),
  );
}
