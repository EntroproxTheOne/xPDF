import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Chooses a writable, user-oriented folder for PDF/image exports.
///
/// Android: prefers public **Documents**, then **Downloads**, then app documents.
/// iOS: app documents (visible in Files when sharing is enabled) under [exportsSubfolder].
abstract final class ExportPaths {
  /// Subfolder name under Documents/Downloads or app storage.
  static const exportsSubfolder = 'xPDF Exports';

  /// Resolved directory; tries candidates until one passes a write probe.
  static Future<Directory> ensureExportsDirectory() async {
    for (final root in await _candidateRoots()) {
      try {
        await root.create(recursive: true);
        final sub = Directory(p.join(root.path, exportsSubfolder));
        await sub.create(recursive: true);
        final probe = File(p.join(sub.path, '.xpdf_write_probe'));
        try {
          await probe.writeAsString('ok', flush: true);
          await probe.delete();
          return sub;
        } catch (_) {}
      } catch (_) {}
    }

    final fb = await getApplicationDocumentsDirectory();
    final sub = Directory(p.join(fb.path, exportsSubfolder));
    await sub.create(recursive: true);
    return sub;
  }

  /// Short hint for snackbars / dialogs.
  static String whereToFindExportedFiles(Directory resolvedDir) {
    final norm = resolvedDir.path.replaceAll('\\', '/');

    if (!kIsWeb && Platform.isIOS) {
      return 'Files → On My iPhone → xPDF → $exportsSubfolder';
    }

    if (!kIsWeb && Platform.isAndroid) {
      if (norm.contains('/Documents')) {
        return 'Documents → $exportsSubfolder';
      }
      if (norm.contains('Download')) {
        return 'Downloads → $exportsSubfolder';
      }
    }

    return exportsSubfolder;
  }

  static Future<List<Directory>> _candidateRoots() async {
    final list = <Directory>[];

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final docs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        if (docs != null && docs.isNotEmpty) {
          list.addAll(docs);
        }
      } catch (_) {}

      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          list.add(downloads);
        }
      } catch (_) {}

      try {
        final extDl = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDl != null && extDl.isNotEmpty) {
          list.addAll(extDl);
        }
      } catch (_) {}
    }

    try {
      final dl = await getDownloadsDirectory();
      if (dl != null && !list.any((e) => e.path == dl.path)) {
        list.add(dl);
      }
    } catch (_) {}

    try {
      final app = await getApplicationDocumentsDirectory();
      list.add(Directory(app.path));
    } catch (_) {}

    return list;
  }
}
