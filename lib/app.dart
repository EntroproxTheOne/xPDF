import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'services/incoming_pdf_service.dart';

class AllInOnePdfApp extends StatefulWidget {
  const AllInOnePdfApp({super.key});

  @override
  State<AllInOnePdfApp> createState() => _AllInOnePdfAppState();
}

class _AllInOnePdfAppState extends State<AllInOnePdfApp> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  void _openViewer(String path) {
    appRouter.go('/viewer?path=${Uri.encodeComponent(path)}');
  }

  Future<void> _consumeInitialShareIntent() async {
    List<SharedMediaFile> batch = <SharedMediaFile>[];
    try {
      batch = await ReceiveSharingIntent.instance.getInitialMedia();
      final path = await IncomingPdfService.importFirstPdf(batch);
      await ReceiveSharingIntent.instance.reset();
      if (!mounted || path == null || path.isEmpty) return;
      _openViewer(path);
    } catch (_) {
      // Tests / desktop or channel not wired.
      try {
        await ReceiveSharingIntent.instance.reset();
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialShareIntent());
    });

    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((
      batch,
    ) async {
      final path = await IncomingPdfService.importFirstPdf(batch);
      if (!mounted || path == null) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openViewer(path);
      });
    });
  }

  @override
  void dispose() {
    unawaited(_shareSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final platform =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final effectiveDark = settings.themeMode == ThemeMode.dark ||
            (settings.themeMode == ThemeMode.system &&
                platform == Brightness.dark);
        AppColors.setDarkMode(effectiveDark);

        return MaterialApp.router(
          title: 'xPDF',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          routerConfig: appRouter,
          themeAnimationDuration: const Duration(milliseconds: 220),
          themeAnimationCurve: Curves.easeOutCubic,
        );
      },
    );
  }
}
