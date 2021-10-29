import 'dart:convert';
import 'dart:io';

import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:flutter/services.dart';

Map _languageMap = {};

class I18n {
  static List<String> languageNames = [
    'English (US)',
    '繁體中文 (台灣)',
    '繁體中文 (香港)',
    '简体中文 (中国)',
    '日本語'
  ];

  static List<Widget> languageFlags = [
    Flag.fromCode(FlagsCode.US, height: 30, width: 30),
    Flag.fromCode(FlagsCode.TW, height: 30, width: 30),
    Flag.fromCode(FlagsCode.HK, height: 30, width: 30),
    Flag.fromCode(FlagsCode.CN, height: 30, width: 30),
    Flag.fromCode(FlagsCode.JP, height: 30, width: 30),
  ];

  static List<String> languageCodes = [
    'en_us',
    'zh_tw',
    'zh_hk',
    'zh_cn',
    'ja_jp'
  ];

  static Future<void> init() async {
    await _loadLanguageMap();
  }

  static Future<void> _loadLanguageMap() async {
    for (String i in languageCodes) {
      String data = await rootBundle.loadString('lang/$i.json');
      _languageMap[i] = await json.decode(data);
    }
  }

  static String format(String key,
      {Map<String, dynamic>? args,
      String? lang,
      String? onError,
      Function(String)? handling}) {
    String value = key;
    try {
      value = _languageMap[lang ?? Config.getValue("lang_code")]![key];
    } catch (err) {
      value = key;
    }

    /// 變數轉換，使用 %keyName 當作變數
    if (args != null) {
      for (var argsKey in args.keys) {
        if (value.contains("%$argsKey")) {
          value = value.replaceFirst('%$argsKey', args[argsKey].toString());
        }
      }
    }

    if (handling != null) {
      value = handling(value);
    }

    if (value == key) {
      value = onError ?? _languageMap["zh_tw"]![key]; //如果找不到本地化文字，將使用預設語言
    }

    return value;
  }

  static Map getLanguageMap() {
    return _languageMap;
  }

  static String getLanguageCode() {
    if (languageCodes.contains(Platform.localeName.toLowerCase())) {
      return Platform.localeName.toLowerCase();
    } else {
      return "zh_tw";
    }
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
      Map<String, dynamic>? args})
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
}

class SelectorLanguageWidget extends StatelessWidget {
  final StateSetter setWidgetState;
  SelectorLanguageWidget({
    required this.setWidgetState,
    Key? key,
  }) : super(key: key);
  String languageNamesValue = I18n
      .languageNames[I18n.languageCodes.indexOf(Config.getValue("lang_code"))];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.format("settings.appearance.language.title"),
          style: TextStyle(fontSize: 20.0, color: Colors.lightBlue),
        ),
        DropdownButton<String>(
          value: languageNamesValue,
          onChanged: (String? newValue) {
            languageNamesValue = newValue!;
            Config.change(
                "lang_code",
                I18n.languageCodes[
                    I18n.languageNames.indexOf(languageNamesValue)]);
            setWidgetState(() {});
          },
          items:
              I18n.languageNames.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value),
                  SizedBox(
                    width: 10,
                  ),
                  I18n.languageFlags[I18n.languageNames.indexOf(value)],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
