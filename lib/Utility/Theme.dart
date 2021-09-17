import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';

enum Themes { Dark, Light }

class ThemeUtility {
  static final List<String> ThemeStrings = [
    i18n.Format('settings.appearance.theme.dark'),
    i18n.Format('settings.appearance.theme.light')
  ];

  static String toI18nString(Themes theme) {
    switch (theme) {
      case Themes.Dark:
        return i18n.Format('settings.appearance.theme.dark');
      case Themes.Light:
        return i18n.Format('settings.appearance.theme.light');
      default:
        return "Unknown";
    }
  }

  static int toInt(Themes theme) {
    switch (theme) {
      case Themes.Dark:
        return 0;
      case Themes.Light:
        return 1;
      default:
        return 0;
    }
  }

  static Themes getThemeEnumByID(int ID) {
    if (ID == 0) {
      return Themes.Dark;
    } else if (ID == 1) {
      return Themes.Light;
    } else {
      return Themes.Dark;
    }
  }

  static Themes getThemeEnumByString(String str) {
    if (str == i18n.Format('settings.appearance.theme.dark')) {
      return Themes.Dark;
    } else if (str == i18n.Format('settings.appearance.theme.light')) {
      return Themes.Light;
    } else {
      return Themes.Dark;
    }
  }

  static ThemeData getTheme() {
    return Theme.of(NavigationService.navigationKey.currentContext!);
  }
}
