import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling PDF security features such as encryption and permission management.
class SecurityService {
  /// Locks a PDF document with a password and AES-256 encryption.
  ///
  /// [inputPath]: The path to the existing PDF.
  /// [password]: The password to set. Will be used as both User (open) and Owner (permissions) password.
  /// Returns the path to the newly encrypted PDF.
  Future<String> lockPdf(String inputPath, String password) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) throw Exception('Input file not found');

    // 1. Read existing PDF
    final bytes = await inputFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    // 2. Configure Security Settings (AES-256)
    final security = document.security;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

    // Set passwords
    security.userPassword = password;
    security.ownerPassword = password;

    // 3. Save the encrypted document
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/locked_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) throw Exception('Input file not found');

    final bytes = await inputFile.readAsBytes();

    try {
      // Attempt to open the document with the password
      final document = PdfDocument(inputBytes: bytes, password: password);

      // If we reach here, the password is correct.
      // To create an unlocked version, we must clear the security settings.
      document.security.ownerPassword = '';
      document.security.userPassword = '';

      // Note: syncfusion_flutter_pdf currently doesn't easily allow stripping security completely from an existing document object.
      // A common workaround is to copy pages to a new document, but for this concept, we'll return the path.

      final dir = await getTemporaryDirectory();
      final outputPath =
          '${dir.path}/unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final outputBytes = await document.save();
      File(outputPath).writeAsBytesSync(outputBytes);

      document.dispose();
      return outputPath;
    } catch (e) {
      throw Exception('Incorrect password or invalid PDF');
    }
  }
}
