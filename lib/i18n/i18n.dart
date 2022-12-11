import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/launcher_language.dart';

class I18n {
  static final Map<LauncherLanguage, Map> _languageMap = {};

  /// Load all language files.
  static Future<void> init() async {
    for (final language in LauncherLanguage.values) {
      final data =
          await rootBundle.loadString('assets/lang/${language.code}.json');
      _languageMap[language] = await json.decode(data);
    }
  }

  static String format(String key,
      {Map<String, dynamic>? args,
      LauncherLanguage? language,
      String? errorMessage}) {
    String value = key;
    try {
      value = _languageMap[language ?? launcherConfig.language]![key];
    } catch (err) {
      value = key;
    }

    // Handle the variables in the string.
    // For example: "Hello, %name%".
    // If the `name` variable is `World`, the result will be `Hello, World`.
    if (args != null) {
      for (var key in args.keys) {
        if (value.contains('%$key%')) {
          value = value.replaceFirst('%$key%', args[key].toString());
        }
      }
    }

    // If the key is not found, try to find the key in the default language
    // If the key is still not found, return the key itself
    if (value == key) {
      value = _languageMap[LauncherLanguage.defaultLanguage]?[key] ??
          errorMessage ??
          key;
    }

    return value;
  }

  /// Get the system language.
  static LauncherLanguage getSystemLanguage() {
    final locale = WidgetsBinding.instance.window.locale;

    for (final language in LauncherLanguage.values) {
      if (language.code == locale.toString().toLowerCase()) {
        return language;
      }
    }

    return LauncherLanguage.defaultLanguage;
  }
}

class I18nText extends Text {
  I18nText(String data,
      {TextStyle? style,
      Key? key,
      TextAlign? textAlign,
      TextDirection? textDirection,
      TextHeightBehavior? textHeightBehavior,
      TextWidthBasis? textWidthBasis,
      StrutStyle? strutStyle,
      Locale? locale,
      bool? softWrap,
      Map<String, String>? args})
      : super(I18n.format(data, args: args),
            style: style,
            key: key,
            textAlign: textAlign,
            textDirection: textDirection,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis,
            strutStyle: strutStyle,
            locale: locale,
            softWrap: softWrap);

  factory I18nText.errorInfoText() {
    return I18nText('gui.error.info');
  }

  factory I18nText.tipsInfoText() {
    return I18nText('gui.tips.info');
  }
}
