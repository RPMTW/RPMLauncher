import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_data.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';
import 'package:rpmlauncher/ui/theme/theme_provider.dart';

class LauncherTheme {
  static ThemeChangeNotifier of(BuildContext context) {
    return Provider.of<ThemeChangeNotifier>(context, listen: false);
  }

  static RPMLThemeType getTypeByConfig() {
    final id = launcherConfig.themeId;

    return getTypeById(id);
  }

  static RPMLThemeType getTypeById(int id) {
    try {
      return RPMLThemeType.values[id];
    } on StateError {
      return RPMLThemeType.dark;
    }
  }

  static String toI18nString(RPMLThemeType type) {
    switch (type) {
      case RPMLThemeType.light:
        return I18n.format('settings.appearance.theme.light');
      case RPMLThemeType.dark:
        return I18n.format('settings.appearance.theme.dark');
    }
  }

  static int getSystem() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;

    switch (brightness) {
      case Brightness.light:
        return 0;

      case Brightness.dark:
        return 1;
    }
  }

  static ThemeData getMaterialTheme(BuildContext context) {
    return ThemeData(
        useMaterial3: true,
        fontFamilyFallback: const ['Asap', 'GenJyuuGothic'],
        brightness: context.theme.type == RPMLThemeType.light
            ? Brightness.light
            : Brightness.dark,
        tooltipTheme: TooltipThemeData(
          textStyle: TextStyle(
              color: context.theme.type == RPMLThemeType.light
                  ? Colors.white
                  : Colors.black),
          waitDuration: const Duration(milliseconds: 250),
        ),
        colorSchemeSeed: const Color(0xFF14AE5C));
  }
}

extension ThemeExtension on BuildContext {
  RPMLThemeData get theme => LauncherTheme.of(this).themeData;
}
