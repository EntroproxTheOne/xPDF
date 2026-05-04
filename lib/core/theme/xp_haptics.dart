import 'package:flutter/services.dart';

/// Tactile feedback for Lumina Glass UI density ([mockups/DESIGN.md]).
abstract final class XpHaptics {
  /// Glass tiles, list rows, chips, thumbnails.
  static void surfaceTap() {
    HapticFeedback.selectionClick();
  }

  /// Bottom navigation and sheet row picks (changing shell route).
  static void navTap() {
    HapticFeedback.lightImpact();
  }

  /// Solid primary CTAs (`GradientButton`, critical confirm).
  static void primaryCta() {
    HapticFeedback.lightImpact();
  }

  /// Sheets opening (visual “snap” onto glass modal).
  static void sheetPresentation() {
    HapticFeedback.lightImpact();
  }

  /// Undo / reversible commit (optional).
  static void lightCommit() {
    HapticFeedback.lightImpact();
  }

  /// Remove, export finalize, locker apply.
  static void emphasize() {
    HapticFeedback.mediumImpact();
  }
}
