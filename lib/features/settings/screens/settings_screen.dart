import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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

  final _nameCtrl = TextEditingController(text: 'Jane Doe');
  final _emailCtrl = TextEditingController(text: 'jane.doe@example.com');

  /// 0 = Light, 1 = Dark, 2 = System (mock “Theme” row).
  int _appearanceTheme = 0;
  bool _emailSummaries = true;
  bool _processingAlerts = false;
  int _sideRailIndex = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
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
                          _accountSection(context),
                          const SizedBox(height: 28),
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
                                      _accountSection(context),
                                    ],
                                  ),
                                1 =>
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
        'Manage your account settings and preferences.',
        style: AppTypography.body,
      ),
    ];
  }

  Widget _accountSection(BuildContext context) {
    return _GlassSettingsSection(
      sectionIcon: Iconsax.user,
      sectionIconTint: AppColors.primary,
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarBlock(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LuminaLabeledField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: 12),
                    _LuminaLabeledField(
                      label: 'Email Address',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _GhostPillButton(
                label: 'Cancel',
                onPressed: () {
                  XpHaptics.surfaceTap();
                  _toast('Cancelled');
                },
              ),
              const SizedBox(width: 12),
              _PrimaryPillButton(
                label: 'Save Changes',
                onPressed: () {
                  XpHaptics.surfaceTap();
                  _toast('Changes saved locally');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarBlock() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => _toast('Profile photo picker coming soon'),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.surfaceContainer, width: 2),
          ),
          child: const Icon(
            Iconsax.user,
            size: 36,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
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
              Text('Notifications', style: AppTypography.bodyLarge),
              const SizedBox(height: 12),
              _NotificationToggleRow(
                title: 'Email Summaries',
                subtitle: 'Receive weekly processing reports',
                value: _emailSummaries,
                onChanged:
                    (v) => setState(() => _emailSummaries = v),
              ),
              const SizedBox(height: 10),
              _NotificationToggleRow(
                title: 'Processing Alerts',
                subtitle: 'Notify when large files complete',
                value: _processingAlerts,
                onChanged:
                    (v) => setState(() => _processingAlerts = v),
              ),
              const SizedBox(height: 24),
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
                              () => setState(() => _appearanceTheme = 0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Iconsax.moon,
                          label: 'Dark',
                          selected: _appearanceTheme == 1,
                          onTap:
                              () => setState(() => _appearanceTheme = 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Iconsax.sun_fog,
                          label: 'System',
                          selected: _appearanceTheme == 2,
                          onTap:
                              () => setState(() => _appearanceTheme = 2),
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
          Divider(color: AppColors.errorContainer.withValues(alpha: 0.9)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed:
                () {
                  XpHaptics.surfaceTap();
                  _toast('Staying signed in locally');
                },
            icon: Icon(Iconsax.logout_1, size: 20, color: AppColors.error),
            label: Text(
              'Sign Out',
              style: AppTypography.label.copyWith(color: AppColors.error),
            ),
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
          chip('Account', Iconsax.user, 0),
          chip('Preferences', Iconsax.setting_5, 1),
          chip('About', Iconsax.info_circle, 2),
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

class _LuminaLabeledField extends StatelessWidget {
  const _LuminaLabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.body,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.inputFill,
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onTapOutside:
              (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
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
        decoration: const BoxDecoration(
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

class _GhostPillButton extends StatelessWidget {
  const _GhostPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: AppColors.glassChromeFill,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: AppColors.orangeGradient,
            boxShadow: AppColors.orangeGlowShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Text(
              label,
              style: AppTypography.buttonOnAccent.copyWith(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

