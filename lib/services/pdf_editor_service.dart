import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size, Color;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Syncfusion-backed mutations for Acrobat-style workflows (bounded reflow fidelity).
class PdfEditorService {
  PdfDocument? _document;
  String? _loadedPath;

  bool get hasDocument => _document != null;
  String? get loadedPath => _loadedPath;

  int get pageCount => _document?.pages.count ?? 0;

  /// Serialized document for viewers (reflects unpersisted edits in memory).
  List<int> snapshotBytesSync() {
    final doc = _document;
    if (doc == null) throw StateError('No document loaded.');
    return doc.saveSync();
  }

  Size pageMediaSize(int pageIndex) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) {
      return Size.zero;
    }
    return doc.pages[pageIndex].size;
  }

  /// Loads PDF from disk. Throws if file missing or unreadable without proper password handling.
  Future<void> load(String path, {String? password}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError.value(path, 'path', 'PDF not found');
    }
    _disposeCurrent();
    final bytes = await file.readAsBytes();
    _document = password != null && password.isNotEmpty
        ? PdfDocument(inputBytes: bytes, password: password)
        : PdfDocument(inputBytes: bytes);
    _loadedPath = path;
  }

  void _disposeCurrent() {
    _document?.dispose();
    _document = null;
    _loadedPath = null;
  }

  void dispose() => _disposeCurrent();

  void deletePage(int index) {
    final doc = _document;
    if (doc == null) return;
    if (doc.pages.count <= 1) return;
    if (index < 0 || index >= doc.pages.count) return;
    doc.pages.removeAt(index);
  }

  void duplicatePage(int index) {
    final doc = _document;
    if (doc == null) return;
    final pages = doc.pages;
    if (index < 0 || index >= pages.count) return;
    final PdfPage src = pages[index];
    final template = src.createTemplate();
    final sz = src.size;
    final rot = src.rotation;
    final PdfPage inserted = pages.insert(index + 1, sz);
    inserted.rotation = rot;
    inserted.graphics.drawPdfTemplate(template, Offset.zero, sz);
  }

  void rotatePageClockwise(int index) {
    final doc = _document;
    if (doc == null) return;
    if (index < 0 || index >= doc.pages.count) return;
    final page = doc.pages[index];
    final next = PdfPageRotateAngle.values[(page.rotation.index + 1) % 4];
    page.rotation = next;
  }

  void insertBlankAfter(int index) {
    final doc = _document;
    if (doc == null) return;
    final pages = doc.pages;
    final insertAt = (index + 1).clamp(0, pages.count);
    pages.insert(insertAt, PdfPageSize.a4);
  }

  void insertBlankAtEnd() => insertBlankAfter(pageCount - 1);

  void movePage(int fromIndex, int toIndex) {
    final doc = _document;
    if (doc == null) return;
    final pages = doc.pages;
    final n = pages.count;
    if (fromIndex < 0 || fromIndex >= n || toIndex < 0 || toIndex >= n) return;
    if (fromIndex == toIndex) return;

    final PdfPage src = pages[fromIndex];
    final template = src.createTemplate();
    final sz = src.size;
    final rot = src.rotation;
    pages.removeAt(fromIndex);

    var insertPos = toIndex;
    if (fromIndex < toIndex) insertPos--;

    final PdfPage inserted = pages.insert(insertPos, sz);
    inserted.rotation = rot;
    inserted.graphics.drawPdfTemplate(template, Offset.zero, sz);
  }

  /// Covers an arbitrary rectangle on the chosen page — best-effort redaction shim.
  void coverRectangle(int pageIndex, Rect rect, {PdfBrush? brush}) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) return;
    final page = doc.pages[pageIndex];
    page.graphics.drawRectangle(brush: brush ?? PdfBrushes.white, bounds: rect);
  }

  /// Find/replace approximation: erases bounding boxes returned by extractor and overlays replacement strings.
  int replaceVisibleTextAcrossDocument(String query, String replacement) {
    final doc = _document;
    if (doc == null || query.trim().isEmpty) return 0;
    final extractor = PdfTextExtractor(doc);
    final matches = extractor.findText(<String>[
      query,
    ], searchOption: TextSearchOption.caseSensitive);
    if (matches.isEmpty) return 0;

    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final format = PdfStringFormat(
      alignment: PdfTextAlignment.left,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    for (final m in matches) {
      if (m.pageIndex < 0 || m.pageIndex >= doc.pages.count) continue;
      final page = doc.pages[m.pageIndex];
      final inflate = m.bounds.inflate(1.25);
      page.graphics.drawRectangle(brush: PdfBrushes.white, bounds: inflate);
      page.graphics.drawString(
        replacement,
        font,
        brush: PdfBrushes.black,
        bounds: m.bounds,
        format: format,
      );
    }
    return matches.length;
  }

  List<TextWord> extractWordsForPage(int pageIndex) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) {
      return <TextWord>[];
    }
    final extractor = PdfTextExtractor(doc);
    final lines = extractor.extractTextLines(
      startPageIndex: pageIndex,
      endPageIndex: pageIndex,
    );
    final out = <TextWord>[];
    for (final line in lines) {
      out.addAll(line.wordCollection);
    }
    return out;
  }

  /// Finds the visually smallest hit target under [pdfCoord] where coordinates
  /// match [pageMediaSize]'s space (either top‑left or flipped Y for PDF‑style).
  TextWord? findWordAtPdfPoint(int pageIndex, Offset pdfCoord, Size media) {
    final words = extractWordsForPage(pageIndex);
    final direct = _pickBestWordContaining(words, pdfCoord);
    if (direct != null) return direct;
    if (media.height <= 0 || media.width <= 0) return null;
    final alt = Offset(pdfCoord.dx, media.height - pdfCoord.dy);
    return _pickBestWordContaining(words, alt);
  }

  TextWord? _pickBestWordContaining(Iterable<TextWord> words, Offset p) {
    TextWord? best;
    double bestArea = double.infinity;
    for (final w in words) {
      if (!_containsWithMargin(w.bounds, p, margin: 2.5)) continue;
      if (w.text.trim().isEmpty) continue;
      final a = math.max(w.bounds.width, 1.0) * math.max(w.bounds.height, 1.0);
      if (a < bestArea) {
        bestArea = a;
        best = w;
      }
    }
    return best;
  }

  bool _containsWithMargin(Rect r, Offset p, {required double margin}) {
    final e = Rect.fromLTRB(
      r.left - margin,
      r.top - margin,
      r.right + margin,
      r.bottom + margin,
    );
    return e.contains(p);
  }

  PdfColor _pdfColor(Color color) {
    final argb = color.toARGB32();
    return PdfColor((argb >> 16) & 0xff, (argb >> 8) & 0xff, argb & 0xff);
  }

  PdfStandardFont fontMatchingWord(
    TextWord word, {
    double? overrideSize,
    String? overrideFontFamily,
    bool? forceBold,
    bool? forceItalic,
  }) {
    final size = overrideSize ?? (word.fontSize > 2 ? word.fontSize : 12.0);
    final name = (overrideFontFamily ?? word.fontName).toLowerCase();
    PdfFontFamily family = PdfFontFamily.helvetica;
    if (name.contains('courier')) {
      family = PdfFontFamily.courier;
    } else if (name.contains('times') || name.contains('roman')) {
      family = PdfFontFamily.timesRoman;
    } else if (name.contains('symbol')) {
      family = PdfFontFamily.symbol;
    } else if (name.contains('zapf') || name.contains('ding')) {
      family = PdfFontFamily.zapfDingbats;
    }
    if (word.fontStyle.isEmpty) {
      return PdfStandardFont(family, size);
    }
    final hasItalic =
        forceItalic ?? word.fontStyle.contains(PdfFontStyle.italic);
    final hasBold = forceBold ?? word.fontStyle.contains(PdfFontStyle.bold);
    if (hasItalic && hasBold) {
      return PdfStandardFont(
        family,
        size,
        multiStyle: const [PdfFontStyle.bold, PdfFontStyle.italic],
      );
    }
    if (hasBold) return PdfStandardFont(family, size, style: PdfFontStyle.bold);
    if (hasItalic) {
      return PdfStandardFont(family, size, style: PdfFontStyle.italic);
    }
    return PdfStandardFont(family, size);
  }

  /// Erases [word]'s raster box then draws [newText] with the extractor font.
  /// Best‑effort: reflow/longer replacement may clip visually.
  void replaceExtractedWord(
    int pageIndex,
    TextWord word,
    String newText, {
    Color color = const Color(0xFF000000),
    double? fontSize,
    bool? forceBold,
    bool? forceItalic,
    String? fontFamily,
  }) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) {
      return;
    }
    final value = newText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (value.trim().isEmpty) return;
    final font = fontMatchingWord(
      word,
      overrideSize: fontSize,
      overrideFontFamily: fontFamily,
      forceBold: forceBold,
      forceItalic: forceItalic,
    );
    final measured = font.measureString(value);
    final replacementBounds = Rect.fromLTWH(
      word.bounds.left,
      word.bounds.top,
      math.max(word.bounds.width, measured.width + 6),
      math.max(word.bounds.height, measured.height + 4),
    );
    final page = doc.pages[pageIndex];
    final inflate = word.bounds.inflate(2.5);
    page.graphics.drawRectangle(brush: PdfBrushes.white, bounds: inflate);
    page.graphics.drawString(
      value,
      font,
      brush: PdfSolidBrush(_pdfColor(color)),
      bounds: replacementBounds,
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
  }

  /// Finds the word at [pdfCoord] and draws a semi-transparent yellow highlight over it.
  void highlightWordAtPoint(int pageIndex, Offset pdfCoord, Size media) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) return;

    final word = findWordAtPdfPoint(pageIndex, pdfCoord, media);
    if (word == null || word.text.trim().isEmpty) return;

    final page = doc.pages[pageIndex];
    // Syncfusion PdfColor uses 0-255 RGB. We simulate a semi-transparent yellow
    // by using a solid light yellow or applying a brush with alpha if supported.
    // PdfBrush doesn't support alpha directly in the constructor easily, but we
    // can use a lighter yellow color. Actually, PdfSolidBrush takes PdfColor.
    // Let's use a very light yellow to simulate a highlighter over black text.
    // Inflate slightly for better visual coverage
    final bounds = word.bounds.inflate(1.5);

    // To properly simulate highlighter (multiply blend mode), we'd need advanced graphics state.
    // For simplicity, we draw the rectangle. Wait, if we draw a solid rectangle, it will cover the text.
    // Syncfusion allows setting transparency via PdfGraphicsState!
    page.graphics.save();
    page.graphics.setTransparency(0.4);
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 235, 59)),
      bounds: bounds,
    );
    page.graphics.restore();
  }

  /// Draws a freehand stroke path onto the specified page.
  void drawPathOnPage(
    int pageIndex,
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    final doc = _document;
    if (doc == null || pageIndex < 0 || pageIndex >= doc.pages.count) return;
    if (points.length < 2) return;

    final page = doc.pages[pageIndex];
    final pdfColor = _pdfColor(color);
    final pen = PdfPen(pdfColor, width: strokeWidth)
      ..lineCap = PdfLineCap.round
      ..lineJoin = PdfLineJoin.round;

    final path = PdfPath();
    for (var i = 0; i < points.length - 1; i++) {
      path.addLine(points[i], points[i + 1]);
    }

    page.graphics.drawPath(path, pen: pen);
  }

  /// Stamps "Page X of Y" at the bottom center of every page.
  void stampPageNumbers() {
    final doc = _document;
    if (doc == null) return;

    final count = doc.pages.count;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final format = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    final brush = PdfSolidBrush(PdfColor(0, 0, 0));

    for (var i = 0; i < count; i++) {
      final page = doc.pages[i];
      final text = 'Page ${i + 1} of $count';

      // Calculate bounds at the bottom
      final bounds = Rect.fromLTWH(
        0,
        page.size.height - 40,
        page.size.width,
        20,
      );
      page.graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: bounds,
        format: format,
      );
    }
  }

  /// Stamps a diagonal watermark on every page.
  void stampWatermark(String text) {
    final doc = _document;
    if (doc == null || text.trim().isEmpty) return;

    final count = doc.pages.count;
    final font = PdfStandardFont(
      PdfFontFamily.helvetica,
      60,
      style: PdfFontStyle.bold,
    );
    final brush = PdfSolidBrush(PdfColor(150, 150, 150)); // Gray watermark
    final format = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    for (var i = 0; i < count; i++) {
      final page = doc.pages[i];

      page.graphics.save();
      page.graphics.setTransparency(0.3); // 30% opacity

      // Translate to center
      page.graphics.translateTransform(
        page.size.width / 2,
        page.size.height / 2,
      );
      // Rotate diagonally
      page.graphics.rotateTransform(-45);

      // Draw centered at origin
      page.graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: const Rect.fromLTWH(0, 0, 0, 0),
        format: format,
      );

      page.graphics.restore();
    }
  }

  Future<String> saveCopyNextToOriginal() async {
    final doc = _document;
    final base = _loadedPath;
    if (doc == null || base == null) {
      throw StateError('No document loaded.');
    }

    final directory = File(base).existsSync()
        ? p.dirname(base)
        : (await getApplicationDocumentsDirectory()).path;
    final stem = p.basenameWithoutExtension(base);
    final stamped =
        '${stem}_edited_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final destination = p.join(directory, stamped);
    File(destination).writeAsBytesSync(doc.saveSync());
    return p.normalize(destination);
  }

  /// Saves a revision containing exactly one page cloned from [zeroBasedPageIndex].
  Future<String> exportSinglePagePdf(
    int zeroBasedPageIndex, {
    String? preferredOutputDirectory,
  }) async {
    final doc = _document;
    if (doc == null) {
      throw StateError('No document loaded.');
    }
    if (zeroBasedPageIndex < 0 || zeroBasedPageIndex >= doc.pages.count) {
      throw ArgumentError.value(
        zeroBasedPageIndex,
        'pageIndex',
        'Bad page index',
      );
    }

    final PdfDocument excerpt = PdfDocument(inputBytes: doc.saveSync());

    try {
      for (var i = excerpt.pages.count - 1; i >= 0; i--) {
        if (i != zeroBasedPageIndex) {
          excerpt.pages.removeAt(i);
        }
      }

      late final String baseDir;
      final preferred = preferredOutputDirectory?.trim();
      if (preferred != null && preferred.isNotEmpty) {
        baseDir = preferred;
        await Directory(baseDir).create(recursive: true);
      } else if (_loadedPath != null && File(_loadedPath!).existsSync()) {
        baseDir = p.dirname(_loadedPath!);
      } else {
        baseDir = (await getApplicationDocumentsDirectory()).path;
      }

      final outPath = p.join(
        baseDir,
        '${p.basenameWithoutExtension(_loadedPath ?? 'page')}_${zeroBasedPageIndex + 1}_extract_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      File(outPath).writeAsBytesSync(excerpt.saveSync());
      return p.normalize(outPath);
    } finally {
      excerpt.dispose();
    }
  }

  /// Writes a new PDF into [preferredOutputDirectory] when set; otherwise next
  /// to the loaded file (if it exists on disk) or app documents.
  Future<String> exportSubsetPagesToFile(
    Set<int> indicesToKeep, {
    String? preferredOutputDirectory,
  }) async {
    final doc = _document;
    final base = _loadedPath;
    if (doc == null || base == null) {
      throw StateError('No document loaded.');
    }
    if (indicesToKeep.isEmpty) {
      throw ArgumentError.value(
        indicesToKeep,
        'indicesToKeep',
        'Must select at least one page.',
      );
    }
    final n = doc.pages.count;
    for (final i in indicesToKeep) {
      if (i < 0 || i >= n) {
        throw ArgumentError.value(i, 'pageIndex', 'Out of range 0–${n - 1}.');
      }
    }

    final PdfDocument excerpt = PdfDocument(inputBytes: doc.saveSync());
    try {
      for (var i = excerpt.pages.count - 1; i >= 0; i--) {
        if (!indicesToKeep.contains(i)) {
          excerpt.pages.removeAt(i);
        }
      }
      if (excerpt.pages.count == 0) {
        throw StateError('Export subset produced zero pages.');
      }

      late final String directory;
      final preferred = preferredOutputDirectory?.trim();
      if (preferred != null && preferred.isNotEmpty) {
        directory = preferred;
        await Directory(directory).create(recursive: true);
      } else if (File(base).existsSync()) {
        directory = p.dirname(base);
      } else {
        directory = (await getApplicationDocumentsDirectory()).path;
      }
      final stem = p.basenameWithoutExtension(base);
      final outPath = p.join(
        directory,
        '${stem}_export_${indicesToKeep.length}p_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      File(outPath).writeAsBytesSync(excerpt.saveSync());
      return p.normalize(outPath);
    } finally {
      excerpt.dispose();
    }
  }
}
