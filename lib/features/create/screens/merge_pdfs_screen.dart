import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/pdf_library_item.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/pdf_merge_service.dart';
import '../../../services/pdf_sandbox_service.dart';

/// Pick multiple PDFs, order them, merge into one sandbox file (Syncfusion).
class MergePdfsScreen extends StatefulWidget {
  const MergePdfsScreen({super.key});

  @override
  State<MergePdfsScreen> createState() => _MergePdfsScreenState();
}

class _MergePdfsScreenState extends State<MergePdfsScreen> {
  final List<String> _sandboxPaths = [];

  bool _busy = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: AppTypography.bodySmall),
      ),
    );
  }

  Future<void> _addPdfsFromPicker() async {
    XpHaptics.surfaceTap();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final added = <String>[];
    for (final pf in result.files) {
      final platformPath = pf.path;
      if (platformPath == null || platformPath.isEmpty) continue;
      try {
        final sandbox = await PdfSandboxService.importFileToSandbox(
          platformPath,
          originalNameHint: pf.name.isNotEmpty ? pf.name : null,
        );
        if (!_sandboxPaths.contains(sandbox)) {
          added.add(sandbox);
          _sandboxPaths.add(sandbox);
        }
      } catch (e) {
        if (mounted) _toast('Skipped a file: $e');
      }
    }
    if (added.isNotEmpty && mounted) setState(() {});
  }

  void _removeAt(int i) {
    XpHaptics.surfaceTap();
    setState(() => _sandboxPaths.removeAt(i));
  }

  Future<void> _runMerge() async {
    if (_sandboxPaths.length < 2) {
      _toast('Add at least two PDFs.');
      return;
    }
    setState(() => _busy = true);
    XpHaptics.primaryCta();
    try {
      final out =
          await PdfMergeService.mergeToSandbox(List.of(_sandboxPaths));
      await PdfLibraryRepository.instance.recordOpened(out);
      if (!mounted) return;
      _toast('Merged ${_sandboxPaths.length} files.');
      await context.push(
        '/viewer?path=${Uri.encodeComponent(out)}',
      );
    } catch (e) {
      if (mounted) _toast('Merge failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _displayName(String sandboxPath) =>
      PdfLibraryItem.pdfTitleFromPath(sandboxPath);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: GlassAppBar(
        title: 'Merge PDFs',
        subtitle: 'Order matters — top merges first.',
        showBackButton: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Text(
              'Add PDF files, drag handles to reorder, then merge.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _addPdfsFromPicker,
              icon: Icon(
                Iconsax.add_circle,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                _sandboxPaths.isEmpty ? 'Choose PDFs' : 'Add more PDFs',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: _sandboxPaths.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: GlassCard(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.document_copy,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No files yet',
                              style: AppTypography.title,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick two or more PDFs to combine into one document.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    physics: const BouncingScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _sandboxPaths.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final x = _sandboxPaths.removeAt(oldIdx);
                        _sandboxPaths.insert(newIdx, x);
                      });
                    },
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
                              elevation: lerpDouble(0, 5, t)!,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                    itemBuilder: (context, index) {
                      final path = _sandboxPaths[index];
                      return Padding(
                        key: ValueKey<String>(path),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color:
                                    AppColors.surfaceContainer.withValues(
                                  alpha: 0.52,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.glassBorder),
                              ),
                              child: SizedBox(
                                height: 64,
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primaryContainer.withValues(
                                          alpha: 0.55,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style:
                                            AppTypography.label.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayName(path),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.label,
                                          ),
                                          Text(
                                            p.basename(path),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          _busy ? null : () => _removeAt(index),
                                      icon: Icon(
                                        Iconsax.trash,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Remove',
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, bottom + 18),
            child: GradientButton(
              label:
                  _busy ? 'Merging…' : 'Merge into one PDF (${_sandboxPaths.length})',
              icon: Iconsax.document_copy,
              isLoading: _busy,
              onPressed: !_busy &&
                      _sandboxPaths.length >= 2
                  ? _runMerge
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
