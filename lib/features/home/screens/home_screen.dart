import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/xp_ui.dart';
import '../../../models/pdf_library_item.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/pdf_pick_open_service.dart';

/// Home matching Stitch mock (6): centered welcome, bento glass cards, recent teaser.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          _BackgroundGlow(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpMobileTopBar(
                onMenu: () => showXpMissionMenu(context),
                centerTitle: '',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= 720 ? 2 : 1;
                    final pad = EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      MediaQuery.paddingOf(context).bottom + 100,
                    );
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: pad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: GlassCard(
                              borderRadius: 999,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              child: Text(
                                'Welcome Back'.toUpperCase(),
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 350.ms),
                          const SizedBox(height: 20),
                          Text(
                            'Hello, what are you looking to do today?',
                            style: AppTypography.display.copyWith(
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 12),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Select a tool below to quickly process your documents with our advanced glass-engine.',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ).animate().fadeIn(duration: 440.ms),
                          const SizedBox(height: 32),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: cols == 2 ? 0.94 : 1.02,
                            children: [
                              _HomeBentoCard(
                                icon: Iconsax.scan,
                                iconBg:
                                    AppColors.secondaryContainer.withValues(
                                      alpha: 0.55,
                                    ),
                                iconColor: AppColors.secondary,
                                title: 'Scan',
                                subtitle:
                                    'Digitize physical documents with high-fidelity OCR.',
                                accentGradient: true,
                                onTap:
                                    () => context.push('/scan'),
                              ).animate(delay: 50.ms).fadeIn().slideY(
                                  begin: 0.06, end: 0),
                              _HomeBentoCard(
                                icon: Iconsax.document_copy,
                                iconBg:
                                    AppColors.surfaceContainerHigh,
                                iconColor: AppColors.tertiary,
                                title: 'Merge',
                                subtitle:
                                    'Combine multiple PDFs into a single document.',
                                onTap: () =>
                                    context.push('/merge-pdfs'),
                              ).animate(delay: 90.ms).fadeIn().slideY(
                                  begin: 0.06, end: 0),
                              _HomeBentoCard(
                                icon: Iconsax.note_2,
                                iconBg:
                                    AppColors.primaryContainer.withValues(
                                      alpha: 0.22,
                                    ),
                                iconColor: AppColors.primary,
                                title: 'Edit',
                                subtitle:
                                    'Modify text, add annotations, and sign documents securely.',
                                onTap: () =>
                                    pickPdfAndNavigateEditor(context),
                              ).animate(delay: 130.ms).fadeIn().slideY(
                                  begin: 0.06, end: 0),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ListenableBuilder(
                            listenable: PdfLibraryRepository.instance,
                            builder: (context, _) {
                              final recent =
                                  PdfLibraryRepository.instance.recent(
                                limit: 1,
                              );
                              if (recent.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return _RecentTeaser(item: recent.first)
                                  .animate(delay: 220.ms)
                                  .fadeIn();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeBentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accentGradient;

  const _HomeBentoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    const minTile = 156.0;
    return GestureDetector(
      onTap: () {
        XpHaptics.surfaceTap();
        onTap();
      },
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            if (accentGradient)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          AppColors.secondaryContainer.withValues(
                            alpha: 0.08,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: minTile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headline.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTeaser extends StatelessWidget {
  final PdfLibraryItem item;

  const _RecentTeaser({required this.item});

  String _when(DateTime opened) {
    final delta = DateTime.now().difference(opened);
    if (delta.inMinutes < 180) return '${delta.inMinutes} min ago';
    if (delta.inHours < 48) return '${delta.inHours} hr ago';
    return '${opened.month}/${opened.day}/${opened.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child:
                Icon(Iconsax.clock, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent: ${item.title}',
                  style: AppTypography.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Opened ${_when(item.lastOpenedAt)}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              XpHaptics.surfaceTap();
              context.go('/documents');
            },
            child: Text(
              'View History',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
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
              bottom: 140,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
