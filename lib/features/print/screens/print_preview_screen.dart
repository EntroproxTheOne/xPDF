import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';

class PrintPreviewScreen extends StatelessWidget {
  final String filePath;
  const PrintPreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const GlassAppBar(title: 'Print Preview', showBackButton: true),
      body: Column(
        children: [
          // Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppColors.glassShadow,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 48,
                      color: AppColors.backgroundTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Document Preview',
                      style: AppTypography.body.copyWith(
                        color: AppColors.backgroundPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Print settings
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
              children: [
                _PrintOption(label: 'Pages', value: 'All'),
                _PrintOption(label: 'Copies', value: '1'),
                _PrintOption(label: 'Color', value: 'Full Color'),
                _PrintOption(label: 'Orientation', value: 'Portrait'),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Print Document',
                  icon: Iconsax.printer,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintOption extends StatelessWidget {
  final String label;
  final String value;
  const _PrintOption({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Text(value, style: AppTypography.bodySmall),
                const SizedBox(width: 6),
                Icon(
                  Iconsax.arrow_down_1,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
