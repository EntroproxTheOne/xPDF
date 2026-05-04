import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/settings/app_settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/xp_ui.dart';

/// Settings aligned with Stitch settings mock (`code.html`): glass panels, rails, theme grid.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const EdgeInsets _pagePad = EdgeInsets.fromLTRB(24, 8, 24, 112);
  static const double _railBreakpoint = 900;



  /// 0 = Light, 1 = Dark, 2 = System (mock “Theme” row).
  final AppSettingsController _settings = AppSettingsController.instance;
  int _sideRailIndex = 0;

  int get _appearanceTheme => _settings.selectedThemeIndex;

  @override
  void dispose() {
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: AppTypography.bodySmall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          const XpAmbientBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpMobileTopBar(
                onMenu: () => showXpMissionMenu(context),
                centerTitle: '',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= _railBreakpoint;
                    if (!wide) {
                      return ListView(
                        padding: _pagePad,
                        children: [
                          ..._pageHeader(context),
                          const SizedBox(height: 20),
                          _preferencesSection(context),
                          const SizedBox(height: 28),
                          _aboutSection(context),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 0, 0),
                          child: _SideRail(
                            index: _sideRailIndex,
                            onChanged:
                                (i) =>
                                    setState(() => _sideRailIndex = i),
                          ),
                        ),
                        Expanded(
                          child:
                              switch (_sideRailIndex) {
                                0 =>
                                  ListView(
                                    padding: _pagePad,
                                    children: [
                                      ..._pageHeader(context),
                                      const SizedBox(height: 24),
                                      _preferencesSection(context),
                                    ],
                                  ),
                                _ =>
                                  ListView(
                                    padding: _pagePad,
                                    children: [
                                      ..._pageHeader(context),
                                      const SizedBox(height: 24),
                                      _aboutSection(context),
                                    ],
                                  ),
                              },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _pageHeader(BuildContext context) {
    return [
      Text(
        'Settings',
        style: AppTypography.display.copyWith(
          fontSize: 32,
          height: 40 / 32,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Manage your app preferences.',
        style: AppTypography.body,
      ),
    ];
  }


  Widget _preferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassSettingsSection(
          sectionIcon: Iconsax.setting_5,
          sectionIconTint: AppColors.secondary,
          title: 'Preferences',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Theme', style: AppTypography.bodyLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  return Row(
                    children: [
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Iconsax.sun_1,
                          label: 'Light',
                          selected: _appearanceTheme == 0,
                          onTap:
                              () => _settings.setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Iconsax.moon,
                          label: 'Dark',
                          selected: _appearanceTheme == 1,
                          onTap:
                              () => _settings.setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Iconsax.sun_fog,
                          label: 'System',
                          selected: _appearanceTheme == 2,
                          onTap:
                              () => _settings.setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Workflow', style: AppTypography.bodyLarge),
              const SizedBox(height: 12),
              const _SettingsValueRow(
                icon: Iconsax.image,
                title: 'Default image quality',
                value: 'High',
              ),
              const SizedBox(height: 8),
              const _SettingsValueRow(
                icon: Iconsax.document,
                title: 'Default page size',
                value: 'A4',
              ),
              const SizedBox(height: 8),
              const _SettingsValueRow(
                icon: Iconsax.folder_2,
                title: 'Storage location',
                value: 'Internal',
              ),
              const SizedBox(height: 8),
              const _SettingsValueRow(
                icon: Iconsax.language_square,
                title: 'Language',
                value: 'English',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutSection(BuildContext context) {
    return _GlassSettingsSection(
      sectionIcon: Iconsax.info_circle,
      sectionIconTint: AppColors.tertiary,
      title: 'About',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AboutDividerRow(left: 'Version', right: '1.0.0 (+1)'),
          _AboutTrailingRow(
            label: 'Terms of Service',
            onTap:
                () => _toast('Terms of service placeholder'),
          ),
          _AboutTrailingRow(
            label: 'Privacy Policy',
            onTap:
                () => _toast('Privacy policy placeholder'),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, IconData ic, int i) {
      final sel = index == i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap:
                () {
                  XpHaptics.surfaceTap();
                  onChanged(i);
                },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color:
                    sel
                        ? AppColors.surfaceContainer
                        : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    ic,
                    size: 20,
                    color:
                        sel
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color:
                          sel
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chip('Preferences', Iconsax.setting_5, 0),
          chip('About', Iconsax.info_circle, 1),
        ],
      ),
    );
  }
}

class _GlassSettingsSection extends StatelessWidget {
  const _GlassSettingsSection({
    required this.sectionIcon,
    required this.sectionIconTint,
    required this.title,
    required this.child,
  });

  final IconData sectionIcon;
  final Color sectionIconTint;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(sectionIcon, color: sectionIconTint, size: 24),
              const SizedBox(width: 10),
              Text(title, style: AppTypography.headline),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () {
            XpHaptics.surfaceTap();
            onTap();
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.surfaceContainerLow
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.onSurface),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                fontSize: 11,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTypography.label)),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Iconsax.arrow_right_3, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}

class _AboutDividerRow extends StatelessWidget {
  const _AboutDividerRow({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border(
                bottom:
                    BorderSide(color: AppColors.surfaceContainerHigh),
              ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Text(left, style: AppTypography.label),
              const Spacer(),
              Text(
                right,
                style: AppTypography.body.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutTrailingRow extends StatelessWidget {
  const _AboutTrailingRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () {
            XpHaptics.surfaceTap();
            onTap();
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: AppTypography.label),
            const Spacer(),
            Icon(Iconsax.export_3, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
