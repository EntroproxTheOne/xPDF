import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/pdf_library_item.dart';
import 'pdf_library_repository.dart';
import 'pdf_sandbox_service.dart';

/// Handles payloads from [`receive_sharing_intent`] and stages them through the sandbox.
class IncomingPdfService {
  IncomingPdfService._();

  /// Best-effort: returns the sandbox path for the first PDF-like entry.
  /// Records history when successful.
  static Future<String?> importFirstPdf(Iterable<SharedMediaFile> batch) async {
    for (final file in batch) {
      final path = await _maybeImportPdf(file);
      if (path != null) return path;
    }
    return null;
  }

  static Future<String?> _maybeImportPdf(SharedMediaFile file) async {
    if (!_looksLikePdf(file)) return null;
    final source = file.path;
    if (source.isEmpty) return null;
    try {
      final out = await PdfSandboxService.importFileToSandbox(source);
      final titleHint = PdfLibraryItem.pdfTitleFromPath(source);
      await PdfLibraryRepository.instance.recordOpened(out, title: titleHint);
      return out;
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikePdf(SharedMediaFile file) {
    final mime = (file.mimeType ?? '').toLowerCase();
    final path = file.path.toLowerCase();
    if (mime.contains('pdf')) return true;
    if (path.endsWith('.pdf')) return true;
    if (mime == 'application/octet-stream' && path.contains('.pdf')) {
      return true;
    }
    return false;
  }
}
