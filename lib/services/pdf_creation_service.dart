import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Request object for the background isolate
class _PdfCreationRequest {
  final List<String> imagePaths;
  final String outputPath;
  final SendPort progressPort;

  _PdfCreationRequest(this.imagePaths, this.outputPath, this.progressPort);
}

/// Service for handling heavy-duty PDF creation from images.
/// Uses background isolates to prevent main thread blocking, ensuring smooth UI.
class PdfCreationService {
  /// Builds a PDF and returns its file path. [onProgress] receives 0.0–1.0 while pages are encoded.
  Future<String> buildPdfFromImagePaths(
    List<String> imagePaths, {
    void Function(double progress)? onProgress,
  }) async {
    if (imagePaths.isEmpty) throw ArgumentError('Image list cannot be empty');

    for (final path in imagePaths) {
      if (!File(path).existsSync()) {
        throw Exception(
          'Missing image file (path no longer readable): ${p.basename(path)}',
        );
      }
    }

    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/xpdf_created_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final receivePort = ReceivePort();
    await Isolate.spawn(
      _processImagesInIsolate,
      _PdfCreationRequest(imagePaths, outputPath, receivePort.sendPort),
    );

    await for (final message in receivePort) {
      if (message is double) {
        onProgress?.call(message.clamp(0.0, 1.0));
      } else if (message is String && message == 'DONE') {
        receivePort.close();
        return outputPath;
      } else if (message is Exception) {
        receivePort.close();
        throw message;
      } else if (message is Error) {
        receivePort.close();
        throw message;
      }
    }

    return outputPath;
  }

  /// Creates a PDF from a list of image paths.
  ///
  /// Processes images in chunks in a background isolate to manage memory,
  /// crucial for handling up to 500 high-quality images.
  ///
  /// Yields progress updates (0.0 to 1.0) and finally returns the path of the generated PDF.
  Stream<double> createPdfFromImages(List<String> imagePaths) async* {
    if (imagePaths.isEmpty) throw ArgumentError('Image list cannot be empty');

    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/xpdf_created_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final receivePort = ReceivePort();

    // Spawn the isolate for background processing
    await Isolate.spawn(
      _processImagesInIsolate,
      _PdfCreationRequest(imagePaths, outputPath, receivePort.sendPort),
    );

    // Listen to progress updates from the isolate
    await for (final message in receivePort) {
      if (message is double) {
        yield message;
        if (message >= 1.0) {
          receivePort.close();
        }
      } else if (message is String && message == 'DONE') {
        receivePort.close();
      } else if (message is Exception || message is Error) {
        receivePort.close();
        throw message;
      }
    }

    // Once the stream closes, the PDF is ready
    yield 1.0;
  }

  /// The entry point for the isolate. Must be a top-level or static function.
  static Future<void> _processImagesInIsolate(
    _PdfCreationRequest request,
  ) async {
    try {
      final pdf = pw.Document();
      final totalImages = request.imagePaths.length;

      // Process in chunks to avoid OOM
      const chunkSize = 10;

      for (int i = 0; i < totalImages; i += chunkSize) {
        final end = (i + chunkSize < totalImages) ? i + chunkSize : totalImages;
        final chunk = request.imagePaths.sublist(i, end);

        for (int j = 0; j < chunk.length; j++) {
          final imagePath = chunk[j];
          final file = File(imagePath);

          if (!file.existsSync()) {
            request.progressPort.send(
              Exception(
                'Missing image while building PDF — rescan: ${p.basename(imagePath)}',
              ),
            );
            return;
          }

          // 1. Read bytes
          final bytes = await file.readAsBytes();

          // 2. Compress image to reduce memory footprint (simulate or use flutter_image_compress if available in isolate)
          // Note: flutter_image_compress uses platform channels which might have issues in pure Dart isolates depending on the plugin setup.
          // For safety in this robust implementation, we'll use a try-catch and fallback to raw bytes if compression fails in isolate.
          Uint8List compressedBytes = bytes;
          try {
            final result = await FlutterImageCompress.compressWithList(
              bytes,
              minWidth: 1080,
              minHeight: 1080,
              quality: 80,
            );
            compressedBytes = result;
          } catch (_) {
            // Fallback to original bytes if compression fails
            compressedBytes = bytes;
          }

          // 3. Decode image for PDF package
          final image = pw.MemoryImage(compressedBytes);

          // 4. Add page to PDF
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              },
            ),
          );

          // Report progress
          final currentProgress = (i + j + 1) / totalImages;
          request.progressPort.send(currentProgress);
        }

        // Optional: Hint the garbage collector to clean up the chunk
        // (Dart doesn't have an explicit GC call, but chunking helps scoping)
      }

      // Save the PDF
      final outputFile = File(request.outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      // Signal completion
      request.progressPort.send('DONE');
    } catch (e) {
      request.progressPort.send(Exception('Failed to create PDF: $e'));
    }
  }
}
