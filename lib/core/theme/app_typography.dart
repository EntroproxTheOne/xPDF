import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// **Inter** scales from [mockups/DESIGN.md] (display-lg, headline-*, body-*, label-*).
class AppTypography {
  AppTypography._();

  static String? _fontFamily;

  static String get fontFamily {
    _fontFamily ??= GoogleFonts.inter().fontFamily;
    return _fontFamily!;
  }

  static TextStyle _base(TextStyle style) =>
      style.copyWith(color: AppColors.onSurface);

  // ─── Display / headline (mobile-tuned from 48/32 mock) ─────────────────────
  static TextStyle display = _base(
    GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.02 * 16,
      height: 56 / 48,
    ),
  );

  static TextStyle headline = _base(
    GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01 * 16,
      height: 32 / 24,
    ),
  );

  static TextStyle title = _base(
    GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.35,
    ),
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────
  static TextStyle body = _base(
    GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
    ),
  );

  static TextStyle bodyLarge = _base(
    GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 28 / 18,
    ),
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 20 / 14,
  );

  // ─── Label ─────────────────────────────────────────────────────────────────
  static TextStyle label = _base(
    GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: 0.01 * 14,
    ),
  );

  static TextStyle labelSmall = _base(
    GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 16 / 12,
      letterSpacing: 0.05 * 12,
    ),
  );

  static TextStyle labelCaps = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.06 * 12,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.08 * 10,
    height: 1.2,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle brandWordmark = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.normal,
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.primary,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimaryButton,
    letterSpacing: 0.15,
    height: 20 / 16,
  );

  static TextStyle buttonOnAccent = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.15,
    height: 20 / 16,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.12,
    height: 18 / 14,
  );
}
