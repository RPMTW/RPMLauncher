import 'dart:ui';

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:flutter/material.dart';

import '../config/config.dart';

enum Themes { dark, light }

class ThemeUtil {
  static String toI18nString(Themes theme) {
    switch (theme) {
      case Themes.light:
        return I18n.format('settings.appearance.theme.light');
      case Themes.dark:
        return I18n.format('settings.appearance.theme.dark');
      default:
        return 'Unknown';
    }
  }

  static int toInt(Themes theme) {
    switch (theme) {
      case Themes.light:
        return 0;
      case Themes.dark:
        return 1;
      default:
        return 0;
    }
  }

  static Themes getThemeEnumByID(int id) {
    if (id == 0) {
      return Themes.light;
    } else if (id == 1) {
      return Themes.dark;
    } else {
      return Themes.light;
    }
  }

  static Themes getThemeEnumByString(String str) {
    if (str == I18n.format('settings.appearance.theme.light')) {
      return Themes.light;
    } else if (str == I18n.format('settings.appearance.theme.dark')) {
      return Themes.dark;
    } else {
      return Themes.light;
    }
  }

  static ThemeData getTheme([BuildContext? context]) {
    return Theme.of(context ?? navigator.context);
  }

  static Themes getThemeEnumByConfig() {
    return ThemeUtil.getThemeEnumByID(launcherConfig.themeId);
  }

  static ThemeCollection themeCollection() {
    return ThemeCollection(themes: {
      ThemeUtil.toInt(Themes.light): ThemeData(
          colorSchemeSeed: Colors.indigo,
          fontFamily: 'font',
          tooltipTheme: const TooltipThemeData(
            textStyle: TextStyle(fontFamily: 'font', color: Colors.white),
            waitDuration: Duration(milliseconds: 250),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontFamily: 'font',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          useMaterial3: true),
      ThemeUtil.toInt(Themes.dark): ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          fontFamily: 'font',
          tooltipTheme: const TooltipThemeData(
            textStyle: TextStyle(fontFamily: 'font', color: Colors.black),
            waitDuration: Duration(milliseconds: 250),
          ),
          textTheme: const TextTheme(
              bodyLarge: TextStyle(
            fontFamily: 'font',
            fontFeatures: [FontFeature.tabularFigures()],
          )),
          useMaterial3: true),
    });
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
        defaultThemeId: ThemeUtil.toInt(Themes.dark),
        builder: builder);
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
        onChanged: (String? themeString) async {
          int themeId =
              ThemeUtil.toInt(ThemeUtil.getThemeEnumByString(themeString!));
          launcherConfig.themeId = themeId;
          themeString = themeString;
          setWidgetState(() {});
          await DynamicTheme.of(context)!.setTheme(themeId);
        },
        items: [
          DropdownMenuItem<String>(
            value: ThemeUtil.toI18nString(Themes.dark),
            child: Text(ThemeUtil.toI18nString(Themes.dark),
                textAlign: TextAlign.center),
          ),
          DropdownMenuItem<String>(
            value: ThemeUtil.toI18nString(Themes.light),
            child: Text(ThemeUtil.toI18nString(Themes.light),
                textAlign: TextAlign.center),
          )
        ]);
  }
}
