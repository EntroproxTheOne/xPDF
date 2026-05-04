import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import 'pdf_editor_service.dart';
import 'export_paths.dart';

enum PdfRasterExportFormat { png, jpeg }

/// Local export (subset PDF + page rasters); uses Syncfusion + PDFium.
class PdfExportService {
  PdfExportService._();

  /// New PDF in [outputDirectory] (defaults to Documents/Downloads `xPDF Exports`).
  static Future<File> exportSubsetPdf({
    required String sourcePath,
    required Set<int> zeroBasedIndices,
    Directory? outputDirectory,
  }) async {
    final outDir =
        outputDirectory ?? await ExportPaths.ensureExportsDirectory();
    final ed = PdfEditorService();
    try {
      await ed.load(sourcePath);
      final dest = await ed.exportSubsetPagesToFile(
        zeroBasedIndices,
        preferredOutputDirectory: outDir.path,
      );
      return File(dest);
    } finally {
      ed.dispose();
    }
  }

  /// Exports each page in [zeroBasedIndices] as its own standalone PDF file.
  static Future<List<File>> exportSplitPdfs({
    required String sourcePath,
    required Set<int> zeroBasedIndices,
    Directory? outputDirectory,
  }) async {
    final outDir = outputDirectory ?? await ExportPaths.ensureExportsDirectory();
    final ed = PdfEditorService();
    try {
      await ed.load(sourcePath);
      final out = <File>[];
      for (final index in zeroBasedIndices) {
        if (index < 0 || index >= ed.pageCount) continue;
        final dest = await ed.exportSinglePagePdf(
          index,
          preferredOutputDirectory: outDir.path,
        );
        out.add(File(dest));
      }
      return out;
    } finally {
      ed.dispose();
    }
  }

  /// One image file per page; order matches [sortedZeroBasedAscending].
  /// Files are written under [outputDirectory] (defaults to a user-visible
  /// export folder from [ExportPaths.ensureExportsDirectory]).
  static Future<List<File>> exportPagesRaster({
    required String sourcePath,
    required List<int> sortedZeroBasedAscending,
    required PdfRasterExportFormat format,
    Directory? outputDirectory,
    double dpiScale = 2.25,
    int jpegQuality = 88,
  }) async {
    final PdfDocument doc = await PdfDocument.openFile(sourcePath);
    final outParent =
        outputDirectory ?? await ExportPaths.ensureExportsDirectory();
    try {
      await doc.loadPagesProgressively(
        onPageLoadProgress: (_, _, _) async => true,
      );
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final stem = _safeStem(sourcePath);

      final out = <File>[];
      for (final pi in sortedZeroBasedAscending) {
        if (pi < 0 || pi >= doc.pages.length) continue;

        final pdfPage = doc.pages[pi];
        final scale = dpiScale.clamp(1.0, 4.0);
        final fullW = pdfPage.width * scale;
        final fullH = pdfPage.height * scale;

        final raster = await pdfPage.render(
          fullWidth: fullW,
          fullHeight: fullH,
          backgroundColor: Colors.white,
        );

        if (raster == null) continue;

        try {
          final Uint8List bytes;
          if (format == PdfRasterExportFormat.png) {
            final uiImg = await raster.createImage();
            final bd = await uiImg.toByteData(format: ui.ImageByteFormat.png);
            uiImg.dispose();
            if (bd == null) continue;
            bytes = bd.buffer.asUint8List();
          } else {
            final fmt = raster.format == ui.PixelFormat.rgba8888
                ? img.ChannelOrder.rgba
                : img.ChannelOrder.bgra;
            final image = img.Image.fromBytes(
              width: raster.width,
              height: raster.height,
              bytes: raster.pixels.buffer,
              numChannels: 4,
              order: fmt,
            );
            bytes = Uint8List.fromList(
              img.encodeJpg(image, quality: jpegQuality.clamp(30, 100)),
            );
          }

          final ext = format == PdfRasterExportFormat.png ? 'png' : 'jpg';
          final name = 'xpdf_${stem}_p${pi + 1}_$stamp.$ext';
          final file = File(p.join(outParent.path, name));
          await file.writeAsBytes(bytes, flush: true);
          out.add(file);
        } finally {
          raster.dispose();
        }
      }
      return out;
    } finally {
      await doc.dispose();
    }
  }

  static String _safeStem(String path) {
    final bn = p.basenameWithoutExtension(path);
    final sanitized = bn.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return sanitized.isEmpty ? 'export' : sanitized;
  }
}
