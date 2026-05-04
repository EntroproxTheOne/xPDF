import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../services/export_paths.dart';
import '../../../services/pdf_editor_service.dart';
import '../../../services/pdf_export_service.dart';
import '../../../services/pdf_library_repository.dart';

class ExportScreen extends StatefulWidget {
  final String filePath;
  const ExportScreen({super.key, required this.filePath});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

enum _ExportFormat { pdfSubset, pdfSplit, png, jpeg }

class _ExportScreenState extends State<ExportScreen> {
  int? _pageCount;
  Object? _loadError;

  late Set<int> _selectedPages;
  bool _initializedSelection = false;

  _ExportFormat _format = _ExportFormat.pdfSubset;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedPages = {};
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final path = widget.filePath.trim();
    if (path.isEmpty) {
      setState(() => _loadError = 'No file selected.');
      return;
    }

    final f = File(path);
    if (!await f.exists()) {
      setState(() => _loadError = 'PDF not found on device.');
      return;
    }

    final ed = PdfEditorService();
    try {
      await ed.load(path);
      final n = ed.pageCount;
      if (!mounted) return;
      setState(() {
        _pageCount = n;
        _loadError = null;
        if (!_initializedSelection) {
          _selectedPages = {...List.generate(n, (i) => i)};
          _initializedSelection = true;
        }
      });
    } catch (e) {
      setState(() => _loadError = e);
    } finally {
      ed.dispose();
    }
  }

  String get _subtitle {
    final n = _pageCount;
    if (n == null) return '';
    return '${_selectedPages.length} of $n pages selected';
  }

  Future<void> _runExport() async {
    if (_busy) return;
    final n = _pageCount;
    if (n == null || n <= 0) return;

    if (_selectedPages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Select at least one page.', style: AppTypography.body),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    XpHaptics.emphasize();

    try {
      final exportDir = await ExportPaths.ensureExportsDirectory();

      final ascending = (_selectedPages.toList()..sort());
      File? exportedPdf;
      List<File> rasters = const [];

      switch (_format) {
        case _ExportFormat.pdfSubset:
          exportedPdf = await PdfExportService.exportSubsetPdf(
            sourcePath: widget.filePath.trim(),
            zeroBasedIndices: _selectedPages,
            outputDirectory: exportDir,
          );
        case _ExportFormat.pdfSplit:
          rasters = await PdfExportService.exportSplitPdfs(
            sourcePath: widget.filePath.trim(),
            zeroBasedIndices: _selectedPages,
            outputDirectory: exportDir,
          );
        case _ExportFormat.png:
          rasters = await PdfExportService.exportPagesRaster(
            sourcePath: widget.filePath.trim(),
            sortedZeroBasedAscending: ascending,
            format: PdfRasterExportFormat.png,
            outputDirectory: exportDir,
          );
        case _ExportFormat.jpeg:
          rasters = await PdfExportService.exportPagesRaster(
            sourcePath: widget.filePath.trim(),
            sortedZeroBasedAscending: ascending,
            format: PdfRasterExportFormat.jpeg,
            outputDirectory: exportDir,
          );
      }

      if (!mounted) return;

      final xfiles = exportedPdf != null
          ? <XFile>[XFile(exportedPdf.path)]
          : rasters.map((e) => XFile(e.path)).toList(growable: false);

      if (xfiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not build export.', style: AppTypography.body),
          ),
        );
        return;
      }

      final stem = p
          .basename(widget.filePath.trim())
          .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');

      final saveHint = ExportPaths.whereToFindExportedFiles(exportDir);

      await Share.shareXFiles(
        xfiles,
        subject: 'xPDF — $stem',
        text: exportedPdf != null
            ? 'PDF export (${_selectedPages.length} page${_selectedPages.length == 1 ? '' : 's'}) · saved: $saveHint'
            : 'Exported ${_format == _ExportFormat.png ? 'PNG' : 'JPG'} ${_selectedPages.length} page${_selectedPages.length == 1 ? '' : 's'} · $saveHint',
      );

      final primaryPath = exportedPdf?.path ?? rasters.first.path;
      await PdfLibraryRepository.instance.recordOpened(primaryPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Saved ${p.basename(primaryPath)} • $saveHint',
            style: AppTypography.body,
          ),
        ),
      );

      XpHaptics.lightCommit();

      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceContainerHighest,
          content: Text('Export failed: $e', style: AppTypography.body),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleSelectAll() {
    final n = _pageCount ?? 0;
    if (n <= 0) return;
    setState(() {
      if (_selectedPages.length == n) {
        _selectedPages = {};
      } else {
        _selectedPages = {...List.generate(n, (i) => i)};
      }
    });
    XpHaptics.surfaceTap();
  }

  Widget _loadingBody() => Padding(
    padding: const EdgeInsets.all(20),
    child: GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: SizedBox(
        height: 200,
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceContainer,
          highlightColor: AppColors.surfaceContainerHigh,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: GlassAppBar(
        title: 'Export',
        subtitle: _subtitle,
        showBackButton: true,
        actions: [
          if (_pageCount != null && (_pageCount ?? 0) > 0)
            GestureDetector(
              onTap: _toggleSelectAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  _selectedPages.length == _pageCount
                      ? 'Deselect all'
                      : 'Select all',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.orangeAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can’t load this PDF',
                      style: AppTypography.label.copyWith(
                        color: AppColors.redTrim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_loadError!.toString(), style: AppTypography.caption),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() => _loadError = null);
                        _loadDocument();
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: (_pageCount == null && _loadError == null)
                ? _loadingBody()
                : _pageCount == null
                ? const SizedBox.shrink()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _pageCount!,
                    itemBuilder: (context, index) => _thumb(index),
                  ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(top: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Format', style: AppTypography.label),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FormatChip(
                        label: 'PDF',
                        desc: 'New PDF • selected pages',
                        isSelected: _format == _ExportFormat.pdfSubset,
                        onTap: () => setState(() {
                          _format = _ExportFormat.pdfSubset;
                        }),
                      ),
                      const SizedBox(width: 10),
                      _FormatChip(
                        label: 'Split PDF',
                        desc: 'One PDF file per page',
                        isSelected: _format == _ExportFormat.pdfSplit,
                        onTap: () => setState(() {
                          _format = _ExportFormat.pdfSplit;
                        }),
                      ),
                      const SizedBox(width: 10),
                      _FormatChip(
                        label: 'PNG',
                        desc: 'One image per page',
                        isSelected: _format == _ExportFormat.png,
                        onTap: () => setState(() {
                          _format = _ExportFormat.png;
                        }),
                      ),
                      const SizedBox(width: 10),
                      _FormatChip(
                        label: 'JPG',
                        desc: 'Smaller • one file per page',
                        isSelected: _format == _ExportFormat.jpeg,
                        onTap: () =>
                            setState(() => _format = _ExportFormat.jpeg),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Exports save to Documents or Downloads → ${ExportPaths.exportsSubfolder} when possible; the share sheet can copy elsewhere (Drive, Mail, etc.).',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: _formatLabel,
                  icon: Iconsax.export_1,
                  isLoading: _busy,
                  onPressed:
                      (_busy ||
                          (_pageCount ?? 0) == 0 ||
                          _selectedPages.isEmpty)
                      ? null
                      : () => _runExport(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(int index) {
    final isSelected = _selectedPages.contains(index);
    final n = index + 1;

    return GestureDetector(
      onTap: () {
        XpHaptics.surfaceTap();
        setState(() {
          if (isSelected) {
            _selectedPages.remove(index);
          } else {
            _selectedPages.add(index);
          }
        });
      },
      child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.orangeAccent
                    : AppColors.glassBorder,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected ? AppColors.orangeGlowShadow : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Iconsax.document_text,
                    size: 32,
                    color: AppColors.textMuted,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Text(
                    'Page $n',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.orangeAccent,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.orangeAccent
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orangeAccent
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: ((index.clamp(0, 48)) * 40).ms)
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  String get _formatLabel {
    switch (_format) {
      case _ExportFormat.pdfSubset:
        return 'Export PDF (${_selectedPages.length})';
      case _ExportFormat.pdfSplit:
        return 'Split PDFs (${_selectedPages.length})';
      case _ExportFormat.png:
        return 'Export PNG (${_selectedPages.length})';
      case _ExportFormat.jpeg:
        return 'Export JPG (${_selectedPages.length})';
    }
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        XpHaptics.surfaceTap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 132),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orangeAccent.withValues(alpha: 0.2)
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.orangeAccent : AppColors.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isSelected
                    ? AppColors.orangeAccent
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
