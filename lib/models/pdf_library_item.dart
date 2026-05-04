import 'dart:convert';

/// A recently accessed PDF backed by Hive JSON storage ([PdfLibraryRepository]).
class PdfLibraryItem {
  PdfLibraryItem({
    required this.path,
    required this.title,
    required this.lastOpenedAt,
    this.bytes,
  });

  final String path;
  final String title;
  final DateTime lastOpenedAt;

  /// Optional persisted size hint (lazy; not guaranteed).
  final int? bytes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'title': title,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
    'bytes': bytes,
  };

  factory PdfLibraryItem.fromJson(Map<String, dynamic> json) {
    return PdfLibraryItem(
      path: json['path'] as String,
      title:
          json['title'] as String? ?? pdfTitleFromPath(json['path'] as String),
      lastOpenedAt:
          DateTime.tryParse(json['lastOpenedAt'] as String? ?? '') ??
          DateTime.now(),
      bytes: json['bytes'] as int?,
    );
  }

  static String pdfTitleFromPath(String rawPath) {
    final trimmed = rawPath.replaceAll(RegExp(r'[/\\]+$'), '');
    final i = trimmed.lastIndexOf(RegExp(r'[/\\]'));
    return i >= 0 ? trimmed.substring(i + 1) : trimmed;
  }

  static String encodeList(List<PdfLibraryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<PdfLibraryItem> decodeList(String? encoded) {
    if (encoded == null || encoded.isEmpty) return <PdfLibraryItem>[];
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list
          .map(
            (e) => PdfLibraryItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return <PdfLibraryItem>[];
    }
  }
}
