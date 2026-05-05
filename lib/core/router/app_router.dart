import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/tools/screens/tools_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/create/screens/merge_pdfs_screen.dart';
import '../../features/create/screens/scan_document_screen.dart';
import '../../features/viewer/screens/pdf_viewer_screen.dart';
import '../../features/editor/screens/pdf_editor_screen.dart';
import '../../features/export/screens/export_screen.dart';
import '../../features/security/screens/pdf_locker_screen.dart';
import '../../features/security/screens/security_screen.dart';
import '../../features/print/screens/print_preview_screen.dart';
import '../../features/tools/screens/pdf_compress_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/create', redirect: (context, state) => '/tools'),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _buildPage(const HomeScreen(), state),
        ),
        GoRoute(
          path: '/documents',
          pageBuilder: (context, state) => _buildPage(
            DocumentsScreen(
              initialFocusSearch:
                  state.uri.queryParameters['focus'] == 'search',
              initialQuery: state.uri.queryParameters['q'],
            ),
            state,
          ),
        ),
        GoRoute(
          path: '/tools',
          pageBuilder: (context, state) =>
              _buildPage(const ToolsScreen(), state),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              _buildPage(const SettingsScreen(), state),
        ),
      ],
    ),
    GoRoute(
      path: '/secure',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slidePage(const SecurityScreen(), state),
    ),
    GoRoute(path: '/bulk-import', redirect: (context, state) => '/merge-pdfs'),
    GoRoute(
      path: '/merge-pdfs',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideUpPage(const MergePdfsScreen(), state),
    ),
    GoRoute(
      path: '/scan',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideUpPage(const ScanDocumentScreen(), state),
    ),
    GoRoute(
      path: '/viewer',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'] ?? '';
        return _slidePage(PdfViewerScreen(filePath: filePath), state);
      },
    ),
    GoRoute(
      path: '/editor',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'] ?? '';
        return _slidePage(PdfEditorScreen(filePath: filePath), state);
      },
    ),
    GoRoute(
      path: '/export',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'] ?? '';
        return _slideUpPage(ExportScreen(filePath: filePath), state);
      },
    ),
    GoRoute(
      path: '/lock',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'] ?? '';
        final mode = switch (state.uri.queryParameters['mode']) {
          'unlock' => PdfSecurityMode.unlock,
          'status' => PdfSecurityMode.status,
          _ => PdfSecurityMode.lock,
        };
        return _slideUpPage(
          PdfLockerScreen(filePath: filePath, initialMode: mode),
          state,
        );
      },
    ),
    GoRoute(
      path: '/compress',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'];
        return _slideUpPage(PdfCompressScreen(initialPath: filePath), state);
      },
    ),
    GoRoute(
      path: '/print',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final filePath = state.uri.queryParameters['path'] ?? '';
        return _slidePage(PrintPreviewScreen(filePath: filePath), state);
      },
    ),
  ],
);

CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage _slideUpPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
