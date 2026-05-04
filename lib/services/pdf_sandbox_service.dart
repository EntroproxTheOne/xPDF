import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies externally supplied PDF paths (including plug-in temporary paths)
/// into app-managed documents storage.
class PdfSandboxService {
  static const _uuid = Uuid();

  static Future<Directory> ensurePdfsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'pdfs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String normalizeStoredPath(String filePath) {
    if (filePath.isEmpty) return filePath;
    return p.normalize(filePath.replaceAll(RegExp(r'[/\\]+$'), '').trim());
  }

  /// Copy [sourcePath] into the sandbox folder. Returns normalized destination path.
  static Future<String> importFileToSandbox(
    String sourcePath, {
    String? originalNameHint,
  }) async {
    final normalizedSource = normalizeStoredPath(sourcePath);
    final srcFile = File(normalizedSource);
    if (!await srcFile.exists()) {
      throw ArgumentError.value(
        sourcePath,
        'sourcePath',
        'File does not exist',
      );
    }

    final destDir = await ensurePdfsDirectory();
    final baseName = originalNameHint != null && originalNameHint.isNotEmpty
        ? p.basename(originalNameHint)
        : p.basename(normalizedSource);
    final lowerBn = baseName.toLowerCase();
    final short = lowerBn.endsWith('.pdf')
        ? baseName.substring(0, baseName.length - 4)
        : baseName;
    final sanitized = short.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    final name =
        '${sanitized.isEmpty ? 'document' : sanitized}_${_uuid.v4()}.pdf';
    final destPath = p.join(destDir.path, name);
    await srcFile.copy(destPath);
    return normalizeStoredPath(destPath);
  }

  /// Single-page blank A4 PDF in the sandbox (for “new doc” workflows).
  static Future<String> createBlankSandboxPdf() async {
    final dir = await ensurePdfsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = normalizeStoredPath(
      p.join(dir.path, 'blank_${stamp}_${_uuid.v4()}.pdf'),
    );
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (_) => pw.Center(child: pw.SizedBox()),
      ),
    );
    await File(outPath).writeAsBytes(await doc.save());
    return outPath;
  }
}
