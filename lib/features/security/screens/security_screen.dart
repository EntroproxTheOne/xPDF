import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/widgets/xp_ui.dart';
import '../../../models/pdf_library_item.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/pdf_pick_open_service.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  void _toast(BuildContext context, String msg) {
    if (msg.contains('Change password')) {
      pickPdfAndNavigateLockStatus(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: AppTypography.body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          const XpAmbientBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpMobileTopBar(
                onMenu: () => showXpMissionMenu(context),
                centerTitle: '',
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Secure',
                          style: AppTypography.headline.copyWith(fontSize: 28),
                        ).animate().fadeIn(duration: 320.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Protect and manage sensitive PDFs',
                          style: AppTypography.bodySmall,
                        ).animate().fadeIn(duration: 380.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                      sliver: SliverToBoxAdapter(
                        child: ListenableBuilder(
                          listenable: PdfLibraryRepository.instance,
                          builder: (context, _) {
                            final n = PdfLibraryRepository.instance
                                .recent()
                                .length;
                            return Row(
                              children: [
                                _StatCard(
                                  icon: Iconsax.lock,
                                  value: '—',
                                  label: 'Locked',
                                  color: AppColors.redTrim,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  icon: Iconsax.clock,
                                  value: '$n',
                                  label: 'Recent',
                                  color: AppColors.orangeAccent,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  icon: Iconsax.shield_tick,
                                  value: 'AES',
                                  label: '256-bit',
                                  color: AppColors.tertiaryBright,
                                ),
                              ],
                            );
                          },
                        ).animate().fadeIn(duration: 400.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                      sliver: SliverToBoxAdapter(
                        child: XpSectionCaps(
                          icon: Iconsax.shield_tick,
                          label: 'QUICK ACTIONS',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child:
                            _VaultActionLarge(
                                  icon: Iconsax.lock,
                                  title: 'Lock a document',
                                  body: 'AES-256 password protection.',
                                  accent: AppColors.redTrim,
                                  foot: 'CHOOSE PDF',
                                  onTap: () => pickPdfAndNavigateLock(context),
                                )
                                .animate(delay: 60.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.05, end: 0),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child:
                            _VaultActionLarge(
                                  icon: Iconsax.unlock,
                                  title: 'Unlock document',
                                  body:
                                      'Remove encryption when you have the password.',
                                  accent: AppColors.success,
                                  foot: 'CHOOSE PDF',
                                  onTap: () =>
                                      pickPdfAndNavigateUnlock(context),
                                )
                                .animate(delay: 120.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.05, end: 0),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child:
                            _VaultActionLarge(
                                  icon: Iconsax.shield_search,
                                  title: 'Check lock status',
                                  body:
                                      'See whether a PDF needs a PIN before opening.',
                                  accent: AppColors.info,
                                  foot: 'CHOOSE PDF',
                                  enabled: true,
                                  onTap: () => _toast(
                                    context,
                                    'Change password • coming soon.',
                                  ),
                                )
                                .animate(delay: 180.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.05, end: 0),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
                      sliver: SliverToBoxAdapter(
                        child: XpSectionCaps(
                          icon: Iconsax.folder_open,
                          label: 'RECENT (OPEN TO VIEW)',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 112),
                      sliver: SliverToBoxAdapter(
                        child: ListenableBuilder(
                          listenable: PdfLibraryRepository.instance,
                          builder: (context, _) {
                            final items = PdfLibraryRepository.instance.recent(
                              limit: 12,
                            );
                            if (items.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'No PDFs yet. Scan, import, or open from Home.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.caption,
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: items.asMap().entries.map((e) {
                                final i = e.key;
                                final item = e.value;
                                return _VaultRecentRow(item: item)
                                    .animate(delay: (240 + i * 40).ms)
                                    .fadeIn(duration: 300.ms);
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.headline.copyWith(
                fontSize: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultActionLarge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final String foot;
  final VoidCallback onTap;
  final bool enabled;

  const _VaultActionLarge({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.foot,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: enabled ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: enabled ? 0.35 : 0.12),
              ),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.caption, maxLines: 2),
                const SizedBox(height: 8),
                Text(
                  foot,
                  style: AppTypography.labelCaps.copyWith(
                    color: enabled ? accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            color: enabled
                ? AppColors.textMuted.withValues(alpha: 0.7)
                : AppColors.textMuted.withValues(alpha: 0.35),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _VaultRecentRow extends StatelessWidget {
  final PdfLibraryItem item;

  const _VaultRecentRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 10,
        blurSigma: 20,
        onTap: () =>
            context.push('/viewer?path=${Uri.encodeComponent(item.path)}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.9),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Iconsax.document_text,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open • long-press in Library for lock',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
