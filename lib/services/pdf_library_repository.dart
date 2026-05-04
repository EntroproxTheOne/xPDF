import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/pdf_library_item.dart';
import 'pdf_sandbox_service.dart';

/// Persisted recently opened PDFs plus viewer reading-theme preference strings.
class PdfLibraryRepository extends ChangeNotifier {
  PdfLibraryRepository._();

  static final PdfLibraryRepository instance = PdfLibraryRepository._();

  static const _recentKey = 'recent_pdf_docs_json_v1';
  static const _readingThemeKey = 'pdf_reading_theme_v1';

  Box<dynamic> _bx(String context) {
    if (!Hive.isBoxOpen('allinonepdf_box')) {
      throw StateError(
        '$context: Hive box not initialized. Call AppBootstrap.init() first.',
      );
    }
    return Hive.box<dynamic>('allinonepdf_box');
  }

  PdfReadingThemeEnum getReadingTheme() {
    final raw = _bx('getReadingTheme').get(_readingThemeKey) as String?;
    return PdfReadingThemeEnum.fromStorage(
      raw ?? PdfReadingThemeEnum.system.storageValue,
    );
  }

  Future<void> setReadingTheme(PdfReadingThemeEnum theme) async {
    await _bx('setReadingTheme').put(_readingThemeKey, theme.storageValue);
    notifyListeners();
  }

  Future<void> recordOpened(String filePath, {String? title}) async {
    if (filePath.isEmpty) return;
    final norm = PdfSandboxService.normalizeStoredPath(filePath);
    final f = File(norm);
    if (!f.existsSync()) return;

    final items = PdfLibraryItem.decodeList(
      _bx('recordOpened').get(_recentKey) as String?,
    );
    items.removeWhere((e) => e.path == norm);
    final label = title?.trim().isNotEmpty == true
        ? title!.trim()
        : PdfLibraryItem.pdfTitleFromPath(norm);
    items.insert(
      0,
      PdfLibraryItem(
        path: norm,
        title: label,
        lastOpenedAt: DateTime.now(),
        bytes: f.lengthSync(),
      ),
    );
    while (items.length > 120) {
      items.removeLast();
    }
    await _bx('recordOpened').put(_recentKey, PdfLibraryItem.encodeList(items));
    notifyListeners();
  }

  List<PdfLibraryItem> recent({int limit = 40}) {
    final items = PdfLibraryItem.decodeList(
      _bx('recent').get(_recentKey) as String?,
    );
    if (limit >= items.length) return items;
    return items.take(limit).toList();
  }

  Future<void> removeRecent(String normalizedPath) async {
    final items = PdfLibraryItem.decodeList(
      _bx('removeRecent').get(_recentKey) as String?,
    )..removeWhere((e) => e.path == normalizedPath);
    await _bx('removeRecent').put(_recentKey, PdfLibraryItem.encodeList(items));
    notifyListeners();
  }
}

enum PdfReadingThemeEnum {
  light('light'),
  dark('dark'),
  system('system');

  final String storageValue;
  const PdfReadingThemeEnum(this.storageValue);

  static PdfReadingThemeEnum fromStorage(String? raw) =>
      PdfReadingThemeEnum.values.firstWhere(
        (v) => v.storageValue == raw,
        orElse: () => PdfReadingThemeEnum.system,
      );
}
