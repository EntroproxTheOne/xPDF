import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool _dark = false;

  static bool get isDark => _dark;

  static void setDarkMode(bool enabled) {
    _dark = enabled;
  }

  static const Color _lightBackground = Color(0xFFF8F9FF);
  static const Color _lightSurface = Color(0xFFF8F9FF);
  static const Color _lightSurfaceDim = Color(0xFFCBDBF5);
  static const Color _lightSurfaceBright = Color(0xFFF8F9FF);
  static const Color _lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _lightSurfaceContainerLow = Color(0xFFEFF4FF);
  static const Color _lightSurfaceContainer = Color(0xFFE5EEFF);
  static const Color _lightSurfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color _lightSurfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color _lightOnSurface = Color(0xFF0B1C30);
  static const Color _lightOnSurfaceVariant = Color(0xFF424656);
  static const Color _lightOutline = Color(0xFF737687);
  static const Color _lightOutlineVariant = Color(0xFFC2C6D9);
  static const Color _lightInputFill = Color(0xFFF1F5F9);
  static const Color _lightTextMuted = Color(0xFF5C6370);

  static const Color _darkBackground = Color(0xFF07111F);
  static const Color _darkSurface = Color(0xFF0B1728);
  static const Color _darkSurfaceDim = Color(0xFF091322);
  static const Color _darkSurfaceBright = Color(0xFF17263A);
  static const Color _darkSurfaceContainerLowest = Color(0xFF0A1424);
  static const Color _darkSurfaceContainerLow = Color(0xFF101D30);
  static const Color _darkSurfaceContainer = Color(0xFF15243A);
  static const Color _darkSurfaceContainerHigh = Color(0xFF1C2D45);
  static const Color _darkSurfaceContainerHighest = Color(0xFF263852);
  static const Color _darkOnSurface = Color(0xFFEAF1FF);
  static const Color _darkOnSurfaceVariant = Color(0xFFC4CCDA);
  static const Color _darkOutline = Color(0xFF8D97A8);
  static const Color _darkOutlineVariant = Color(0xFF3A4A61);
  static const Color _darkInputFill = Color(0xFF101B2B);
  static const Color _darkTextMuted = Color(0xFF9CA8BA);

  static Color get background => _dark ? _darkBackground : _lightBackground;
  static Color get surface => _dark ? _darkSurface : _lightSurface;
  static Color get surfaceDim => _dark ? _darkSurfaceDim : _lightSurfaceDim;
  static Color get surfaceBright =>
      _dark ? _darkSurfaceBright : _lightSurfaceBright;

  static Color get surfaceContainerLowest => _dark
      ? _darkSurfaceContainerLowest
      : _lightSurfaceContainerLowest;
  static Color get surfaceContainerLow =>
      _dark ? _darkSurfaceContainerLow : _lightSurfaceContainerLow;
  static Color get surfaceContainer =>
      _dark ? _darkSurfaceContainer : _lightSurfaceContainer;
  static Color get surfaceContainerHigh =>
      _dark ? _darkSurfaceContainerHigh : _lightSurfaceContainerHigh;
  static Color get surfaceContainerHighest => _dark
      ? _darkSurfaceContainerHighest
      : _lightSurfaceContainerHighest;

  static Color get onSurface => _dark ? _darkOnSurface : _lightOnSurface;
  static Color get onSurfaceVariant =>
      _dark ? _darkOnSurfaceVariant : _lightOnSurfaceVariant;
  static Color get onBackground => onSurface;

  static Color get inverseSurface =>
      _dark ? const Color(0xFFEAF1FF) : const Color(0xFF213145);
  static Color get inverseOnSurface =>
      _dark ? const Color(0xFF0B1C30) : const Color(0xFFEAF1FF);

  static Color get outline => _dark ? _darkOutline : _lightOutline;
  static Color get outlineVariant =>
      _dark ? _darkOutlineVariant : _lightOutlineVariant;
  static Color get surfaceTint => primary;

  static Color get primary =>
      _dark ? const Color(0xFF7BB3FF) : const Color(0xFF004BCA);
  static Color get onPrimary =>
      _dark ? const Color(0xFF061529) : const Color(0xFFFFFFFF);
  static Color get primaryContainer =>
      _dark ? const Color(0xFF124A93) : const Color(0xFF0061FF);
  static Color get onPrimaryContainer =>
      _dark ? const Color(0xFFD7E7FF) : const Color(0xFFF1F2FF);

  static Color get secondary =>
      _dark ? const Color(0xFF67DDF5) : const Color(0xFF00677D);
  static Color get onSecondary =>
      _dark ? const Color(0xFF00252D) : const Color(0xFFFFFFFF);
  static Color get secondaryContainer =>
      _dark ? const Color(0xFF184F60) : const Color(0xFF50D9FE);
  static Color get onSecondaryContainer =>
      _dark ? const Color(0xFFC9F5FF) : const Color(0xFF005C70);

  static Color get tertiary =>
      _dark ? const Color(0xFFB9C5CE) : const Color(0xFF535759);
  static Color get onTertiary =>
      _dark ? const Color(0xFF18212A) : const Color(0xFFFFFFFF);

  static Color get error =>
      _dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  static Color get onError =>
      _dark ? const Color(0xFF690005) : const Color(0xFFFFFFFF);
  static Color get errorContainer =>
      _dark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);
  static Color get onErrorContainer =>
      _dark ? const Color(0xFFFFDAD6) : const Color(0xFF93000A);

  static Color get inputFill => _dark ? _darkInputFill : _lightInputFill;

  static Color get backgroundPrimary => background;
  static Color get backgroundSecondary => surfaceContainerLow;
  static Color get backgroundTertiary => surfaceContainerHigh;

  static Color get textPrimary => onSurface;
  static Color get textSecondary => onSurfaceVariant;
  static Color get textMuted => _dark ? _darkTextMuted : _lightTextMuted;

  static Color get glassSurface =>
      (_dark ? const Color(0xFF112036) : Colors.white).withValues(
        alpha: _dark ? 0.72 : 0.60,
      );
  static Color get glassSurfaceLight =>
      (_dark ? const Color(0xFF182A43) : Colors.white).withValues(
        alpha: _dark ? 0.86 : 0.88,
      );
  static Color get glassBorder =>
      (_dark ? Colors.white : Colors.white).withValues(
        alpha: _dark ? 0.12 : 0.20,
      );
  static Color get glassBorderLight => outlineVariant.withValues(alpha: 0.9);
  static Color get glassChromeFill =>
      (_dark ? const Color(0xFF0B1728) : Colors.white).withValues(
        alpha: _dark ? 0.72 : 0.60,
      );

  static Color get obsidian => backgroundPrimary;
  static Color get surfaceWarm => surfaceContainerLow;
  static Color get orangeAccent => primary;
  static Color get orangeAccentLight =>
      _dark ? const Color(0xFF9AC6FF) : const Color(0xFF5B8DEF);
  static Color get orangeAccentDark =>
      _dark ? const Color(0xFF4E95EA) : const Color(0xFF003EA8);
  static Color get onPrimaryButton => onPrimary;
  static Color get orangeGlow => primary.withValues(alpha: 0.35);

  static Color get redTrim => primary;
  static Color get redTrimDark =>
      _dark ? const Color(0xFF4E95EA) : const Color(0xFF00308C);
  static Color get redTrimGlow => primary.withValues(alpha: 0.25);

  static Color get tertiaryBright => secondaryContainer;
  static Color get textOnOrange => onPrimary;

  static Color get success =>
      _dark ? const Color(0xFF7DDBCB) : const Color(0xFF00796B);
  static Color get warning =>
      _dark ? const Color(0xFFFFB86B) : const Color(0xFFE65100);
  static Color get info => secondary;
  static Color get errorStrong => error;

  static LinearGradient get orangeGradient => LinearGradient(
        colors: _dark
            ? const [Color(0xFF7BB3FF), Color(0xFF67DDF5)]
            : const [Color(0xFF004BCA), Color(0xFF0061FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get redOrangeGradient => LinearGradient(
        colors: _dark
            ? const [Color(0xFF7BB3FF), Color(0xFF67DDF5)]
            : const [Color(0xFF004BCA), Color(0xFF00677D)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get darkGradient => LinearGradient(
        colors: [surfaceContainerLow, background],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          (_dark ? const Color(0xFF17263A) : Colors.white).withValues(
            alpha: _dark ? 0.86 : 0.92,
          ),
          (_dark ? const Color(0xFF0B1728) : Colors.white).withValues(
            alpha: _dark ? 0.68 : 0.72,
          ),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: _dark
              ? Colors.black.withValues(alpha: 0.22)
              : const Color.fromRGBO(0, 40, 100, 0.04),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glassChromeUpShadow => [
        BoxShadow(
          color: _dark
              ? Colors.black.withValues(alpha: 0.30)
              : const Color.fromRGBO(0, 40, 100, 0.04),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, -10),
        ),
      ];

  static Color get navActivePillBg => primary.withValues(alpha: 0.14);

  static List<BoxShadow> get orangeGlowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: _dark ? 0.28 : 0.22),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get redGlowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: _dark ? 0.24 : 0.18),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];
}
