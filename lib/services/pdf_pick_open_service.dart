import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'pdf_library_repository.dart';
import 'pdf_sandbox_service.dart';

Future<void> pickPdfAndNavigateViewer(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return;
  if (!context.mounted) return;
  await openPdfFromExternalPath(context, platformPath);
}

Future<void> openPdfFromExternalPath(BuildContext context, String path) async {
  final sandboxPath = await PdfSandboxService.importFileToSandbox(path);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  if (!context.mounted) return;
  await context.push('/viewer?path=${Uri.encodeComponent(sandboxPath)}');
}

Future<void> pickPdfAndNavigateExport(BuildContext context) async {
  await _pickPdfThenPath(context, (sandboxPath) async {
    if (!context.mounted) return;
    await context.push('/export?path=${Uri.encodeComponent(sandboxPath)}');
  });
}

Future<void> pickPdfAndNavigateEditor(BuildContext context) async {
  await _pickPdfThenPath(context, (sandboxPath) async {
    if (!context.mounted) return;
    await context.push('/editor?path=${Uri.encodeComponent(sandboxPath)}');
  });
}

typedef PdfSandboxPathCallback = Future<void> Function(String sandboxPath);

Future<void> _pickPdfThenPath(
  BuildContext context,
  PdfSandboxPathCallback next,
) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return;
  if (!context.mounted) return;
  final sandboxPath = await PdfSandboxService.importFileToSandbox(platformPath);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  if (!context.mounted) return;
  await next(sandboxPath);
}

Future<void> pickPdfAndNavigatePrint(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return;
  if (!context.mounted) return;
  final sandboxPath = await PdfSandboxService.importFileToSandbox(platformPath);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  if (!context.mounted) return;
  await context.push('/print?path=${Uri.encodeComponent(sandboxPath)}');
}

Future<void> pickPdfThenShareViaSheet(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return;
  if (!context.mounted) return;
  final sandboxPath = await PdfSandboxService.importFileToSandbox(platformPath);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  if (!context.mounted) return;
  await Share.shareXFiles(<XFile>[
    XFile(sandboxPath, mimeType: 'application/pdf'),
  ], subject: p.basename(sandboxPath));
}

Future<void> pickPdfAndNavigateLock(BuildContext context) async {
  await pickPdfAndNavigateSecurity(context, mode: 'lock');
}

Future<void> pickPdfAndNavigateUnlock(BuildContext context) async {
  await pickPdfAndNavigateSecurity(context, mode: 'unlock');
}

Future<void> pickPdfAndNavigateLockStatus(BuildContext context) async {
  await pickPdfAndNavigateSecurity(context, mode: 'status');
}

Future<void> pickPdfAndNavigateSecurity(
  BuildContext context, {
  required String mode,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return;
  if (!context.mounted) return;
  final sandboxPath = await PdfSandboxService.importFileToSandbox(platformPath);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  if (!context.mounted) return;
  await context.push(
    '/lock?path=${Uri.encodeComponent(sandboxPath)}&mode=$mode',
  );
}

Future<String?> pickSinglePdfToSandbox() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['pdf'],
  );
  final platformPath = result?.files.single.path;
  if (platformPath == null || platformPath.isEmpty) return null;
  final sandboxPath = await PdfSandboxService.importFileToSandbox(platformPath);
  await PdfLibraryRepository.instance.recordOpened(sandboxPath);
  return sandboxPath;
}
