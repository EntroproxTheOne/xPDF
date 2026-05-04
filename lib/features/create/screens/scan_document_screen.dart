import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../../../services/ocr_service.dart';
import '../../../services/pdf_creation_service.dart';
import '../../../services/scanner_service.dart';

/// Live capture + gallery import via native document scanner (`cunning_document_scanner`).
/// Post-process: ML Kit OCR and PDF assembly from scanned page images.
class ScanDocumentScreen extends StatefulWidget {
  const ScanDocumentScreen({super.key});

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> {
  final _scannerService = ScannerService();
  final _pdfService = PdfCreationService();

  List<String> _scannedPaths = [];
  bool _scannerBusy = false;
  bool _pdfBusy = false;
  double? _pdfProgress;
  bool _ocrBusy = false;
  String? _errorMessage;

  /// Copy native scanner outputs into app storage immediately. The plugin often
  /// writes to cache paths that may not survive returning to Flutter or a
  /// second scan batch; staging avoids "one page" PDFs when only the last file remains.
  Future<List<String>> _stageScannedImages(List<String> sources) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'xpdf_scan_sessions'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final batchId = DateTime.now().millisecondsSinceEpoch;
    final out = <String>[];
    for (var i = 0; i < sources.length; i++) {
      final srcPath = sources[i];
      final src = File(srcPath);
      if (!await src.exists()) continue;
      final ext = p.extension(srcPath).isNotEmpty ? p.extension(srcPath) : '.jpg';
      final destPath = p.join(dir.path, 'page_${batchId}_$i$ext');
      await src.copy(destPath);
      out.add(destPath);
    }
    return out;
  }

  Future<void> _clearCapturedPages() async {
    final copy = [..._scannedPaths];
    for (final path in copy) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    if (mounted) setState(() => _scannedPaths = []);
  }

  Future<void> _startScanSession() async {
    setState(() {
      _scannerBusy = true;
      _errorMessage = null;
    });
    try {
      final paths = await _scannerService.scanDocuments(
        galleryImportAllowed: true,
      );

      if (!mounted) return;

      if (paths == null || paths.isEmpty) {
        setState(() => _scannerBusy = false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              paths == null
                  ? 'Scan cancelled'
                  : 'No pages captured — try again',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            backgroundColor: AppColors.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final staged = await _stageScannedImages(paths);
      if (!mounted) return;

      setState(() {
        _scannerBusy = false;
        _scannedPaths = [..._scannedPaths, ...staged];
      });

      if (staged.length < paths.length && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              'Some pages could not be saved (${staged.length}/${paths.length}). Others were added.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      } else if (staged.isNotEmpty && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              staged.length == 1
                  ? 'Added 1 page (${_scannedPaths.length} total)'
                  : 'Added ${staged.length} pages (${_scannedPaths.length} total)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceContainer,
          ),
        );
      }

      if (staged.isEmpty && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              'Scanned files were not reachable — try scanning again.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorStrong.withValues(alpha: 0.9),
          ),
        );
      }
    } on ScannerPermissionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scannerBusy = false;
        _errorMessage = e.message;
      });
      _showPermissionSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scannerBusy = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPermissionSnackBar(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: AppColors.orangeAccent,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Future<void> _runOcrConcat() async {
    if (_scannedPaths.isEmpty) return;

    setState(() => _ocrBusy = true);
    try {
      final text = await OcrService().recognizeLatinConcat(_scannedPaths);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 48),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppColors.redTrim.withValues(alpha: 0.55),
                ),
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.55,
                minChildSize: 0.35,
                maxChildSize: 0.92,
                builder: (ctx, scroll) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXTRACTED TEXT',
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: text.isEmpty
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: text),
                                    );
                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.maybeOf(
                                      ctx,
                                    )?.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Copied',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.onSurface,
                                              ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            AppColors.surfaceContainer,
                                      ),
                                    );
                                  },
                            child: Text(
                              'COPY ALL',
                              style: AppTypography.navLabel.copyWith(
                                color: AppColors.orangeAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: text.isEmpty
                            ? Center(
                                child: Text(
                                  'No text detected — try sharper lighting.',
                                  style: AppTypography.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : SingleChildScrollView(
                                controller: scroll,
                                child: SelectableText(
                                  text,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'OCR failed: $e',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorStrong.withValues(alpha: 0.9),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  Future<void> _buildPdf() async {
    if (_scannedPaths.isEmpty) return;

    setState(() {
      _pdfBusy = true;
      _pdfProgress = 0;
    });

    try {
      final pdfPath = await _pdfService.buildPdfFromImagePaths(
        _scannedPaths,
        onProgress: (value) {
          if (mounted) setState(() => _pdfProgress = value);
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'PDF saved (${p.basename(pdfPath)})',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceContainer,
        ),
      );

      await context.push('/viewer?path=${Uri.encodeComponent(pdfPath)}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Could not create PDF: $e',
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorStrong.withValues(alpha: 0.9),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pdfBusy = false;
          _pdfProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const GlassAppBar(
        title: 'Scan Document',
        subtitle: 'Native auto-crop, perspective correction & filters',
        showBackButton: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: _scannedPaths.isEmpty
                    ? const _HintsPanel()
                    : _ResultsPanel(paths: _scannedPaths),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(context).padding.bottom + 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null && _scannedPaths.isEmpty) ...[
                      Text(
                        _errorMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.redTrim,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    GradientButton(
                      label: _scannedPaths.isEmpty
                          ? 'Start native scanner'
                          : 'Scan more pages',
                      icon: Iconsax.camera,
                      isLoading: _scannerBusy || _ocrBusy || _pdfBusy,
                      onPressed: (_scannerBusy || _ocrBusy || _pdfBusy)
                          ? null
                          : _startScanSession,
                    ),
                    const SizedBox(height: 12),
                    RedTrimButton(
                      label: 'Import from gallery (same flow)',
                      icon: Iconsax.gallery,
                      height: 50,
                      onPressed: (_scannerBusy || _ocrBusy || _pdfBusy)
                          ? null
                          : _startScanSession,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Each scan adds to the reel (not replacing). Confirm all pages in the native UI, then build one PDF.',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                    if (_scannedPaths.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Create PDF (${_scannedPaths.length})',
                        icon: Iconsax.document,
                        isExpanded: true,
                        isLoading: _pdfBusy,
                        onPressed: (_pdfBusy || _scannerBusy)
                            ? null
                            : _buildPdf,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: (_ocrBusy || _pdfBusy || _scannerBusy)
                            ? null
                            : _runOcrConcat,
                        icon: Icon(
                          Iconsax.text,
                          color: AppColors.orangeAccent,
                          size: 18,
                        ),
                        label: Text(
                          'Extract text (on-device OCR)',
                          style: AppTypography.navLabel.copyWith(
                            color: AppColors.orangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: (_ocrBusy || _pdfBusy || _scannerBusy)
                            ? null
                            : _clearCapturedPages,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          side: BorderSide(color: AppColors.glassBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Clear pages',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_pdfBusy)
            ProgressOverlay(
              message: 'Building PDF…',
              progress: _pdfProgress ?? 0.0,
              detail:
                  '${((_pdfProgress ?? 0).clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
            )
          else if (_scannerBusy || _ocrBusy)
            ProgressOverlay(
              message: _ocrBusy ? 'Reading text…' : 'Opening scanner…',
              progress: null,
              detail: _scannerBusy
                  ? 'Use the fullscreen native capture UI.'
                  : null,
            ),
        ],
      ),
    );
  }
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.scan, size: 48, color: AppColors.orangeAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to scan',
                    style: AppTypography.title.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opens the trusted native scanner for edge detection and perspective correction.',
                    style: AppTypography.caption.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'On-device OCR (ML Kit) runs after capture when you tap “Extract text”.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          ..._cornerIndicators(),
        ],
      ),
    );
  }

  List<Widget> _cornerIndicators() {
    const offset = 16.0;
    return [
      Positioned(top: offset, left: offset, child: _CornerMarker(rotation: 0)),
      Positioned(top: offset, right: offset, child: _CornerMarker(rotation: 1)),
      Positioned(
        bottom: offset,
        right: offset,
        child: _CornerMarker(rotation: 2),
      ),
      Positioned(
        bottom: offset,
        left: offset,
        child: _CornerMarker(rotation: 3),
      ),
    ];
  }
}

class _CornerMarker extends StatelessWidget {
  final int rotation;
  const _CornerMarker({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 1.5708,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.orangeAccent, width: 3),
            left: BorderSide(color: AppColors.orangeAccent, width: 3),
          ),
        ),
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  final List<String> paths;

  const _ResultsPanel({required this.paths});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      children: [
        Text(
          'CAPTURED PAGES (${paths.length})',
          style: AppTypography.labelCaps.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (context, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _ThumbnailCard(path: paths[i], label: '${i + 1}'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ThumbnailCard extends StatelessWidget {
  final String path;
  final String label;

  const _ThumbnailCard({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: AppColors.surfaceContainer),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Iconsax.image, color: AppColors.textMuted, size: 32),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: AppTypography.navLabel.copyWith(
                    fontSize: 10,
                    color: AppColors.onPrimaryButton,
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
