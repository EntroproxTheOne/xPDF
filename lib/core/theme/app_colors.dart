import 'package:flutter/material.dart';

/// **Lumina Glass** — tokens from [mockups/DESIGN.md] (Material light + frosted glass).
class AppColors {
  AppColors._();

  // ─── Core (YAML) ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF424656);
  static const Color onBackground = Color(0xFF0B1C30);

  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  static const Color outline = Color(0xFF737687);
  static const Color outlineVariant = Color(0xFFC2C6D9);
  static const Color surfaceTint = Color(0xFF0052DC);

  static const Color primary = Color(0xFF004BCA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0061FF);
  static const Color onPrimaryContainer = Color(0xFFF1F2FF);

  static const Color secondary = Color(0xFF00677D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF50D9FE);
  static const Color onSecondaryContainer = Color(0xFF005C70);

  static const Color tertiary = Color(0xFF535759);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  /// Search / neutral fields (DESIGN.md COMPONENTS).
  static const Color inputFill = Color(0xFFF1F5F9);

  // ─── Scaffold & panels (semantic) ─────────────────────────────────────────
  static const Color backgroundPrimary = background;
  static const Color backgroundSecondary = surfaceContainerLow;
  static const Color backgroundTertiary = surfaceContainerHigh;

  // ─── Content helpers ──────────────────────────────────────────────────────
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = Color(0xFF5C6370);

  // ─── Light glass (mock `.glass-panel` + chrome: white ~60%, border white/20) ─
  static Color glassSurface = Colors.white.withValues(alpha: 0.60);
  static Color glassSurfaceLight = Colors.white.withValues(alpha: 0.88);
  static Color glassBorder = Colors.white.withValues(alpha: 0.20);
  static Color glassBorderLight = outlineVariant.withValues(alpha: 0.9);

  /// Top/bottom shell bars (`bg-white/60` in mock HTML).
  static Color glassChromeFill = Colors.white.withValues(alpha: 0.60);

  // ─── Legacy names (map to Lumina; limits churn across feature screens) ────
  static const Color obsidian = backgroundPrimary;
  static const Color surfaceWarm = surfaceContainerLow;
  static const Color orangeAccent = primary;
  static const Color orangeAccentLight = Color(0xFF5B8DEF);
  static const Color orangeAccentDark = Color(0xFF003EA8);
  static const Color onPrimaryButton = onPrimary;
  static Color orangeGlow = primary.withValues(alpha: 0.35);

  /// Former “red trim” — use primary/outline for chrome; keep saturated for rare legacy emphasis.
  static const Color redTrim = primary;
  static const Color redTrimDark = Color(0xFF00308C);
  static Color redTrimGlow = primary.withValues(alpha: 0.25);

  static const Color tertiaryBright = secondaryContainer;
  static const Color textOnOrange = onPrimary;

  // ─── Semantic feedback ───────────────────────────────────────────────────
  static const Color success = Color(0xFF00796B);
  static const Color warning = Color(0xFFE65100);
  static const Color info = secondary;
  static const Color errorStrong = error;

  // ─── Gradients (light, subtle) ───────────────────────────────────────────
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFF004BCA), Color(0xFF0061FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redOrangeGradient = LinearGradient(
    colors: [Color(0xFF004BCA), Color(0xFF00677D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient darkGradient = LinearGradient(
    colors: [surfaceContainerLow, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.92),
      Colors.white.withValues(alpha: 0.72),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows (mock glass-panel: `0 8px 30px rgba(0,40,100,0.04)`) ───────────
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: const Color.fromRGBO(0, 40, 100, 0.04),
      blurRadius: 30,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Bottom nav uplift (mock `0 -10px 40px rgba(0,40,100,0.04)`).
  static List<BoxShadow> glassChromeUpShadow = [
    BoxShadow(
      color: const Color.fromRGBO(0, 40, 100, 0.04),
      blurRadius: 40,
      spreadRadius: 0,
      offset: const Offset(0, -10),
    ),
  ];

  /// Active tab pill tint (tailwind `blue-50/50` analogue).
  static Color navActivePillBg = primary.withValues(alpha: 0.08);

  static List<BoxShadow> orangeGlowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.22),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> redGlowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];
}
