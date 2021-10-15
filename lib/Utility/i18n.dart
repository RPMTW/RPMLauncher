// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:flutter/services.dart';

Map _LanguageMap = {};

class i18n {
  static List<String> LanguageNames = [
    'English (US)',
    '繁體中文 (台灣)',
    '繁體中文 (香港)',
    '简体中文 (中国)',
    '日本語'
  ];

  static List<Widget> LanguageFlags = [
    Flag.fromCode(FlagsCode.US, height: 30, width: 30),
    Flag.fromCode(FlagsCode.TW, height: 30, width: 30),
    Flag.fromCode(FlagsCode.HK, height: 30, width: 30),
    Flag.fromCode(FlagsCode.CN, height: 30, width: 30),
    Flag.fromCode(FlagsCode.JP, height: 30, width: 30),
  ];

  static List<String> LanguageCodes = [
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
    for (var i in LanguageCodes) {
      String data = await rootBundle.loadString('lang/$i.json');
      _LanguageMap[i] = await json.decode(data);
    }
  }

  static String format(String key,
      {Map<String, dynamic>? args,
      String? lang,
      String? onError,
      Function(String)? handling}) {
    String value = key;
    try {
      value = _LanguageMap[lang ?? Config.getValue("lang_code")]![key];
      if (value == key) {
        value = _LanguageMap["zh_tw"]![key]; //如果找不到本地化文字，將使用預設語言
      }
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

    return onError ?? value;
  }

  static Map getLanguageMap() {
    return _LanguageMap;
  }

  static String getLanguageCode() {
    if (LanguageCodes.contains(Platform.localeName.toLowerCase())) {
      return Platform.localeName.toLowerCase();
    } else {
      return "zh_tw";
    }
  }
}

class i18nText extends Text {
  i18nText(String data,
      {TextStyle? style,
      Key? key,
      TextAlign? textAlign,
      Map<String, dynamic>? args})
      : super(i18n.format(data, args: args),
            style: style, key: key, textAlign: textAlign);
}

class SelectorLanguageWidget extends StatelessWidget {
  final StateSetter setWidgetState;
  SelectorLanguageWidget({
    required this.setWidgetState,
    Key? key,
  }) : super(key: key);
  String LanguageNamesValue = i18n
      .LanguageNames[i18n.LanguageCodes.indexOf(Config.getValue("lang_code"))];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          i18n.format("settings.appearance.language.title"),
          style: TextStyle(fontSize: 20.0, color: Colors.lightBlue),
        ),
        DropdownButton<String>(
          value: LanguageNamesValue,
          onChanged: (String? newValue) {
            LanguageNamesValue = newValue!;
            Config.change(
                "lang_code",
                i18n.LanguageCodes[
                    i18n.LanguageNames.indexOf(LanguageNamesValue)]);
            setWidgetState(() {});
          },
          items:
              i18n.LanguageNames.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value),
                  SizedBox(
                    width: 10,
                  ),
                  i18n.LanguageFlags[i18n.LanguageNames.indexOf(value)],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
