import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/xp_ui.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/pdf_pick_open_service.dart';
import '../../../services/pdf_sandbox_service.dart';
import '../widgets/stitch_tool_kit.dart';

/// Tools hub matching Stitch mock (7): hero banner + Create / Modify / Security grids.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _primaryFixedBg = Color(0xFFDBE1FF);
  static const Color _onPrimaryFixedIcon = Color(0xFF00174B);
  static const Color _secondaryFixedBg = Color(0xFFB3EBFF);
  static const Color _onSecondaryFixedIcon = Color(0xFF001F27);
  static const Color _tertiaryFixedBg = Color(0xFFE0E3E5);
  static const Color _onTertiaryFixedIcon = Color(0xFF191C1E);

  Future<void> _blankEditor(BuildContext context) async {
    final path = await PdfSandboxService.createBlankSandboxPdf();
    await PdfLibraryRepository.instance.recordOpened(path);
    if (!context.mounted) return;
    await context.push('/editor?path=${Uri.encodeComponent(path)}');
  }

  List<Widget> _grid(BuildContext context, {required List<Widget> children}) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 920 ? 3 : (w >= 560 ? 2 : 1);
    return [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: cols == 3 ? 0.92 : cols == 2 ? 0.98 : 1.15,
        children: children,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  const XpAmbientBackground(),
                  Positioned(
                    top: -40,
                    left: -40,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerHigh.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpMobileTopBar(
                onMenu: () => showXpMissionMenu(context),
                centerTitle: '',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Container(
                              height: 148,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.surfaceContainerHighest,
                                    AppColors.surfaceContainerLow,
                                    AppColors.primary.withValues(alpha: 0.22),
                                  ],
                                ),
                                boxShadow: AppColors.glassShadow,
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      AppColors.surface.withValues(alpha: 0.93),
                                      AppColors.surface.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tools',
                                      style: AppTypography.display,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Streamline your document workflow.',
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(
                            begin: 0.06,
                            end: 0,
                          ),
                      const SizedBox(height: 28),

                      ToolsSectionHeader(
                        title: 'Create',
                        pillColor: AppColors.primary,
                      ),
                      ..._grid(context, children: [
                        ToolsGridCard(
                          icon: Iconsax.scan,
                          title: 'Scan to PDF',
                          body:
                              'Digitize physical documents into high-quality PDFs instantly.',
                          iconBg: _primaryFixedBg,
                          iconColor: _onPrimaryFixedIcon,
                          onTap: () => context.push('/scan'),
                        ),
                        ToolsGridCard(
                          icon: Iconsax.document_copy,
                          title: 'Merge PDFs',
                          body:
                              'Combine multiple PDFs in order into a single document.',
                          iconBg: _primaryFixedBg,
                          iconColor: _onPrimaryFixedIcon,
                          onTap: () => context.push('/merge-pdfs'),
                        ),
                      ]),

                      const SizedBox(height: 32),
                      ToolsSectionHeader(
                        title: 'Modify',
                        pillColor: AppColors.secondary,
                      ),
                      ..._grid(context, children: [
                        ToolsGridCard(
                          icon: Iconsax.edit,
                          title: 'Edit PDF',
                          body:
                              'Seamlessly modify text, images, and structural layouts.',
                          iconBg: _secondaryFixedBg,
                          iconColor: _onSecondaryFixedIcon,
                          onTap:
                              () => pickPdfAndNavigateEditor(context),
                        ),
                        ToolsGridCard(
                          icon: Iconsax.pen_close,
                          title: 'Annotate',
                          body:
                              'Add highlights, custom comments, and freehand drawings.',
                          iconBg: _secondaryFixedBg,
                          iconColor: _onSecondaryFixedIcon,
                          onTap:
                              () => pickPdfAndNavigateEditor(context),
                        ),
                      ]),

                      const SizedBox(height: 32),
                      ToolsSectionHeader(
                        title: 'Optimize',
                        pillColor: AppColors.success,
                      ),
                      ..._grid(context, children: [
                        ToolsGridCard(
                          icon: Iconsax.document_download,
                          title: 'Compress PDF',
                          body: 'Reduce file size while preserving content quality.',
                          iconBg: AppColors.success.withValues(alpha: 0.2),
                          iconColor: AppColors.success,
                          onTap: () => context.push('/compress'),
                        ),
                      ]),

                      const SizedBox(height: 32),
                      ToolsSectionHeader(
                        title: 'Security',
                        pillColor: AppColors.tertiary,
                      ),
                      ..._grid(context, children: [
                        ToolsGridCard(
                          icon: Iconsax.lock,
                          title: 'PDF Locker',
                          body:
                              'Secure sensitive documents with advanced password encryption.',
                          iconBg: _tertiaryFixedBg,
                          iconColor: _onTertiaryFixedIcon,
                          onTap: () => context.push('/secure'),
                        ),
                      ]),

                      const SizedBox(height: 28),
                      GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.document_text,
                              color: AppColors.primary,
                              size: 26,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick open',
                                    style: AppTypography.label,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Import a PDF to view or start a blank page in the editor.',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed:
                                            () => pickPdfAndNavigateViewer(
                                              context,
                                            ),
                                        child: Text(
                                          'Import PDF',
                                          style: AppTypography.label
                                              .copyWith(
                                                color:
                                                    AppColors.primary,
                                              ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          XpHaptics.surfaceTap();
                                          await _blankEditor(context);
                                        },
                                        child: Text(
                                          'Blank document',
                                          style: AppTypography.label
                                              .copyWith(
                                                color:
                                                    AppColors.primary,
                                              ),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
