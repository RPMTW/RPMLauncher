import 'dart:ui';

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/data.dart';

enum LauncherTheme { dark, light }

class ThemeUtil {
  static String toI18nString(LauncherTheme theme) {
    switch (theme) {
      case LauncherTheme.light:
        return I18n.format('settings.appearance.theme.light');
      case LauncherTheme.dark:
        return I18n.format('settings.appearance.theme.dark');
    }
  }

  static int toInt(LauncherTheme theme) {
    switch (theme) {
      case LauncherTheme.light:
        return 0;
      case LauncherTheme.dark:
        return 1;
    }
  }

  static LauncherTheme getThemeByID(int id) {
    switch (id) {
      case 0:
        return LauncherTheme.light;
      case 1:
        return LauncherTheme.dark;
      default:
        return LauncherTheme.light;
    }
  }

  static ThemeData getTheme([BuildContext? context]) {
    return Theme.of(context ?? navigator.context);
  }

  static LauncherTheme getThemeByConfig() {
    return ThemeUtil.getThemeByID(launcherConfig.themeId);
  }

  static ThemeCollection themeCollection() {
    return ThemeCollection(themes: {
      ThemeUtil.toInt(LauncherTheme.light): ThemeData(
          // colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
          fontFamily: 'font',
          tooltipTheme: const TooltipThemeData(
            textStyle: TextStyle(fontFamily: 'font', color: Colors.white),
            waitDuration: Duration(milliseconds: 250),
          ),
          useMaterial3: true),
      ThemeUtil.toInt(LauncherTheme.dark): ThemeData(
          // colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          fontFamily: 'font',
          tooltipTheme: const TooltipThemeData(
            textStyle: TextStyle(fontFamily: 'font', color: Colors.black),
            waitDuration: Duration(milliseconds: 250),
          ),
          useMaterial3: true),
    });
  }

  static int getSystem() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;

    switch (brightness) {
      case Brightness.light:
        return toInt(LauncherTheme.light);

      case Brightness.dark:
        return toInt(LauncherTheme.dark);
    }
  }
}

class DynamicThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeData themeData) builder;

  const DynamicThemeBuilder({Key? key, required this.builder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        themeCollection: ThemeUtil.themeCollection(),
        defaultThemeId: ThemeUtil.toInt(LauncherTheme.dark),
        builder: builder);
  }
}
