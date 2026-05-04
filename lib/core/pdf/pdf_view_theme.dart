import 'dart:ui';

import '../../services/pdf_library_repository.dart';

/// Lightweight color matrices for rasterized viewing (not typography reflow).
class PdfReadingThemeMatrices {
  static const darkReader = ColorFilter.matrix(<double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  /// `null` when no extra toning beyond the baked PDF colors should be applied.
  static ColorFilter? effectiveFilter(
    PdfReadingThemeEnum mode,
    Brightness platform,
  ) {
    final invert = switch (mode) {
      PdfReadingThemeEnum.light => false,
      PdfReadingThemeEnum.dark => true,
      PdfReadingThemeEnum.system => platform == Brightness.dark,
    };
    return invert ? darkReader : null;
  }

  static Color viewerCanvasBackground(
    PdfReadingThemeEnum mode,
    Brightness platform,
  ) {
    final dark = effectiveFilter(mode, platform) != null;
    return dark ? const Color(0xFF101010) : const Color(0xFFEFF4FF);
  }
}
