import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/glass_morphism.dart';
import '../theme/xp_haptics.dart';

/// Soft ambient blobs on Lumina scaffold background ([mockups/DESIGN.md]).
class XpAmbientBackground extends StatelessWidget {
  const XpAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundPrimary,
                  AppColors.backgroundSecondary,
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryContainer.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class XpMobileTopBar extends StatelessWidget {
  const XpMobileTopBar({
    super.key,
    required this.onMenu,
    required this.centerTitle,
  });

  final VoidCallback onMenu;

  /// Optional screen title centered (mock keeps **xPDF** wordmark left; subtitle lives in-page).
  final String centerTitle;

  @override
  Widget build(BuildContext context) {
    final pageTitle = centerTitle.trim();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassChromeFill,
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
            boxShadow: AppColors.glassShadow,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          XpHaptics.surfaceTap();
                          onMenu();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.menu_rounded,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Iconsax.document_text,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'xPDF',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                        color: AppColors.onSurface,
                        height: 1.15,
                      ),
                    ),
                    if (pageTitle.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            pageTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class XpSectionCaps extends StatelessWidget {
  const XpSectionCaps({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

Future<void> showXpMissionMenu(BuildContext context) async {
  final router = GoRouter.of(context);
  XpHaptics.sheetPresentation();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetCtx) {
      Widget link(String route, IconData ic, String label) {
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(ic, color: AppColors.primary, size: 22),
          title: Text(label, style: AppTypography.body),
          onTap: () {
            XpHaptics.navTap();
            Navigator.pop(sheetCtx);
            router.go(route);
          },
        );
      }

      final bottom = MediaQuery.of(sheetCtx).padding.bottom;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottom + 12,
          top: 8,
        ),
        child: GlassCard(
          borderRadius: 16,
          padding: EdgeInsets.only(bottom: bottom > 0 ? 8 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text('Go to…', style: AppTypography.label),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    link('/', Iconsax.home_2, 'Home'),
                    link('/tools', Iconsax.category, 'Tools'),
                    link('/documents', Iconsax.clock, 'History'),
                    link('/secure', Iconsax.lock, 'Vault'),
                    link('/merge-pdfs', Iconsax.document_copy, 'Merge PDFs'),
                    link('/settings', Iconsax.setting_2, 'Settings'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
