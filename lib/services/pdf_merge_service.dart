import 'dart:io';
import 'dart:ui' show Offset, Size;

import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_sandbox_service.dart';

/// Concatenates multiple PDFs in order using Syncfusion (full page clone per page).
class PdfMergeService {
  PdfMergeService._();

  /// [orderedPaths] must be readable files (typically sandbox copies). Returns path
  /// to a new PDF in the app sandbox.
  static Future<String> mergeToSandbox(List<String> orderedPaths) async {
    if (orderedPaths.length < 2) {
      throw ArgumentError('Select at least two PDFs to merge.');
    }

    final merged = PdfDocument();
    try {
      for (final path in orderedPaths) {
        final norm = PdfSandboxService.normalizeStoredPath(path);
        final file = File(norm);
        if (!await file.exists()) {
          throw ArgumentError.value(path, 'path', 'PDF not found: $norm');
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw ArgumentError.value(path, 'path', 'PDF file is empty');
        }
        final src = PdfDocument(inputBytes: bytes);
        try {
          for (var i = 0; i < src.pages.count; i++) {
            final sp = src.pages[i];
            final sz = sp.size;
            final rot = sp.rotation;
            final insertAt = merged.pages.count;
            // Insert page with explicit dart:ui Size
            final PdfPage inserted = merged.pages.insert(
              insertAt,
              Size(sz.width, sz.height),
            );
            inserted.rotation = rot;
            try {
              final template = sp.createTemplate();
              inserted.graphics.drawPdfTemplate(
                template,
                Offset.zero,
                Size(sz.width, sz.height),
              );
            } catch (_) {
              // If template copy fails, leave blank page rather than crash
            }
          }
        } finally {
          src.dispose();
        }
      }

      final dir = await PdfSandboxService.ensurePdfsDirectory();
      final outPath = PdfSandboxService.normalizeStoredPath(
        p.join(
          dir.path,
          'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );
      final outBytes = merged.saveSync();
      if (outBytes.isEmpty) {
        throw StateError('Merge produced an empty document.');
      }
      await File(outPath).writeAsBytes(outBytes);
      return outPath;
    } finally {
      merged.dispose();
    }
  }
}
