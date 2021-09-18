// ignore_for_file: must_be_immutable

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';

import 'Config.dart';

enum Themes { Dark, Light }

class ThemeUtility {
  static List<String> ThemeStrings = [
    i18n.format('settings.appearance.theme.dark'),
    i18n.format('settings.appearance.theme.light')
  ];

  static List<int> ThemeIDs = [0, 1];

  static String toI18nString(Themes theme) {
    switch (theme) {
      case Themes.Dark:
        return i18n.format('settings.appearance.theme.dark');
      case Themes.Light:
        return i18n.format('settings.appearance.theme.light');
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
    if (str == i18n.format('settings.appearance.theme.dark')) {
      return Themes.Dark;
    } else if (str == i18n.format('settings.appearance.theme.light')) {
      return Themes.Light;
    } else {
      return Themes.Dark;
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
  String ThemeString;
  StateSetter setWidgetState;

  SelectorThemeWidget({
    required this.ThemeString,
    required this.setWidgetState,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: ThemeString,
        onChanged: (String? themeString) async {
          int themeId = ThemeUtility.toInt(
              ThemeUtility.getThemeEnumByString(themeString!));
          Config.change('theme_id', themeId);
          ThemeString = themeString;
          setWidgetState(() {});
          await DynamicTheme.of(context)!.setTheme(themeId);
        },
        items: [
          DropdownMenuItem<String>(
            value: ThemeUtility.toI18nString(Themes.Dark),
            child: Text(ThemeUtility.toI18nString(Themes.Dark),
                textAlign: TextAlign.center),
          ),
          DropdownMenuItem<String>(
            value: ThemeUtility.toI18nString(Themes.Light),
            child: Text(ThemeUtility.toI18nString(Themes.Light),
                textAlign: TextAlign.center),
          )
        ]);
  }
}
