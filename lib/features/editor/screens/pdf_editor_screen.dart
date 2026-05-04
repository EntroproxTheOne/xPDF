import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter, Rect, lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../services/pdf_editor_service.dart';
import '../../../services/pdf_library_repository.dart';

class PdfEditorScreen extends StatefulWidget {
  final String filePath;
  const PdfEditorScreen({super.key, required this.filePath});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  final PdfEditorService _editor = PdfEditorService();

  bool _loading = true;
  Uint8List? _previewBytes;
  int _previewRev = 0;
  bool _reorderMode = false;
  bool _highlightMode = false;
  bool _drawMode = false;

  List<Offset> _currentStroke = [];
  int? _currentStrokePage;

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: error
            ? AppColors.redTrim.withValues(alpha: 0.92)
            : AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
    );
  }

  void _reloadPreview() {
    if (!_editor.hasDocument) {
      _previewBytes = null;
      return;
    }
    _previewBytes = Uint8List.fromList(_editor.snapshotBytesSync());
    _previewRev++;
  }

  String? _errorMessage;
  int? _selectedIndex;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _selectedIndex = null;
      _previewBytes = null;
    });
    try {
      if (widget.filePath.trim().isEmpty ||
          !File(widget.filePath.trim()).existsSync()) {
        throw ArgumentError(
          widget.filePath.isEmpty
              ? 'No path supplied.'
              : 'That PDF cannot be accessed.',
        );
      }
      await _editor.load(widget.filePath);
      if (_editor.pageCount > 0) {
        _selectedIndex = 0;
      }
      _reloadPreview();
    } catch (error) {
      _errorMessage = error.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }



  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  Future<void> _saveCopy() async {
    try {
      final outPath = await _editor.saveCopyNextToOriginal();
      await PdfLibraryRepository.instance.recordOpened(outPath);
      if (!mounted) return;
      _toast('Saved revised copy beside the original.');
      final encoded = Uri.encodeComponent(outPath);
      context.pop();
      if (!mounted) return;
      final path = GoRouterState.of(context).uri.path;
      if (path == '/viewer') {
        context.go('/viewer?path=$encoded');
      } else {
        context.push('/viewer?path=$encoded');
      }
    } catch (error) {
      if (!mounted) return;
      _toast('Unable to save: $error', error: true);
    }
  }

  Future<void> _extractPage() async {
    final sel = _selectedIndex;
    if (!_editor.hasDocument || sel == null) return;
    try {
      final out = await _editor.exportSinglePagePdf(sel);
      await Share.shareXFiles([XFile(out)], text: 'Single-page excerpt');
    } catch (error) {
      if (!mounted) return;
      _toast('Extract failed: $error', error: true);
    }
  }

  void _handlePreviewTap({
    required int pageIndexZero,
    required Size viewportSize,
    required Offset local,
  }) {
    final media = _editor.pageMediaSize(pageIndexZero);
    if (media.width <= 0 || media.height <= 0) return;

    final s = math.min(
      viewportSize.width / media.width,
      viewportSize.height / media.height,
    );
    final scaledW = media.width * s;
    final scaledH = media.height * s;
    final ox = (viewportSize.width - scaledW) / 2;
    final oy = (viewportSize.height - scaledH) / 2;

    if (local.dx < ox ||
        local.dy < oy ||
        local.dx > ox + scaledW ||
        local.dy > oy + scaledH) {
      return;
    }

    final pdfOffset = Offset(
      (local.dx - ox) / s,
      (local.dy - oy) / s,
    );

    final hit = _editor.findWordAtPdfPoint(pageIndexZero, pdfOffset, media);
    if (hit == null || hit.text.trim().isEmpty) {
      _toast('No extractable text at that spot. Try nearer the characters.');
      return;
    }

    XpHaptics.surfaceTap();
    _openWordEditor(pageIndexZero, hit);
  }

  void _handleHighlightTap(BuildContext tapCtx, Offset globalPos, int pageIndexZero) {
    final rb = tapCtx.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final local = rb.globalToLocal(globalPos);
    
    final media = _editor.pageMediaSize(pageIndexZero);
    if (media.width <= 0 || media.height <= 0) return;

    final s = math.min(rb.size.width / media.width, rb.size.height / media.height);
    final scaledW = media.width * s;
    final scaledH = media.height * s;
    final ox = (rb.size.width - scaledW) / 2;
    final oy = (rb.size.height - scaledH) / 2;

    if (local.dx < ox || local.dy < oy || local.dx > ox + scaledW || local.dy > oy + scaledH) return;

    final pdfOffset = Offset((local.dx - ox) / s, (local.dy - oy) / s);
    
    _editor.highlightWordAtPoint(pageIndexZero, pdfOffset, media);
    XpHaptics.surfaceTap();
    setState(() {
      _reloadPreview();
      _selectedIndex = pageIndexZero;
    });
  }

  void _commitStroke(BuildContext tapCtx, int pageIndexZero) {
    if (_currentStroke.length < 2) {
      setState(() {
        _currentStroke.clear();
        _currentStrokePage = null;
      });
      return;
    }
    
    final rb = tapCtx.findRenderObject() as RenderBox?;
    if (rb == null) return;
    
    final media = _editor.pageMediaSize(pageIndexZero);
    if (media.width <= 0 || media.height <= 0) return;

    final s = math.min(rb.size.width / media.width, rb.size.height / media.height);
    final scaledW = media.width * s;
    final scaledH = media.height * s;
    final ox = (rb.size.width - scaledW) / 2;
    final oy = (rb.size.height - scaledH) / 2;

    final pdfPoints = _currentStroke.map((local) {
      return Offset((local.dx - ox) / s, (local.dy - oy) / s);
    }).toList();

    _editor.drawPathOnPage(pageIndexZero, pdfPoints, Colors.red, 4.0);
    
    XpHaptics.surfaceTap();
    setState(() {
      _currentStroke.clear();
      _currentStrokePage = null;
      _reloadPreview();
    });
  }

  void _applyPageNumbers() {
    _editor.stampPageNumbers();
    _toast('Page numbers applied');
    XpHaptics.lightCommit();
    _reloadPreview();
  }

  Future<void> _applyWatermark() async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Watermark', style: AppTypography.title),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'e.g. CONFIDENTIAL',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: AppTypography.label),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Apply', style: AppTypography.label),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      _editor.stampWatermark(result.trim());
      _toast('Watermark applied');
      XpHaptics.lightCommit();
      _reloadPreview();
    }
  }

  Future<void> _openWordEditor(int pageIndex, TextWord word) async {
    final ctrl = TextEditingController(text: word.text);
    final fz = word.fontSize > 2 ? word.fontSize.toStringAsFixed(1) : '—';

    try {
      await GlassBottomSheet.show<void>(
        context: context,
        maxHeightFraction: 0.55,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            MediaQuery.paddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom +
                18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit text', style: AppTypography.label),
              const SizedBox(height: 6),
              Text(
                'Uses ${word.fontName.isEmpty ? 'standard' : word.fontName} '
                '~$fz pt (best match). Replacements do not auto-reflow paragraphs.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                controller: ctrl,
                maxLines: null,
                style: AppTypography.body,
                decoration: const InputDecoration(hintText: 'New wording'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: () {
                        XpHaptics.primaryCta();
                        _editor.replaceExtractedWord(
                          pageIndex,
                          word,
                          ctrl.text,
                        );
                        Navigator.pop(context);
                        if (!mounted) return;
                        setState(() {
                          _reloadPreview();
                          _selectedIndex = pageIndex;
                        });
                        _toast('Text updated.');
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _redactPrompt() async {
    final sel = _selectedIndex;
    if (!_editor.hasDocument || sel == null) return;

    final left = TextEditingController(text: '40');
    final top = TextEditingController(text: '620');
    final widthCtrl = TextEditingController(text: '200');
    final heightCtrl = TextEditingController(text: '40');

    await GlassBottomSheet.show<void>(
      context: context,
      maxHeightFraction: 0.55,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom +
              18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'White cover (page ${_selectedIndex! + 1})',
                style: AppTypography.label,
              ),
              const SizedBox(height: 6),
              Text(
                'PDF coordinates · best-effort mask',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              _miniField(left, hint: 'Left'),
              const SizedBox(height: 8),
              _miniField(top, hint: 'Top'),
              const SizedBox(height: 8),
              _miniField(widthCtrl, hint: 'Width'),
              const SizedBox(height: 8),
              _miniField(heightCtrl, hint: 'Height'),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () {
                  double parse(String txt) =>
                      double.tryParse(txt.trim().replaceAll(',', '.')) ?? 0;
                  final rect = Rect.fromLTWH(
                    parse(left.text),
                    parse(top.text),
                    parse(widthCtrl.text),
                    parse(heightCtrl.text),
                  );
                  Navigator.pop(context);
                  _editor.coverRectangle(sel, rect);
                  if (!mounted) return;
                  setState(() {
                    _reloadPreview();
                  });
                  _toast('Applied white cover.');
                },
                child: const Text('Stamp cover rectangle'),
              ),
            ],
          ),
        ),
      ),
    );
    left.dispose();
    top.dispose();
    widthCtrl.dispose();
    heightCtrl.dispose();
  }

  Widget _miniField(TextEditingController c, {required String hint}) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: hint),
      style: AppTypography.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppColors.surfaceContainer,
                      highlightColor: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.55,
                      ),
                      child: Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Shimmer.fromColors(
                      baseColor: AppColors.surfaceContainer,
                      highlightColor: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.55,
                      ),
                      child: Container(
                        height: 8,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Preparing editor…',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || !_editor.hasDocument) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: GlassAppBar(
          title: 'PDF Editor',
          subtitle: 'Load problem',
          showBackButton: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _errorMessage ?? 'No document ready.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pageCount = _editor.pageCount;
    final previewBytes = _previewBytes!;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: GlassAppBar(
        title: 'PDF Editor',
        subtitle: _reorderMode
            ? '$pageCount pages · drag ☰ to reorder · long-press to exit'
            : _drawMode
                ? '$pageCount pages · drag on page to draw red stroke'
                : _highlightMode
                    ? '$pageCount pages · tap text to highlight'
                    : '$pageCount pages · double-tap text to edit · long-press page to reorder',
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  XpHaptics.primaryCta();
                  _saveCopy();
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppColors.glassShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      'Save copy',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.42),
                  border: Border(
                    bottom: BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _toolbarIcon(
                          icon: Iconsax.add_circle,
                          label: 'Blank',
                          onTap: () {
                            _editor.insertBlankAtEnd();
                            setState(_reloadPreview);
                          },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.trash,
                          label: 'Delete',
                          color: AppColors.error,
                          onTap: (_selectedIndex == null || pageCount <= 1)
                              ? null
                              : () {
                                  _editor.deletePage(_selectedIndex!);
                                  setState(() {
                                    if (!_editor.hasDocument ||
                                        _editor.pageCount == 0) {
                                      _selectedIndex = null;
                                    } else {
                                      final next =
                                          (_selectedIndex! >
                                              _editor.pageCount - 1)
                                          ? _editor.pageCount - 1
                                          : _selectedIndex!;
                                      _selectedIndex = next;
                                    }
                                    _reloadPreview();
                                  });
                                },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.export_1,
                          label: 'Extract',
                          onTap: _extractPage,
                        ),
                        _toolbarIcon(
                          icon: Iconsax.document_copy,
                          label: 'Dup',
                          onTap: _selectedIndex == null
                              ? null
                              : () {
                                  _editor.duplicatePage(_selectedIndex!);
                                  setState(_reloadPreview);
                                },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.rotate_left,
                          label: 'Rotate',
                          onTap: _selectedIndex == null
                              ? null
                              : () {
                                  _editor.rotatePageClockwise(
                                    _selectedIndex!,
                                  );
                                  setState(_reloadPreview);
                                },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.square,
                          label: 'Cover…',
                          onTap: _redactPrompt,
                        ),
                        _toolbarIcon(
                          icon: Iconsax.brush_2,
                          label: 'Pen',
                          color: _drawMode ? AppColors.primary : null,
                          onTap: () {
                            setState(() {
                              _drawMode = !_drawMode;
                              if (_drawMode) {
                                _highlightMode = false;
                                _reorderMode = false;
                              }
                            });
                          },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.magic_star,
                          label: 'Highlight',
                          color: _highlightMode ? AppColors.primary : null,
                          onTap: () {
                            setState(() {
                              _highlightMode = !_highlightMode;
                              if (_highlightMode) {
                                _drawMode = false;
                                _reorderMode = false;
                              }
                            });
                          },
                        ),
                        _toolbarIcon(
                          icon: Iconsax.document_text_1,
                          label: 'Numbers',
                          onTap: _applyPageNumbers,
                        ),
                        _toolbarIcon(
                          icon: Iconsax.security,
                          label: 'Watermark',
                          onTap: _applyWatermark,
                        ),
                        _toolbarIcon(
                          icon: Iconsax.arrow_down_2,
                          label: 'Help',
                          color: AppColors.primary,
                          onTap: _showDisclaimer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: KeyedSubtree(
                key: ValueKey<int>(_previewRev),
                child: PdfDocumentViewBuilder(
                  documentRef: PdfDocumentRefData(
                    previewBytes,
                    sourceName: 'xpdf_editor_prev_$_previewRev',
                    allowDataOwnershipTransfer: false,
                    useProgressiveLoading: false,
                  ),
                  builder: (ctx, pdf) {
                    if (pdf == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final maxThumbH = constraints.maxHeight > 620
                            ? 420.0
                            : 320.0;
                        final minThumbH = 200.0;
                        final tileH = tileHeightForViewport(
                          maxWidth: constraints.maxWidth - 72,
                          minH: minThumbH,
                          maxH: math.min(maxThumbH, constraints.maxHeight),
                        );

                        return ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            100,
                          ),
                          physics: const BouncingScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: pageCount,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, _) {
                                final t =
                                    Curves.easeOut.transform(animation.value);
                                return Transform.scale(
                                  scale: lerpDouble(1, 1.02, t)!,
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: lerpDouble(0, 6, t)!,
                                    shadowColor: AppColors.primary.withValues(
                                      alpha: 0.28,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: child,
                                  ),
                                );
                              },
                            );
                          },
                          onReorder: (oldIdx, newIdx) {
                            if (newIdx > oldIdx) newIdx--;
                            _editor.movePage(oldIdx, newIdx);
                            setState(() {
                              _selectedIndex = newIdx;
                              _reloadPreview();
                            });
                          },
                          itemBuilder: (context, index) {
                            final sel = index == _selectedIndex;
                            final hThumb =
                                (tileH - 52).clamp(170.0, 340.0).toDouble();

                            return Padding(
                              key: ValueKey<String>(
                                '${_previewRev}_slot_$index',
                              ),
                              padding:
                                  const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (_reorderMode)
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Tooltip(
                                        message:
                                            'Hold and drag up/down to reorder',
                                        child: Material(
                                          color: AppColors
                                              .surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: const SizedBox(
                                            width: 44,
                                            height: 56,
                                            child: Icon(
                                              Icons.drag_handle_rounded,
                                              color:
                                                  AppColors.textMuted,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_reorderMode)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child:
                                        AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.backgroundSecondary,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: sel
                                              ? AppColors.primary
                                              : AppColors.glassBorder,
                                          width: sel ? 2 : 1,
                                        ),
                                        boxShadow: sel
                                            ? AppColors.glassShadow
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                                  14,
                                                  10,
                                                  14,
                                                  6,
                                                ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Page ${index + 1}',
                                                  style: AppTypography
                                                      .label,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    sel
                                                        ? (_reorderMode
                                                            ? 'Selected · drag ☰ to reorder'
                                                            : _drawMode
                                                                ? 'Selected · drag to draw red stroke'
                                                                : _highlightMode
                                                                    ? 'Selected · tap text to highlight'
                                                                    : 'Selected · double-tap text to edit')
                                                        : (_reorderMode
                                                            ? 'Tap to select · drag ☰ to reorder'
                                                            : 'Long-press to reorder · double-tap text to edit'),
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors
                                                          .textMuted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Divider(
                                            height: 1,
                                            color: AppColors
                                                .outlineVariant
                                                .withValues(
                                                  alpha: 0.85,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(14),
                                            child: SizedBox(
                                              height: hThumb,
                                              width:
                                                  double.infinity,
                                              child: Builder(
                                                builder: (tapCtx) {
                                                  return GestureDetector(
                                                    behavior:
                                                        HitTestBehavior
                                                            .opaque,
                                                    onTap: () {
                                                      setState(() =>
                                                          _selectedIndex =
                                                              index);
                                                      XpHaptics
                                                          .surfaceTap();
                                                    },
                                                    onTapUp: (_highlightMode && !_reorderMode)
                                                        ? (details) {
                                                            _handleHighlightTap(tapCtx, details.globalPosition, index);
                                                          }
                                                        : null,
                                                    onPanStart: (_drawMode && !_reorderMode)
                                                        ? (details) {
                                                            setState(() {
                                                              _selectedIndex = index;
                                                              _currentStrokePage = index;
                                                              final rb = tapCtx.findRenderObject() as RenderBox?;
                                                              if (rb != null) {
                                                                _currentStroke = [rb.globalToLocal(details.globalPosition)];
                                                              }
                                                            });
                                                          }
                                                        : null,
                                                    onPanUpdate: (_drawMode && !_reorderMode && _currentStrokePage == index)
                                                        ? (details) {
                                                            setState(() {
                                                              final rb = tapCtx.findRenderObject() as RenderBox?;
                                                              if (rb != null) {
                                                                _currentStroke.add(rb.globalToLocal(details.globalPosition));
                                                              }
                                                            });
                                                          }
                                                        : null,
                                                    onPanEnd: (_drawMode && !_reorderMode && _currentStrokePage == index)
                                                        ? (details) {
                                                            _commitStroke(tapCtx, index);
                                                          }
                                                        : null,
                                                    onLongPress: () {
                                                      XpHaptics
                                                          .primaryCta();
                                                      setState(() {
                                                        _reorderMode =
                                                            !_reorderMode;
                                                        if (_reorderMode) {
                                                          _drawMode = false;
                                                          _highlightMode = false;
                                                        }
                                                        _selectedIndex =
                                                            index;
                                                      });
                                                    },
                                                    onDoubleTapDown:
                                                        (_reorderMode || _highlightMode || _drawMode)
                                                            ? null
                                                            : (details) {
                                                                final rb =
                                                                    tapCtx
                                                                            .findRenderObject()
                                                                        as RenderBox?;
                                                                if (rb ==
                                                                    null) {
                                                                  return;
                                                                }
                                                                setState(() =>
                                                                    _selectedIndex =
                                                                        index);
                                                                XpHaptics
                                                                    .surfaceTap();
                                                                final local =
                                                                    rb.globalToLocal(
                                                                  details
                                                                      .globalPosition,
                                                                );
                                                                _handlePreviewTap(
                                                                  pageIndexZero:
                                                                      index,
                                                                  viewportSize:
                                                                      rb.size,
                                                                  local:
                                                                      local,
                                                                );
                                                              },
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        IgnorePointer(
                                                          child:
                                                              PdfPageView(
                                                        document:
                                                            pdf,
                                                        pageNumber:
                                                            index +
                                                                1,
                                                        maximumDpi:
                                                            138,
                                                        backgroundColor:
                                                            Colors.white,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.white,
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              blurRadius: 6,
                                                              offset:
                                                                  Offset(
                                                                      2,
                                                                      4),
                                                              color:
                                                                  Colors.black26,
                                                            ),
                                                          ],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8),
                                                        ),
                                                        pageSizeCallback:
                                                            (
                                                              biggest,
                                                              page,
                                                            ) {
                                                          final s =
                                                              math.min(
                                                            138 / 72,
                                                            math.min(
                                                              biggest.width /
                                                                  page.width,
                                                              biggest.height /
                                                                  page.height,
                                                            ),
                                                          );
                                                          final w =
                                                              page.width *
                                                                  s;
                                                          final h =
                                                              page.height *
                                                                  s;
                                                          return Size(
                                                              w,
                                                              h);
                                                        },
                                                      ),
                                                    ),
                                                    if (_drawMode && _currentStrokePage == index && _currentStroke.isNotEmpty)
                                                      CustomPaint(
                                                        painter: _StrokePainter(_currentStroke, Colors.red, 4.0),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double tileHeightForViewport({
    required double maxWidth,
    required double minH,
    required double maxH,
  }) {
    final inferred = math.min(maxWidth * 1.16 + 112, maxH).clamp(minH, maxH);
    return inferred.toDouble();
  }

  Widget _toolbarIcon({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap == null
              ? null
              : () {
                  XpHaptics.surfaceTap();
                  onTap();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color ?? AppColors.textSecondary, size: 21),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDisclaimer() => GlassBottomSheet.show<void>(
        context: context,
        maxHeightFraction: 0.55,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editing limits', style: AppTypography.label),
              const SizedBox(height: 12),
              Text(
                '• Structural edits stay reliable.\n'
                '• Double-tap a word on its page thumbnail to edit it — we match size & Bold/Italic on standard fonts.\n'
                '• Custom/embedded fonts may fall back visually; edits don\'t reflow whole paragraphs.\n'
                '• Long-press any page to toggle reorder mode. In reorder mode, drag ☰ handles to move pages.\n'
                '• Long-press again (or tap outside) to return to normal viewing mode.',
                style: AppTypography.bodySmall.copyWith(
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StrokePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double width;
  _StrokePainter(this.points, this.color, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
