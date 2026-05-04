import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device Latin-script OCR via ML Kit (not a generative LLM).
///
/// Intended for scanned page images produced by [`ScannerService`].
class OcrService {
  /// Recognizes text from a JPEG/PNG/etc. stored at [absolutePath].
  Future<String> recognizeLatin(String absolutePath) async {
    final file = File(absolutePath);
    if (!file.existsSync()) {
      throw ArgumentError.value(
        absolutePath,
        'absolutePath',
        'Image file does not exist',
      );
    }

    if (kIsWeb) {
      throw UnsupportedError('OCR runs on Android and iOS only.');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final image = InputImage.fromFilePath(absolutePath);
      final RecognizedText result = await recognizer.processImage(image);
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }

  /// OCR all images in page order (concatenates with blank lines between pages).
  Future<String> recognizeLatinConcat(List<String> imagePaths) async {
    final out = StringBuffer();
    for (var i = 0; i < imagePaths.length; i++) {
      final text = await recognizeLatin(imagePaths[i]);
      if (text.isEmpty) continue;
      if (out.isNotEmpty) out.writeln('\n—— Page ${i + 1} ——\n');
      out.writeln(text);
    }
    return out.toString().trim();
  }
}
