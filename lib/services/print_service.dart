import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Service handling cross-platform printing capabilities.
class PrintService {
  /// Opens the native print dialog for the given PDF file.
  ///
  /// Supports both wireless network printing (AirPrint, Android Print)
  /// and USB connections depending on the host OS.
  Future<void> printDocument(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found for printing.');
    }

    final bytes = await file.readAsBytes();

    // The printing package opens the native system print spooler UI
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: file
          .uri
          .pathSegments
          .last, // Use filename as document name in print queue
    );
  }
}
