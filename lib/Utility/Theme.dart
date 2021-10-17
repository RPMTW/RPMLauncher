import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';

import 'Config.dart';

enum Themes { dark, light }

class ThemeUtility {
  static List<String> themeStrings = [
    I18n.format('settings.appearance.theme.dark'),
    I18n.format('settings.appearance.theme.light')
  ];

  static List<int> themeIDs = [0, 1];

  static String toI18nString(Themes theme) {
    switch (theme) {
      case Themes.dark:
        return I18n.format('settings.appearance.theme.dark');
      case Themes.light:
        return I18n.format('settings.appearance.theme.light');
      default:
        return "Unknown";
    }
  }

  static int toInt(Themes theme) {
    switch (theme) {
      case Themes.dark:
        return 0;
      case Themes.light:
        return 1;
      default:
        return 0;
    }
  }

  static Themes getThemeEnumByID(int id) {
    if (id == 0) {
      return Themes.dark;
    } else if (id == 1) {
      return Themes.light;
    } else {
      return Themes.dark;
    }
  }

  static Themes getThemeEnumByString(String str) {
    if (str == I18n.format('settings.appearance.theme.dark')) {
      return Themes.dark;
    } else if (str == I18n.format('settings.appearance.theme.light')) {
      return Themes.light;
    } else {
      return Themes.dark;
    }
  }

  static ThemeData getTheme() {
    return Theme.of(NavigationService.navigationKey.currentContext!);
  }

  static Themes getThemeEnumByContext() {
    return getThemeEnumByID(
        DynamicTheme.of(NavigationService.navigationKey.currentContext!)!
            .themeId);
  }
}

class SelectorThemeWidget extends StatelessWidget {
  String themeString;
  final StateSetter setWidgetState;

  SelectorThemeWidget({
    required this.themeString,
    required this.setWidgetState,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: themeString,
        onChanged: (String? _themeString) async {
          int themeId = ThemeUtility.toInt(
              ThemeUtility.getThemeEnumByString(_themeString!));
          Config.change('theme_id', themeId);
          themeString = _themeString;
          setWidgetState(() {});
          await DynamicTheme.of(context)!.setTheme(themeId);
        },
        items: [
          DropdownMenuItem<String>(
            value: ThemeUtility.toI18nString(Themes.dark),
            child: Text(ThemeUtility.toI18nString(Themes.dark),
                textAlign: TextAlign.center),
          ),
          DropdownMenuItem<String>(
            value: ThemeUtility.toI18nString(Themes.light),
            child: Text(ThemeUtility.toI18nString(Themes.light),
                textAlign: TextAlign.center),
          )
        ]);
  }
}
