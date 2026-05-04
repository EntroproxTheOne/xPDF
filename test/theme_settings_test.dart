import 'package:allinonepdf/core/settings/app_settings_controller.dart';
import 'package:allinonepdf/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings controller maps theme modes to settings tab selection', () {
    final settings = AppSettingsController.instance;

    settings.setThemeMode(ThemeMode.light);
    expect(settings.selectedThemeIndex, 0);

    settings.setThemeMode(ThemeMode.dark);
    expect(settings.selectedThemeIndex, 1);

    settings.setThemeMode(ThemeMode.system);
    expect(settings.selectedThemeIndex, 2);
  });

  test('app color tokens switch between light and dark surfaces', () {
    AppColors.setDarkMode(false);
    final lightBackground = AppColors.backgroundPrimary;
    final lightText = AppColors.textPrimary;

    AppColors.setDarkMode(true);
    expect(AppColors.backgroundPrimary, isNot(lightBackground));
    expect(AppColors.textPrimary, isNot(lightText));
    expect(AppColors.textPrimary.computeLuminance(), greaterThan(0.6));

    AppColors.setDarkMode(false);
  });
}
