import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'export_paths.dart';

class OptimizationResult {
  final File file;
  final int originalBytes;
  final int newBytes;
  final bool optimized;

  OptimizationResult(this.file, this.originalBytes, this.newBytes, this.optimized);
}

class PdfOptimizationService {
  PdfOptimizationService._();

  static Future<OptimizationResult> compressPdf(String sourcePath) async {
    final originalFile = File(sourcePath);
    if (!originalFile.existsSync()) {
      throw const FileSystemException('File not found');
    }

    final originalBytesCount = await originalFile.length();
    
    final exportDir = await ExportPaths.ensureExportsDirectory();
    final stem = p.basenameWithoutExtension(sourcePath);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(exportDir.path, '${stem}_compressed_$stamp.pdf');

    // Run compression in a background isolate to avoid blocking the main thread.
    final resultBytes = await compute(_compressInIsolate, sourcePath);
    
    if (resultBytes.length >= originalBytesCount) {
      // The file was already fully optimized or compression added bloat. 
      // Return the original file.
      return OptimizationResult(originalFile, originalBytesCount, originalBytesCount, false);
    } else {
      final newFile = File(destPath);
      await newFile.writeAsBytes(resultBytes, flush: true);
      return OptimizationResult(newFile, originalBytesCount, resultBytes.length, true);
    }
  }

  static List<int> _compressInIsolate(String sourcePath) {
    final file = File(sourcePath);
    final bytes = file.readAsBytesSync();
    
    final document = PdfDocument(inputBytes: bytes);
    // Setting compression to the highest level
    document.compressionLevel = PdfCompressionLevel.best;
    
    // Saving rebuilding the document structure
    final result = document.saveSync();
    document.dispose();
    
    return result;
  }
}
