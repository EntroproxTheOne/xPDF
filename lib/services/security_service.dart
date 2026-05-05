import 'dart:io';
import 'dart:ui' show Offset, Size;

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for handling PDF security features such as encryption and permission management.
class SecurityService {
  /// Locks a PDF document with a password and AES-256 encryption.
  ///
  /// [inputPath]: The path to the existing PDF.
  /// [password]: The password to set. Will be used as both User (open) and Owner (permissions) password.
  /// Returns the path to the newly encrypted PDF.
  Future<String> lockPdf(String inputPath, String password) async {
    final pin = password.trim();
    if (pin.isEmpty) throw ArgumentError('PIN cannot be empty');

    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) throw Exception('Input file not found');

    // 1. Read existing PDF
    final bytes = await inputFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    // 2. Configure Security Settings (AES-256)
    final security = document.security;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

    // Set passwords
    security.userPassword = pin;
    security.ownerPassword = pin;

    // 3. Save the encrypted document
    final dir = await getTemporaryDirectory();
    final stem = p.basenameWithoutExtension(inputPath);
    final outputPath =
        '${dir.path}/${stem}_locked_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final outputBytes = await document.save();
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(outputBytes);

    document.dispose();

    return outputPath;
  }

  /// Attempts to unlock a PDF document using the provided password.
  ///
  /// Returns the path to a new, decrypted PDF if successful.
  /// Throws an exception if the password is incorrect.
  Future<String> unlockPdf(String inputPath, String password) async {
    final pin = password.trim();
    if (pin.isEmpty) throw ArgumentError('PIN cannot be empty');

    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) throw Exception('Input file not found');

    final bytes = await inputFile.readAsBytes();

    try {
      final document = PdfDocument(inputBytes: bytes, password: pin);
      final unlockedDocument = _copyPagesToNewDocument(document);

      final dir = await getTemporaryDirectory();
      final stem = p.basenameWithoutExtension(inputPath);
      final outputPath =
          '${dir.path}/${stem}_unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final outputBytes = await unlockedDocument.save();
      File(outputPath).writeAsBytesSync(outputBytes);

      unlockedDocument.dispose();
      document.dispose();
      return outputPath;
    } catch (e) {
      throw Exception('Incorrect password or invalid PDF');
    }
  }

  /// Returns true when a PDF cannot be opened without a password.
  Future<bool> isPdfLocked(String inputPath) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) throw Exception('Input file not found');

    try {
      final document = PdfDocument(inputBytes: await inputFile.readAsBytes());
      document.dispose();
      return false;
    } catch (_) {
      return true;
    }
  }

  PdfDocument _copyPagesToNewDocument(PdfDocument source) {
    final output = PdfDocument();
    for (var i = 0; i < source.pages.count; i++) {
      final sourcePage = source.pages[i];
      final size = sourcePage.size;
      output.pageSettings.size = Size(size.width, size.height);
      final page = output.pages.add();
      page.rotation = sourcePage.rotation;
      final template = sourcePage.createTemplate();
      page.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        Size(size.width, size.height),
      );
    }
    return output;
  }
}
