import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera (or comparable) denied before opening the native document scanner.
class ScannerPermissionException implements Exception {
  final String message;

  ScannerPermissionException(this.message);

  @override
  String toString() => message;
}

/// Service wrapper for [`cunning_document_scanner`] (native crop / perspective / gallery).
///
/// Requests photo-library access when [galleryImportAllowed] is true so imports behave
/// reliably on newer Android/iOS versions. The scanner still requests camera internally.
class ScannerService {
  static const int maxPagesDefault = 100;

  /// Ask for runtime permissions suitable for scanning (and optionally gallery pick).
  Future<void> ensureScannerPermissions({
    required bool galleryImportAllowed,
  }) async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      throw ScannerPermissionException(
        'Camera access is needed to capture documents.',
      );
    }

    if (galleryImportAllowed && !_isDesktop) {
      await Permission.photos.request();
    }
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Opens the native scanner. Returns ``null`` if the user cancels/dismisses.
  ///
  /// [galleryImportAllowed] enables the picker flow inside native UI (Adobe-like crop).
  Future<List<String>?> scanDocuments({
    int maxPages = maxPagesDefault,
    bool galleryImportAllowed = true,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Document scanning is not supported on web.');
    }
    await ensureScannerPermissions(galleryImportAllowed: galleryImportAllowed);

    try {
      return await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        isGalleryImportAllowed: galleryImportAllowed,
      );
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('permission')) {
        throw ScannerPermissionException(
          'Scanner needs camera permission. Enable it in settings and try again.',
        );
      }
      if (e is PlatformException) {
        throw Exception('Scanner failed: ${e.message ?? e.code}');
      }
      throw Exception('Scanner failed: $e');
    }
  }
}
