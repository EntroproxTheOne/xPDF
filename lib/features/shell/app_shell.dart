import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass_bottom_nav.dart';
import '../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  /// Matches four-tab mocks: Home(0), Tools(1), History/Documents(2), Settings(3).
  int _currentTabIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    switch (path) {
      case '/':
        return 0;
      case '/tools':
        return 1;
      case '/documents':
        return 2;
      case '/settings':
        return 3;
      default:
        return 0;
    }
  }

  void _goTab(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/');
      case 1:
        context.go('/tools');
      case 2:
        context.go('/documents');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentTabIndex(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: index,
        onTap: (i) => _goTab(context, i),
      ),
    );
  }
}
