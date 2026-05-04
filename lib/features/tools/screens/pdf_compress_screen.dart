import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../services/pdf_optimization_service.dart';
import '../../../services/pdf_pick_open_service.dart';
import '../../../services/pdf_library_repository.dart';

class PdfCompressScreen extends StatefulWidget {
  final String? initialPath;

  const PdfCompressScreen({super.key, this.initialPath});

  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  String? _filePath;
  bool _compressing = false;
  OptimizationResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _filePath = widget.initialPath;
      _runCompression(_filePath!);
    }
  }

  Future<void> _pickFile() async {
    final path = await pickSinglePdfToSandbox();
    if (path == null) return;
    
    setState(() {
      _filePath = path;
      _result = null;
      _error = null;
    });
    
    await _runCompression(path);
  }

  Future<void> _runCompression(String path) async {
    setState(() {
      _compressing = true;
      _error = null;
    });

    try {
      final res = await PdfOptimizationService.compressPdf(path);
      if (res.optimized) {
        await PdfLibraryRepository.instance.recordOpened(res.file.path);
      }
      if (!mounted) return;
      setState(() {
        _result = res;
      });
      XpHaptics.lightCommit();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      XpHaptics.lightCommit();
    } finally {
      if (mounted) {
        setState(() {
          _compressing = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(Iconsax.document_1, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a PDF to compress',
            style: AppTypography.title,
          ),
          const SizedBox(height: 8),
          Text(
            'Reduce file size without losing quality.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: GradientButton(
              label: 'Select PDF',
              icon: Iconsax.folder_open,
              onPressed: _pickFile,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Compressing Document...',
            style: AppTypography.title,
          ),
          const SizedBox(height: 8),
          Text(
            'Optimizing structure and resources',
            style: AppTypography.bodySmall,
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildResultState(OptimizationResult res) {
    final savedBytes = res.originalBytes - res.newBytes;
    final savedPercent = res.originalBytes > 0 
        ? ((savedBytes / res.originalBytes) * 100).toStringAsFixed(1) 
        : '0.0';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: res.optimized ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: res.optimized ? AppColors.success : AppColors.outlineVariant),
              ),
              child: Icon(
                res.optimized ? Iconsax.tick_circle : Iconsax.info_circle, 
                size: 64, 
                color: res.optimized ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              res.optimized ? 'Compression Successful' : 'Already Optimized',
              style: AppTypography.title,
            ),
            const SizedBox(height: 8),
            Text(
              res.optimized 
                ? 'Your file has been compressed and saved.' 
                : 'This PDF is already highly compressed. No further reductions were made.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 32),
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Column(
                children: [
                  _ResultRow('Original Size', _formatBytes(res.originalBytes)),
                  Divider(height: 24, color: AppColors.outlineVariant),
                  _ResultRow(
                    'New Size', 
                    _formatBytes(res.newBytes),
                    color: res.optimized ? AppColors.success : null,
                  ),
                  if (res.optimized) ...[
                    Divider(height: 24, color: AppColors.outlineVariant),
                    _ResultRow(
                      'Space Saved', 
                      '${_formatBytes(savedBytes)} ($savedPercent%)',
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (res.optimized)
              GradientButton(
                label: 'Share PDF',
                icon: Iconsax.export_1,
                onPressed: () async {
                  XpHaptics.lightCommit();
                  await Share.shareXFiles([XFile(res.file.path)]);
                },
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text('Return to Home', style: AppTypography.label),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: GlassAppBar(
        title: 'Compress PDF',
        subtitle: _filePath != null ? p.basename(_filePath!) : 'Optimize file size',
        showBackButton: true,
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.warning_2, size: 48, color: AppColors.redTrim),
                      const SizedBox(height: 16),
                      Text('Compression Failed', style: AppTypography.title),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center, style: AppTypography.caption),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : _compressing
                ? _buildLoadingState()
                : _result != null
                    ? _buildResultState(_result!)
                    : _buildEmptyState(),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ResultRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.label.copyWith(color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
