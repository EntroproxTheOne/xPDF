import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/pdf/pdf_view_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../models/pdf_library_item.dart';
import '../../../services/pdf_library_repository.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _viewerController = PdfViewerController();

  PdfReadingThemeEnum _readingMode = PdfLibraryRepository.instance
      .getReadingTheme();
  bool _fullscreen = false;
  int _pageCount = 0;
  int _currentPage = 1;

  bool get _pathValid {
    final p = widget.filePath.trim();
    if (p.isEmpty) return false;
    return File(p).existsSync();
  }

  @override
  void initState() {
    super.initState();
    if (_pathValid) {
      PdfLibraryRepository.instance.recordOpened(widget.filePath);
    }
  }

  Future<void> _openReadingThemeSelector() async {
    final repo = PdfLibraryRepository.instance;
    final selected = await GlassBottomSheet.show<PdfReadingThemeEnum>(
      context: context,
      maxHeightFraction: 0.55,
      child: Builder(
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reading theme', style: AppTypography.label),
                const SizedBox(height: 4),
                Text(
                  'Applies to the page preview only—no reflow.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ...PdfReadingThemeEnum.values.map(
                  (m) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(switch (m) {
                      PdfReadingThemeEnum.light => 'Light (original colors)',
                      PdfReadingThemeEnum.dark => 'Dark (inverted raster)',
                      PdfReadingThemeEnum.system => 'Match system brightness',
                    }, style: AppTypography.body),
                    leading: Icon(
                      switch (m) {
                        PdfReadingThemeEnum.light => Iconsax.sun_1,
                        PdfReadingThemeEnum.dark => Iconsax.moon,
                        PdfReadingThemeEnum.system => Iconsax.mobile,
                      },
                      color: _readingMode == m
                          ? AppColors.orangeAccent
                          : AppColors.textMuted,
                    ),
                    trailing: _readingMode == m
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.orangeAccent,
                            size: 22,
                          )
                        : null,
                    onTap: () => Navigator.pop(sheetContext, m),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() => _readingMode = selected);
      await repo.setReadingTheme(selected);
    }
  }

  Future<void> _jumpToStripPage(int humanIndex) async {
    XpHaptics.surfaceTap();
    await _viewerController.goToPage(
      pageNumber: humanIndex,
      duration: const Duration(milliseconds: 280),
      anchor: PdfPageAnchor.center,
    );
  }

  Future<void> _toggleFullscreen() async {
    XpHaptics.emphasize();
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_pathValid) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: GlassAppBar(
          title: 'PDF Viewer',
          subtitle: 'Nothing to preview',
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.folder_cross,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.filePath.isEmpty
                        ? 'No PDF path was provided.'
                        : 'That PDF path is unavailable on this device.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final colorFilter = PdfReadingThemeMatrices.effectiveFilter(
      _readingMode,
      platformBrightness,
    );
    final canvasTint = PdfReadingThemeMatrices.viewerCanvasBackground(
      _readingMode,
      platformBrightness,
    );
    final subtitle = _viewerController.isReady && _pageCount > 0
        ? '$_pageCount pages · Page $_currentPage of $_pageCount'
        : 'Opening…';

    /// Isolate heavy raster work from chrome repaints; avoid wrapping the scaffold.
    final viewerCore = RepaintBoundary(
      child: PdfViewer.file(
        widget.filePath,
        controller: _viewerController,
        params: PdfViewerParams(
          backgroundColor: canvasTint,

          /// Page shadow tuned for light Lumina chrome.
          pageDropShadow: BoxShadow(
            color: const Color(0xFF002864).withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          onViewerReady: (document, ctrl) async {
            await PdfLibraryRepository.instance.recordOpened(widget.filePath);
            if (!mounted) return;
            setState(() {
              _pageCount = document.pages.length;
              _currentPage = ctrl.pageNumber ?? 1;
            });
          },

          /// Page-only updates — do not attach a listener to [PdfViewerController];
          /// it notifies on every zoom/pan matrix change and would rebuild the whole shell.
          onPageChanged: (pageNumber) {
            if (!mounted || pageNumber == null) return;
            if (pageNumber != _currentPage) {
              setState(() => _currentPage = pageNumber);
            }
          },
        ),
      ),
    );

    final viewerBody = colorFilter != null
        ? ColorFiltered(colorFilter: colorFilter, child: viewerCore)
        : viewerCore;

    final thumbStrip =
        !_fullscreen && _viewerController.isReady && _pageCount > 0
        ? _ThumbnailStrip(
            key: ValueKey<String>(widget.filePath),
            count: _pageCount,
            current: _currentPage,
            onSelect: _jumpToStripPage,
          )
        : null;

    final chrome = Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      extendBodyBehindAppBar: false,
      appBar: !_fullscreen
          ? GlassAppBar(
              title: PdfLibraryItem.pdfTitleFromPath(widget.filePath),
              subtitle: subtitle,
              showBackButton: true,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              actions: [
                _GlassIconBtn(
                  icon: Iconsax.paintbucket,
                  hint: 'Reading theme',
                  onTap: _openReadingThemeSelector,
                ),
                const SizedBox(width: 8),
                _GlassIconBtn(
                  icon: Icons.fullscreen,
                  hint: 'Fullscreen',
                  onTap: _toggleFullscreen,
                ),
                const SizedBox(width: 8),
                _GlassIconBtn(
                  icon: Iconsax.edit,
                  hint: 'Edit PDF',
                  onTap: () {
                    XpHaptics.navTap();
                    context.push(
                      '/editor?path=${Uri.encodeComponent(widget.filePath)}',
                    );
                  },
                ),
                const SizedBox(width: 8),
                _GlassIconBtn(
                  icon: Iconsax.export_1,
                  hint: 'Export PDF',
                  onTap: () {
                    XpHaptics.navTap();
                    context.push(
                      '/export?path=${Uri.encodeComponent(widget.filePath)}',
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: _fullscreen
          ? _FullscreenGlassBar(
              onExit: _toggleFullscreen,
              onTheme: _openReadingThemeSelector,
              onEdit: () {
                XpHaptics.navTap();
                context.push(
                  '/editor?path=${Uri.encodeComponent(widget.filePath)}',
                );
              },
              onExport: () {
                XpHaptics.navTap();
                context.push(
                  '/export?path=${Uri.encodeComponent(widget.filePath)}',
                );
              },
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: SafeArea(
          key: ValueKey<bool>(_fullscreen),
          top: false,
          bottom: !_fullscreen,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, _fullscreen ? 8 : 6, 12, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow.withValues(
                        alpha: 0.88,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.8),
                      ),
                      boxShadow: AppColors.glassShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: viewerBody,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child:
                    thumbStrip ??
                    const SizedBox(
                      key: ValueKey<String>('no_strip'),
                      height: 0,
                      width: double.infinity,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    return chrome;
  }
}

class _FullscreenGlassBar extends StatelessWidget {
  const _FullscreenGlassBar({
    required this.onExit,
    required this.onTheme,
    required this.onEdit,
    required this.onExport,
  });

  final VoidCallback onExit;
  final VoidCallback onTheme;
  final VoidCallback onEdit;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: AppColors.glassShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Exit fullscreen',
                  onPressed: onExit,
                  icon: Icon(
                    Icons.fullscreen_exit,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Reading theme',
                  onPressed: onTheme,
                  icon: Icon(
                    Iconsax.paintbucket,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: Icon(Iconsax.edit, color: AppColors.onSurfaceVariant),
                ),
                IconButton(
                  tooltip: 'Export',
                  onPressed: onExport,
                  icon: Icon(
                    Iconsax.export_1,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the active thumbnail in view; uses post-frame math only when [current] changes.
class _ThumbnailStrip extends StatefulWidget {
  const _ThumbnailStrip({
    super.key,
    required this.count,
    required this.current,
    required this.onSelect,
  });

  final int count;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  State<_ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<_ThumbnailStrip> {
  final ScrollController _scroll = ScrollController();

  /// Tile width + horizontal margins (`52 + 6*2`).
  static const double _stride = 64;

  @override
  void didUpdateWidget(covariant _ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _scrollToThumb();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToThumb());
  }

  void _scrollToThumb() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final i = (widget.current - 1).clamp(0, widget.count - 1);
      final target = i * _stride;
      final view = _scroll.position.viewportDimension;
      final max = _scroll.position.maxScrollExtent;
      final centered = (target - view / 2 + _stride / 2).clamp(0.0, max);
      _scroll.animateTo(
        centered,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('strip'),
      height: 92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: widget.count,
          itemBuilder: (context, i) {
            final page = i + 1;
            final selected = page == widget.current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onSelect(page),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.orangeAccent.withValues(alpha: 0.12)
                          : AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.orangeAccent
                            : AppColors.glassBorder,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected ? AppColors.glassShadow : null,
                    ),
                    child: Text(
                      '$page',
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? AppColors.orangeAccent
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String hint;
  final VoidCallback onTap;

  const _GlassIconBtn({
    required this.icon,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.9),
              ),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }
}
