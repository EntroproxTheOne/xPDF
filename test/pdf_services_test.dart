import 'dart:io';
import 'dart:ui' show Rect;

import 'package:allinonepdf/services/pdf_merge_service.dart';
import 'package:allinonepdf/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _TestPathProviderPlatform extends PathProviderPlatform {
  _TestPathProviderPlatform(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory(p.join(root.path, 'docs'));
    dir.createSync(recursive: true);
    return dir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    final dir = Directory(p.join(root.path, 'tmp'));
    dir.createSync(recursive: true);
    return dir.path;
  }
}

Future<String> _writeSimplePdf(Directory dir, String name, String text) async {
  final document = PdfDocument();
  try {
    final page = document.pages.add();
    page.graphics.drawString(
      text,
      PdfStandardFont(PdfFontFamily.helvetica, 16),
      bounds: const Rect.fromLTWH(40, 40, 300, 40),
    );
    final path = p.join(dir.path, name);
    await File(path).writeAsBytes(await document.save(), flush: true);
    return path;
  } finally {
    document.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('xpdf_services_test_');
    PathProviderPlatform.instance = _TestPathProviderPlatform(root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'mergeToSandbox creates a readable PDF containing every input page',
    () async {
      final inputDir = await Directory(p.join(root.path, 'inputs')).create();
      final first = await _writeSimplePdf(inputDir, 'first.pdf', 'First');
      final second = await _writeSimplePdf(inputDir, 'second.pdf', 'Second');

      final mergedPath = await PdfMergeService.mergeToSandbox(<String>[
        first,
        second,
      ]);

      final mergedFile = File(mergedPath);
      expect(await mergedFile.exists(), isTrue);

      final merged = PdfDocument(inputBytes: await mergedFile.readAsBytes());
      try {
        expect(merged.pages.count, 2);
      } finally {
        merged.dispose();
      }
    },
  );

  test(
    'SecurityService detects, locks, and unlocks a PDF with a PIN',
    () async {
      final inputDir = await Directory(p.join(root.path, 'inputs')).create();
      final source = await _writeSimplePdf(inputDir, 'source.pdf', 'Secure me');
      final service = SecurityService();

      expect(await service.isPdfLocked(source), isFalse);

      final locked = await service.lockPdf(source, '1234');
      expect(await service.isPdfLocked(locked), isTrue);

      expect(
        () => PdfDocument(inputBytes: File(locked).readAsBytesSync()),
        throwsA(isA<ArgumentError>()),
      );

      final unlocked = await service.unlockPdf(locked, '1234');
      expect(await service.isPdfLocked(unlocked), isFalse);

      final unlockedDoc = PdfDocument(
        inputBytes: await File(unlocked).readAsBytes(),
      );
      try {
        expect(unlockedDoc.pages.count, 1);
      } finally {
        unlockedDoc.dispose();
      }
    },
  );
}
