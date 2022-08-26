import 'dart:ui';

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:flutter/material.dart';

import 'config.dart';

enum Themes { dark, light }

class ThemeUtility {
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

  static ThemeData getTheme([BuildContext? context]) {
    return Theme.of(context ?? navigator.context);
  }

  static Themes getThemeEnumByConfig() {
    return ThemeUtility.getThemeEnumByID(Config.getValue('theme_id'));
  }

  static ThemeCollection themeCollection([BuildContext? context]) {
    return ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
          scaffoldBackgroundColor: const Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          tooltipTheme: TooltipThemeData(
            textStyle: (context != null ? getTheme(context) : ThemeData.light())
                .textTheme
                .bodyText1
                ?.copyWith(color: Colors.white, fontSize: 13),
            waitDuration: const Duration(milliseconds: 250),
          ),
          textTheme: const TextTheme(
            bodyText1: TextStyle(
                fontFamily: 'font',
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(190, 86, 110, 244),
                  onPrimary: Colors.white)),
          useMaterial3: false),
      ThemeUtility.toInt(Themes.dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          tooltipTheme: TooltipThemeData(
            textStyle: (context != null ? getTheme(context) : ThemeData.dark())
                .textTheme
                .bodyText1
                ?.copyWith(color: Colors.black, fontSize: 13),
            waitDuration: const Duration(milliseconds: 250),
          ),
          textTheme: const TextTheme(
              bodyText1: TextStyle(
            fontFamily: 'font',
            fontFeatures: [FontFeature.tabularFigures()],
          )),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(190, 46, 160, 253),
                  onPrimary: Colors.white)),
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
        themeCollection: ThemeUtility.themeCollection(),
        defaultThemeId: ThemeUtility.toInt(Themes.dark),
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
          int themeId = ThemeUtility.toInt(
              ThemeUtility.getThemeEnumByString(themeString!));
          Config.change('theme_id', themeId);
          themeString = themeString;
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
