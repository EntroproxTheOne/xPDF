import 'dart:ui';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'xp_haptics.dart';

/// **Lumina Glass** — frosted panels from [mockups/DESIGN.md]:
/// blur ~24px, translucent white fill, soft outline.

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showRedTrim;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 24,
    this.borderColor,
    this.borderWidth = 1,
    this.padding,
    this.margin,
    this.onTap,
    this.showRedTrim = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = showRedTrim
        ? AppColors.primary.withValues(alpha: 0.45)
        : (borderColor ?? AppColors.glassBorder);

    final tap = onTap;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap:
            tap == null
                ? null
                : () {
                    XpHaptics.surfaceTap();
                    tap();
                  },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: effectiveBorder, width: borderWidth),
                boxShadow: AppColors.glassShadow,
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 24,
    this.opacity = 0.60,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: AppColors.glassShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Level 2 — stronger blur + primary-tint rim (sheet / modal).
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFraction;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxHeightFraction = 0.85,
    bool isDismissible = true,
  }) {
    XpHaptics.sheetPresentation();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          GlassBottomSheet(maxHeightFraction: maxHeightFraction, child: child),
    );
  }
}

class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showRedTrim;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.showRedTrim = false,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onTap != null) {
          XpHaptics.surfaceTap();
          widget.onTap!.call();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: GlassCard(
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          showRedTrim: widget.showRedTrim,
          child: widget.child,
        ),
      ),
    );
  }
}
