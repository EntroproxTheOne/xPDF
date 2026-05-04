import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';

class PdfLockerScreen extends StatefulWidget {
  final String filePath;
  const PdfLockerScreen({super.key, required this.filePath});

  @override
  State<PdfLockerScreen> createState() => _PdfLockerScreenState();
}

class _PdfLockerScreenState extends State<PdfLockerScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLocking = false;

  double get _strength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.2;
    return s.clamp(0, 1);
  }

  Color get _strengthColor {
    if (_strength < 0.3) return AppColors.errorStrong;
    if (_strength < 0.6) return AppColors.warning;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_strength < 0.3) return 'Weak';
    if (_strength < 0.6) return 'Medium';
    return 'Strong';
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const GlassAppBar(
        title: 'Lock Document',
        subtitle: 'Set a password to encrypt',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lock icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.redTrim.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.lock, color: AppColors.redTrim, size: 36),
              ),
            ),
            const SizedBox(height: 28),
            // Password field
            Text('Password', style: AppTypography.label),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Enter password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Iconsax.eye_slash : Iconsax.eye,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Strength indicator
            if (_passwordCtrl.text.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _strength,
                        backgroundColor: AppColors.backgroundTertiary,
                        color: _strengthColor,
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _strengthLabel,
                    style: AppTypography.caption.copyWith(
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Confirm password
            Text('Confirm Password', style: AppTypography.label),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              style: AppTypography.body,
              decoration: const InputDecoration(hintText: 'Re-enter password'),
            ),
            const SizedBox(height: 10),
            // Encryption info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.shield_tick, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AES-256 bit encryption will be applied',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GradientButton(
              label: 'Lock Document',
              icon: Iconsax.lock,
              isLoading: _isLocking,
              onPressed: _passwordCtrl.text.isEmpty
                  ? null
                  : () {
                      setState(() => _isLocking = true);
                      final nav = Navigator.of(context);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) nav.pop();
                      });
                    },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
