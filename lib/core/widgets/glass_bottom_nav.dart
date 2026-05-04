import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/xp_haptics.dart';

/// Stitch mock shell: Home · Tools · History · Settings — four slots, pill active state.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _topRadius = 24;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barHeight = 72.0 + bottomInset;
    final items = [
      _NavItem(Iconsax.home_2, 'Home'),
      _NavItem(Iconsax.category, 'Tools'),
      _NavItem(Iconsax.clock, 'History'),
      _NavItem(Iconsax.setting_2, 'Settings'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_topRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: barHeight,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: AppColors.glassChromeFill,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_topRadius),
            ),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
            boxShadow: AppColors.glassChromeUpShadow,
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    XpHaptics.navTap();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: _buildItem(items[i], isActive),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_NavItem item, bool isActive) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navActivePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textMuted.withValues(alpha: 0.75),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label.toUpperCase(),
              style: AppTypography.navLabel.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.7),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
