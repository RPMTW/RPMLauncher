import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';

class ThemeUtility {
  static const int Dark = 0;
  static const int Light = 1;
  static late BuildContext _BuildContext;

  static String toI18nString(int themeId) {
    switch (themeId) {
      case Dark:
        return i18n.Format('settings.appearance.theme.dark');
      case Light:
        return i18n.Format('settings.appearance.theme.light');
      default:
        return "Unknown";
    }
  }

  static ThemeData getTheme([BuildContext? context]) {
    return Theme.of(context ?? _BuildContext);
  }

  static void UpdateTheme(BuildContext context) {
    _BuildContext = context;
  }
}
